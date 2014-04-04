(*
 Elaborator.
 In this pahse, we do the following:
 1. infix elaboration
 2. expand derived form (incomplete; revise later)
   (1) tuples => records
   (2) datatype withtype t = ty => datatype[ty/t] + type t = ty
   (3) while term
   (4) if term
 3. error checking
   (1) record label duplication

 A note on infix resolution
  About infix identifier, the Definition of Standard ML describes:
    (page 6) The only required use of op is in prefixing a non-infixed
    occurrence of an identifier symbol which has infix status; elsewhere op,
    where permitted, has no effect.
  This means, if symbol has infix status, occurrences of symbol without using op:
    elm symbol elm
  are accepted (elm is either an expression or a pattern), but non-infixed
  occurrences without using op:
    symbol
    ... elm symbol
    symbol elm ...
  are rejected.

 * A while expression
 *   while cond do body
 * is transformed to:
 *   let
 *     val rec f =
 *             fn () =>
 *                  (fn true => (fn _ => f ()) body
 *                    | false => ())
 *                  cond
 *   in f () end
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori 
 * @author Liu Bochao
 * @version $Id: Elaborator.sml,v 1.105.6.8 2010/02/10 05:17:29 hiro-en Exp $
*)
(*
sig
  val elabFFITy : Absyn.ffiTy -> PatternCalc.ffiTy
  val elabDec : Fixity.fixity SEnv.map
                -> Absyn.dec
                -> PatternCalc.pdecl list * Fixity.fixity SEnv.map
end 
*)
structure ElaborateCore =
struct
  structure EU = UserErrorUtils
  structure E = ElaborateError

  structure A = Absyn
  structure PC = PatternCalc
  structure F = FFIAttributes
  type loc = Loc.loc
  val noloc = Loc.noloc
  type symbol = Symbol.symbol
  type longsymbol = Symbol.longsymbol

  val mkSymbol = Symbol.mkSymbol
  val mkLongsymbol  = Symbol.mkLongsymbol
  val longsymbolToString = Symbol.longsymbolToString
  val longsymbolToLongid = Symbol.longsymbolToLongid
  val symbolToString = Symbol.symbolToString
  val eqLongsymbol = Symbol.eqLongsymbol
  val eqSymbol = Symbol.eqSymbol

  val initializeErrorQueue = EU.initializeErrorQueue
  val getErrorsAndWarnings = EU.getErrorsAndWarnings
  val getErrors = EU.getErrors
  val getWarnings = EU.getWarnings
  val enqueueError = EU.enqueueError
  val enqueueWarning = EU.enqueueWarning
  val listToTuple = Utils.listToTuple
  val checkNameDuplication = UserErrorUtils.checkNameDuplication
  val checkSymbolDuplication = UserErrorUtils.checkSymbolDuplication
  val checkNameDuplication' = UserErrorUtils.checkNameDuplication'
  val checkSymbolDuplication' = UserErrorUtils.checkSymbolDuplication'
  val emptyTvars = nil : PC.scopedTvars

  fun bug s = Bug.Bug ("ElaborateCore: " ^ s)

  datatype fixity = datatype Fixity.fixity

  local
    fun isReservedConstructorName name =
        case Symbol.symbolToString name of
          "true" => true
        | "false" => true
        | "nil" => true
        | "::" => true
        | "ref" => true
        | _ => false
  in
    fun checkReservedNameForConstructorBind name =
      if isReservedConstructorName name
         orelse (Symbol.symbolToString name) = "it"
        then enqueueError(Symbol.symbolToLoc name, E.BindReservedName name)
      else ()
    fun checkReservedNameForValBind name =
      if isReservedConstructorName name
        then enqueueError(Symbol.symbolToLoc name, E.BindReservedName name)
      else ()
  end

  fun getLabelOfPatRow (A.PATROWPAT(label, _, _)) = label
    | getLabelOfPatRow (A.PATROWVAR(label, _, _, _)) = label

  fun elabFFIAttributes loc attr : F.attributes =
      foldl
        (fn (attr, attrs as {isPure,noCallback,allocMLValue,suspendThread,
                             callingConvention}) =>
            case attr of
              "cdecl" => {isPure = isPure,
                          noCallback = noCallback,
                          allocMLValue = allocMLValue,
                          suspendThread = suspendThread,
                          callingConvention = SOME F.FFI_CDECL}
            | "stdcall" => {isPure = isPure,
                            noCallback = noCallback,
                            allocMLValue = allocMLValue,
                            suspendThread = suspendThread,
                            callingConvention = SOME F.FFI_STDCALL}
            | "fastcc" => {isPure = isPure,
                           noCallback = noCallback,
                           allocMLValue = allocMLValue,
                           suspendThread = suspendThread,
                           callingConvention = SOME F.FFI_FASTCC}
            | "pure" => {isPure = true,
                         noCallback = noCallback,
                         allocMLValue = allocMLValue,
                         suspendThread = suspendThread,
                         callingConvention = callingConvention}
            | "no_callback" => {isPure = isPure,
                                noCallback = true,
                                allocMLValue = allocMLValue,
                                suspendThread = suspendThread,
                                callingConvention = callingConvention}
            | "callback" => {isPure = isPure,
                             noCallback = false,
                             allocMLValue = allocMLValue,
                             suspendThread = suspendThread,
                             callingConvention = callingConvention}
            | "alloc" => {isPure = isPure,
                          noCallback = noCallback,
                          allocMLValue = true,
                          suspendThread = suspendThread,
                          callingConvention = callingConvention}
            | "no_alloc" => {isPure = isPure,
                             noCallback = noCallback,
                             allocMLValue = false,
                             suspendThread = suspendThread,
                             callingConvention = callingConvention}
            | "suspend" => {isPure = isPure,
                            noCallback = noCallback,
                            allocMLValue = allocMLValue,
                            suspendThread = true,
                            callingConvention = callingConvention}
            | "no_suspend" => {isPure = isPure,
                               noCallback = noCallback,
                               allocMLValue = allocMLValue,
                               suspendThread = false,
                               callingConvention = callingConvention}
            | _ =>
              (enqueueError (loc, E.UndefinedFFIAttribute {attr=attr});
               attrs))
        F.defaultFFIAttributes
        attr

  fun substTyVarInTy substFun ty =
    let
      fun subst ty =
        case ty of
          A.TYWILD _ => ty
        | A.TYID (tyVar, loc) => substFun (tyVar, loc)
        | A.TYRECORD (labelTys, loc) =>
            let
              val newLabelTys =
                map (fn (label, ty) => (label, subst ty)) labelTys
            in
              A.TYRECORD (newLabelTys, loc)
            end
        | A.TYCONSTRUCT (argTys, tyConPath, loc) =>
            let val newArgTys = map subst argTys
            in A.TYCONSTRUCT(newArgTys, tyConPath, loc)
            end
        | A.TYTUPLE(tys, loc) =>
(*
          raise Bug.Bug "TYTUPLE in substTyVarInTy"
*)
          A.TYTUPLE(map subst tys, loc)
        | A.TYFUN(rangeTy, domainTy, loc) =>
          A.TYFUN(subst rangeTy, subst domainTy, loc)
        | A.TYPOLY(tvarList, ty, loc) => 
          let
            val shadowNameList = map (fn ({symbol,...},_) => symbolToString symbol) tvarList
            fun newSubstFun  (tyID as ({symbol,...}, loc)) =
                if List.exists (fn x => x = symbolToString symbol) shadowNameList then
                  A.TYID tyID
                else substFun tyID
          in
            A.TYPOLY(tvarList, substTyVarInTy newSubstFun ty, loc)
          end
    in
      subst ty
    end

  fun expandWithTypesInDataBind (withTypeBinds : A.typbind list) =
      let
        fun replaceTyVarInTyWithTy (tyVars, argTys) ty =
            let
              val tyVarMap = 
                  foldr
                    (fn ((tyVar, destTy), map) =>
                        SEnv.insert(map, tyVar, destTy))
                    SEnv.empty
                    (ListPair.zip(tyVars, argTys))
              fun subst (tyID as ({symbol, eq}, loc)) =
                  case SEnv.find(tyVarMap, symbolToString symbol) of
                    NONE =>
                    (enqueueError(loc, E.NotBoundTyvar {tyvar = symbolToString symbol});
                     A.TYID tyID)
                  | SOME destTy => destTy
            in substTyVarInTy subst ty
            end
        val typeMap =
            foldr
            (fn ({tyvars=tyargs, tyConSymbol=symbol, ty,...}, map) =>
                SEnv.insert(map, symbolToString symbol, (tyargs, ty)))
            SEnv.empty
            withTypeBinds
        fun expandInTy ty =
            case ty of
              A.TYWILD _ => ty
            | A.TYID _ => ty
            | A.TYRECORD (labelTys, loc) =>
              let
                val newLabelTys =
                    map (fn (label, ty) => (label, expandInTy ty)) labelTys
              in
                A.TYRECORD (newLabelTys, loc)
              end
            | A.TYCONSTRUCT (argTys, tyConPath, loc) =>
              let 
                val expandedArgTys = map expandInTy argTys
                val tyConLongId = longsymbolToLongid tyConPath
              in
                case tyConLongId of
                  [tyConName] =>
                  (case SEnv.find (typeMap, tyConName) of
                     SOME (withTyVars, withTy) =>
                     let
                       val withTyVarNames = map (fn {symbol,...} => symbolToString symbol) withTyVars
                       val withTyVarsLen = List.length withTyVars
                       val givenTyLen = List.length expandedArgTys
                     in
                        if withTyVarsLen = givenTyLen
                        then
                          replaceTyVarInTyWithTy
                              (withTyVarNames, expandedArgTys) withTy
                        else
                          let
                            val exn = 
                                E.ArityMismatchInTypeDeclaration
                                    {
                                      tyCon = tyConName,
                                      wants = withTyVarsLen,
                                      given = givenTyLen
                                    }
                          in
                            enqueueError(loc, exn); ty
                          end
                      end
                   | NONE => A.TYCONSTRUCT(expandedArgTys, tyConPath, loc))
                | _ => A.TYCONSTRUCT(map expandInTy argTys, tyConPath, loc)
              end
            | A.TYTUPLE(tys, loc) => 
(*
              raise Bug.Bug "TYTUPLE in expandWithTypesInDataBind"
*)
              A.TYTUPLE(map expandInTy tys, loc)
            | A.TYFUN(rangeTy, domainTy, loc) =>
              A.TYFUN(expandInTy rangeTy, expandInTy domainTy, loc)
            | A.TYPOLY(tvarList, ty, loc) => 
              A.TYPOLY(tvarList, expandInTy ty, loc)
        fun expandInDataCon {symbol, ty} =
            let
              val newTyOpt =
                  case ty of NONE => NONE | SOME ty => SOME(expandInTy ty)
            in {symbol = symbol, ty = newTyOpt} end
      in
        fn {tyvars, symbol, conbind} =>
           {tyvars=tyvars, symbol = symbol, conbind = map expandInDataCon conbind}
      end

  (**************************************************************)
  (* utility functions for infix resolution. *)
  (* Here, we assume the left-right scan so that the first param is the 
   * right of the second. 
   * In the case of conflict, we give a preference to the left.
   *)
  fun stronger (INFIX n, INFIX m) = n > m
    | stronger (INFIX n, INFIXR m) = n > m  
    | stronger (INFIXR n, INFIX m) = n > m  
    | stronger (INFIXR n, INFIXR m) = n >= m  
    | stronger (NONFIX, _) = raise Bug.Bug "NONFIX in Elab.stronger"
    | stronger (_, NONFIX) = raise Bug.Bug "NONFIX in Elab.stronger"
  fun findFixity (env : fixity SEnv.map) id =
      case SEnv.find (env, id) of SOME v => v | _ => NONFIX
  fun isNonfix env id =
      (case SEnv.find (env, id) of
         SOME NONFIX => true | NONE => true | _ => false)

  (**
   * operator information
   *)
  type 'a operator =
       {
         combiner : 'a * 'a -> 'a,
         left : Loc.pos,
         right : Loc.pos,
         status : fixity
       }

  (*
   translates a list of expressions or patterns into a nested application.

   Occurrences of infix identifiers in it are associated with arguments of
   its both sides, according to operator's strength of associativity.
   To share the code between translation of expressions and of patterns,
   this function takes some operators in parameter.

   And this function also asserts that every infix identifier occurs only
   at infix position. 
   *)
  fun 'a resolveInfix
         {makeApp, makeUserOp, elab, findFixity, getLongsymbol}
         env
         elist =
      let
        (*  assert infix id does not occur at the first position or at the
         * last position in the list. *)
        (* ToDo : getLongsymbol and findFixity should be merged ?
         * Both operates on ID term (EXPID/PATID). *)
        val (first, last) = (hd elist, List.last elist)
        val validFirst = 
            case findFixity env first of
              NONFIX => true
            | _ => let val longsymbol = getLongsymbol first
                   in enqueueError (Symbol.longsymbolToLoc longsymbol, 
                                    E.BeginWithInfixID longsymbol);
                      false
                   end
        val validLast =
            case elist of
              [_] => true (* first and last is the same element. *)
            | _ =>
              case findFixity env last of
                NONFIX => true
              | _ => let val longsymbol = getLongsymbol last
                     in enqueueError (Symbol.longsymbolToLoc longsymbol, 
                                      E.EndWithInfixID longsymbol); 
                        false
                     end

        fun getLastArg x =
            case findFixity env x of
              NONFIX => elab env x
            | _ => 
              let val longsymbol = getLongsymbol x
              in 
                enqueueError (Symbol.longsymbolToLoc longsymbol, E.EndWithInfixID longsymbol); 
                 elab env x
              end

        fun getNextArg x =
            case findFixity env x of
              NONFIX => elab env x
            | _ => 
              let val longsymbol = getLongsymbol x
              in 
                enqueueError (Symbol.longsymbolToLoc longsymbol, E.ArgWithInfixID longsymbol); 
                 elab env x
              end

        fun errorCheck (INFIX n, INFIXR m) = n = m
          | errorCheck (INFIXR n, INFIX m) = n = m
          | errorCheck (_, _) = false

        (* An infix ID used may not be a data constructor.
         * We do not reject at this point, since it will be rejected by 
         * the type checker later. 
         *)
        fun resolve [x] nil nil = x
          | resolve (h1 :: h2 :: args) ((op1 : 'a operator) :: ops) nil = 
            resolve (#combiner op1 (h2, h1) :: args) ops nil
          | resolve (h1 :: h2 :: args) (op1 :: ops) [lexp] = 
            resolve
              (makeApp (h1, getLastArg lexp) :: h2 :: args) (op1 :: ops) nil
          | resolve (h1 :: h2 :: args) (op1 :: ops) (lexp :: next :: tail) = 
            (case findFixity env lexp of
               NONFIX =>
               resolve
                 (makeApp (h1, elab env lexp) :: h2 :: args)
                 (op1 :: ops)
                 (next::tail)
             | x =>
              (if errorCheck (x, #status op1)
                then
                  let
                    val longsymbol = getLongsymbol lexp
                  in
                    enqueueError (Symbol.longsymbolToLoc longsymbol, 
                                  E.InvalidOpAssociativity longsymbol)
                  end
                else ();
                if stronger(x, #status op1)
                then
                  resolve
                     (getNextArg next :: h1 :: h2 :: args)
                     (makeUserOp (elab env lexp) x :: op1 :: ops)
                     tail
                else
                  resolve
                      (#combiner op1 (h2, h1) :: args) ops (lexp :: next :: tail))
            )
          | resolve (h1 :: args) nil (lexp :: next :: tail) = 
            (case findFixity env lexp of
               NONFIX =>
               resolve (makeApp (h1, getLastArg lexp) :: args) nil (next::tail)
             | x =>
               resolve
                 (getNextArg next :: h1 :: args)
                 [makeUserOp (elab env lexp) x]
                 tail
            )
          | resolve (h1 :: args) nil [lexp] = 
               resolve (makeApp (h1, getLastArg lexp) :: args) nil nil
          | resolve _ _ _ = raise Bug.Bug "Elab.resolveInfix"
      in
        if validFirst andalso validLast
        then
          resolve [elab env (hd elist)] nil (tl elist)
        else
          (* elist contains invalid infix occurrence, which aborts resolve.
           * So, after checking each element, it returns temporary result.
           *)
          hd (map (elab env) elist)
      end

    fun elabSequence elabolator env elements =
      let
        val (elaborateds, env) =
          foldl
          (fn (element, (elaborateds, env')) =>
           let
             val (elaborated, env'') =
               elabolator (SEnv.unionWith #1 (env', env)) element
           in
             (
              elaborated :: elaborateds,
              SEnv.unionWith #1 (env'', env')
              )
           end)
          (nil, SEnv.empty)
          elements
      in
        (List.concat(rev elaborateds), env)
      end

  fun truePat loc = PC.PLPATID(mkLongsymbol ["true"] loc)
  fun falsePat loc = PC.PLPATID(mkLongsymbol ["false"] loc)
  fun trueExp loc = PC.PLVAR(mkLongsymbol ["true"] loc)
  fun falseExp loc = PC.PLVAR(mkLongsymbol ["false"] loc)
  fun unitPat loc = PC.PLPATCONSTANT(A.UNITCONST loc)
  fun unitExp loc = PC.PLCONSTANT(A.UNITCONST loc)

  fun elabLabeledSequence elaborator elements =
      map (fn (label, element) => (label, elaborator element)) elements

  fun elabFFITy ty =
      case ty of
        A.FFITYVAR x => PC.FFITYVAR x
      | A.FFIRECORDTY (labelTys, loc) =>
        let val newLabelTys = elabLabeledSequence elabFFITy labelTys
        in
          checkNameDuplication
              #1 labelTys loc E.DuplicateRecordLabelInRawType;
          PC.FFIRECORDTY (newLabelTys, loc)
        end
      | A.FFICONTY (argTys, tyConPath, loc) =>
        PC.FFICONTY (map elabFFITy argTys, tyConPath, loc)
      | A.FFITUPLETY (tys, loc) =>
        PC.FFIRECORDTY (listToTuple (map elabFFITy tys), loc)
      | A.FFIFUNTY(attrs, domTys, varTys, ranTys, loc) =>
        PC.FFIFUNTY(case attrs of nil => NONE
                                | _ => SOME (elabFFIAttributes loc attrs),
                    map elabFFITy domTys, Option.map (map elabFFITy) varTys,
                    map elabFFITy ranTys, loc)


  fun elabInfixPrec (src, loc) =
      case src of
        "0" => 0
      | "1" => 1
      | "2" => 2
      | "3" => 3
      | "4" => 4
      | "5" => 5
      | "6" => 6
      | "7" => 7
      | "8" => 8
      | "9" => 9
      | _ => (EU.enqueueError (loc, E.InvalidFixityPrecedence);
              case Int.fromString src of
                SOME x => x
              | NONE => 0)

  (**
   * transforms infix application expression into non-infix application
   * expression.
   * This function also perform elaboration.
   *)
  fun resolveInfixExp env elist =
      let
        fun makeApp (x, y) =
            PC.PLAPPM(x, [y], (PC.getLeftPosExp x, PC.getRightPosExp y))
        fun makeUserOp lexp fixity =
            {
              status = fixity, 
              left = PC.getLeftPosExp lexp,
              right = PC.getRightPosExp lexp,
              combiner =
              fn (x, y) => 
                 let val loc = (PC.getLeftPosExp x, PC.getRightPosExp y)
                 in PC.PLAPPM(
                    lexp,
                    [PC.PLRECORD(listToTuple [x, y], loc)], loc)
                 end
            }
        fun findFixity (env : fixity SEnv.map) lexp = 
            case lexp of
              A.EXPID id =>
              (case SEnv.find (env, longsymbolToString(id)) of
                 SOME v => v | _ => NONFIX)
            | _ => NONFIX
        fun getLongsymbol (A.EXPID longsymbol) = longsymbol
          | getLongsymbol exp = raise Bug.Bug "getLongsymbol expects EXPID."

      in
        resolveInfix
        {
          makeApp = makeApp,
          makeUserOp = makeUserOp,
          elab = elabExp,
          findFixity = findFixity,
          getLongsymbol = getLongsymbol
         }
        env
        elist
       end

  (**
   *  transforms infix constructor application pattern into non-infix
   * constructor application pattern.
   * This function also perform elaboration.
   *)
  and resolveInfixPat env elist =
      let
        fun makeApp (x, y) =
            PC.PLPATCONSTRUCT(x, y, (PC.getLeftPosPat x, PC.getRightPosPat y))
        fun makeUserOp lexp fixity =
            {
              status = fixity, 
              left = PC.getLeftPosPat lexp,
              right = PC.getRightPosPat lexp,
              combiner =
              fn (x, y) => 
                 let val loc = (PC.getLeftPosPat x, PC.getRightPosPat y)
                 in
                   PC.PLPATCONSTRUCT
                   (lexp, PC.PLPATRECORD(false, listToTuple [x, y], loc), loc)
                 end
            }
        fun findFixity (env : fixity SEnv.map) lexp = 
            case lexp of
              A.PATID {opPrefix=false, longsymbol, loc} => 
              (case (SEnv.find (env, longsymbolToString(longsymbol))) of
                 SOME v => v | _ => NONFIX)
            | _ => NONFIX
        fun getLongsymbol (A.PATID {opPrefix, longsymbol, loc=loc}) = longsymbol
          | getLongsymbol pat = raise Bug.Bug "getLongsymbol expects PATID"

      in
        resolveInfix
        {
          makeApp = makeApp,
          makeUserOp = makeUserOp,
          elab = elabPat,
          findFixity = findFixity,
          getLongsymbol = getLongsymbol
         }
        env
        elist
      end

  (**
   * translate header of infix function declarations to nonfix declaration
   * using "op" modifier.

   (Case 1)  fun p1 id p2 = exp
             ==>  fun (op id) (p1, p2) = exp
   (Case 2)  fun (p1 id p2) p3 ... pn = exp
             ==> fun (op id) (p1, p2) p3 ... pn = exp
    
   If both case 1 and case 2 apply, case 1 has priority over Case 2.
   For example:
     fun (x %% y) ## z = x + y + z;
   This is interpreted as a definition of ##.

*)
  and resolveFunDecls env {fdecl=fdecls, loc} =
      let
        fun assertPattern pat =
            case pat of
              A.PATID _ => pat
            | A.PATTYPED(innerPat, ty, loc) => 
              A.PATTYPED(assertPattern innerPat, ty, loc)
            | A.PATAPPLY ([pat], _) => assertPattern pat
            | pat => 
              let
                val loc = A.getLocPat pat
              in
                (enqueueError(loc, E.IllegalFunctionSymbol);
                 A.PATID {longsymbol=mkLongsymbol ["<dummy>"] noloc,
                          opPrefix=false,
                          loc=noloc
                         }
                )
              end
        fun longsymbolInPattern pat =
            case pat of
              A.PATID {longsymbol,...} => longsymbol
            | A.PATTYPED(innerPat, _, _) => longsymbolInPattern innerPat
            | _ => raise bug "impossible (longsymbolInPattern) (1)"
        fun opPrefixInPattern pat =
            case pat of
              A.PATID {opPrefix,...} => opPrefix
            | A.PATTYPED(innerPat, _, _) => opPrefixInPattern innerPat
            | _ => raise bug "impossible (opPrefixInPattern)"

        fun make2TuplePat (leftPat, rightPat) =
            let
              val leftLoc = A.getLocPat leftPat
              val rightLoc = A.getLocPat rightPat
            in
              A.PATRECORD
                  {
                   ifFlex= false,
                    fields=
                    [
                      A.PATROWPAT("1", leftPat, leftLoc),
                      A.PATROWPAT("2", rightPat, rightLoc)
                    ],
                    loc = Loc.mergeLocs (leftLoc, rightLoc)
                  }
            end

        fun getArg arg = 
            case arg of 
              A.PATID {opPrefix=opf, longsymbol=fid, loc=loc} =>
              if 
                (case findFixity env (longsymbolToString(fid)) of
                   NONFIX => true | _ => opf)
              then arg 
              else
                (
                  enqueueError
                      (loc, E.InfixUsedWithoutOP (longsymbolToString(fid)));
                  arg
                )
            | _ => arg
                
        (**
          Picks up the function ID and asserts that it is nonfix id or infix
          id with "op" modifier.
          For other arguments, the resolveInfixPat will check that no infix
          ID is used without "op".
         *)
        fun transNonfixForm (pats, tyOpt, exp) =
            case pats of
              pat :: argPats =>
              let
                val loc = A.getLocPat pat
                val pat = assertPattern pat
                val longsymbol = longsymbolInPattern pat
                val opf = opPrefixInPattern pat
              in
                if
                  (case findFixity env (longsymbolToString longsymbol) of
                     NONFIX => true | _ => opf)
                then (opf, pat, map getArg argPats, tyOpt, exp)
                else
                  (
                   enqueueError
                     (loc, E.InfixUsedWithoutOP (longsymbolToString longsymbol));
                   (opf, pat, argPats, tyOpt, exp)
                  )
              end
            | nil => raise bug "impossible nil args in transnonfix"

        (**
         * infix function header is converted to nonfix function header.
         *)
        fun resolveCase2 (args, tyOpt, exp) =
             case args of
               A.PATAPPLY([leftArg,
                           pat as A.PATID {opPrefix=false, longsymbol=id, loc},
                           rightArg], _)
               :: otherArgs =>
               (case findFixity env (longsymbolToString(id)) of
                  NONFIX => transNonfixForm (args, tyOpt, exp)
                | _ =>
                  let val newArg = make2TuplePat(getArg leftArg, getArg rightArg)
                  in (true, pat, newArg :: otherArgs, tyOpt, exp)
                  end)
             | _ => transNonfixForm (args, tyOpt, exp)

        (**
         * infix function header is converted to nonfix function header.
         *)
        fun resolveCase1 (args, tyOpt, exp) =
             case args of
               [leftArg, pat as A.PATID {opPrefix=false, longsymbol=id, loc}, rightArg]
               =>
               (case findFixity env (longsymbolToString(id)) of
                  NONFIX => resolveCase2 (args, tyOpt, exp)
                | _ =>
                  let val newArg = make2TuplePat(getArg leftArg, getArg rightArg)
                  in (true, pat, [newArg], tyOpt, exp)
                  end)
             | _ => resolveCase2 (args, tyOpt, exp)
      in
        {fdecl=map resolveCase1 fdecls, loc=loc}
      end

  and elabFunDecls env {fdecl=fdecls, loc=loc} =
      let
        val (opfs, funPats, args, exps) =
            foldr
                (fn ((opf, funPat, arg, optTy, exp), (opfs, funPats, args, exps)) =>
                    let
                      (* fun id pat .. pat : ty = exp
                       * is a derived form equivalent to
                       * fun id pat .. pat = exp : ty
                       *)
                      val typedExp =
                          case optTy of
                            NONE => exp
                          | SOME ty => A.EXPTYPED(exp, ty, loc)
                      val newExp = elabExp env typedExp
                      val newArg = map (elabPat env) arg
                    in
                      (
                       opf :: opfs,
                       funPat :: funPats, 
                       newArg :: args,
                       newExp :: exps
                      )
                    end)
                (nil, nil, nil, nil)
                fdecls
        fun longsymbolInPattern (pat, (ids,tyLocList)) =
            case pat of
              A.PATID {longsymbol=[symbol],...} => (symbol::ids, tyLocList)
            | A.PATTYPED(innerPat, ty, loc) => longsymbolInPattern (innerPat, (ids, (ty,loc)::tyLocList))
            | _ => raise bug "impossible (longsymbolInPattern) (2)"
        fun longsymbolInPatterns patList =
            foldr
            longsymbolInPattern
            (nil, nil)
            patList
        val (ids, tyLocList) = longsymbolInPatterns funPats
        val fid = hd ids
        val _ =
            if List.all (fn x => eqSymbol(fid, x)) ids
            then ()
            else enqueueError (loc, E.NotAllHaveFunctionName)
              (* ToDo : more specific location should be passed. *)
        val argNum = length (hd args)
        val _ =
            if List.all (fn x => length x = argNum) args
            then ()
            else enqueueError (loc, E.NotAllHaveSameNumberPatterns)
        val _ =
            if 0 = argNum
            then enqueueError (loc, E.FunctionParameterNotFound)
            else ()
        val _ =
            checkReservedNameForValBind fid
        val fpat = 
            foldr
            (fn ((ty,loc), fpat) => PC.PLPATTYPED(fpat, ty, loc))
            (PC.PLPATID [fid])
            tyLocList
        val fdecl = (fpat, ListPair.zip (args,exps))
      in
        {fdecl=fdecl, loc=loc}
      end

  and elabDataBindsWithTypeBinds env (dataBinds, withTypeBinds, loc) =
      let
        fun elabDataCon {conSymbol, tyOpt,...} = {symbol=conSymbol, ty=tyOpt}
        fun elabDataBind {tyvars=tvars, tyConSymbol=name, rhs=dataCons,...} =
            {tyvars=tvars, symbol=name, conbind = map elabDataCon dataCons}
        val dataCons =
            List.concat (map (fn {rhs,...} => rhs) dataBinds)
        val boundTypeNames = 
            (map (fn x => (#tyConSymbol x)) dataBinds) 
            @ (map (fn x => (#tyConSymbol x)) withTypeBinds)
        fun id x = x
        val _ =
            checkSymbolDuplication
              id boundTypeNames E.DuplicateTypeNameInDatatype
        val _ =
            checkSymbolDuplication
              (fn x => (#conSymbol x)) 
              dataCons E.DuplicateConstructorNameInDatatype
        val _ =
            app
              (fn dataCon =>
                  checkReservedNameForConstructorBind
                    (#conSymbol dataCon)
              )
              dataCons
        val newDataBinds = map elabDataBind dataBinds
        val _ = 
            map (fn {tyvars=tvars,tyConSymbol=name,ty,...} => 
                    UserErrorUtils.checkSymbolDuplication
                      (fn {symbol,eq} => symbol) tvars E.DuplicateTypParam)
                withTypeBinds
        val expandedDataBinds =
            map (expandWithTypesInDataBind withTypeBinds) newDataBinds
        val withTypeBinds =
            map (fn {tyvars, tyConSymbol, ty,...} => (tyvars, tyConSymbol, ty)) withTypeBinds
      in
        (expandedDataBinds, withTypeBinds)
      end

  and elabExp env ast = 
      case ast of 
        A.EXPCONSTANT x => PC.PLCONSTANT x
      | A.EXPID x => PC.PLVAR x
      | A.EXPOPID (x,loc) => PC.PLVAR x
      | A.EXPRECORD (stringExpList, loc) =>
        (
          checkNameDuplication
              #1 stringExpList loc E.DuplicateRecordLabel;
          PC.PLRECORD (elabLabeledSequence (elabExp env) stringExpList, loc)
        )
      | A.EXPRECORD_UPDATE (exp, stringExpList, loc) =>
        (
          checkNameDuplication
              #1 stringExpList loc E.DuplicateRecordLabel;
          PC.PLRECORD_UPDATE
          (
            elabExp env exp,
            elabLabeledSequence (elabExp env) stringExpList,
            loc
          )
        )
      | A.EXPRECORD_SELECTOR (x, loc) => PC.PLRECORD_SELECTOR(x, loc)
      | A.EXPTUPLE (elist, loc) =>
        PC.PLRECORD(listToTuple(map (elabExp env) elist), loc)
      | A.EXPLIST (elist, loc) => 
(*
        if !C.doListExpressionOptimization then
          PC.PLLIST(map (elabExp env) elist, loc)
        else
*)
        let
          fun folder (x, y) =
              PC.PLAPPM
                (PC.PLVAR(mkLongsymbol ["::"] loc),
                 [PC.PLRECORD(listToTuple [elabExp env x, y], loc)],
                 loc)
          val plexp = foldr folder (PC.PLVAR(mkLongsymbol ["nil"] loc)) elist
        in
          plexp
        end
      | A.EXPAPP (elist, loc) => resolveInfixExp env elist
      | A.EXPSEQ (elist, loc) => PC.PLSEQ(map (elabExp env) elist, loc)
      | A.EXPTYPED (exp, ty, loc) => PC.PLTYPED (elabExp env exp, ty, loc)
      | A.EXPCONJUNCTION (e1, e2, loc) =>
        let
          val ple1 = elabExp env e1
          val ple2 = elabExp env e2
        in
          PC.PLCASEM
            (
             [ple1],
             [
              ([falsePat loc], falseExp loc),
              ([truePat loc], ple2)
             ],
             PC.MATCH,
             loc
            )
        end
      | A.EXPDISJUNCTION (e1, e2, loc) =>
        let
          val ple1 = elabExp env e1
          val ple2 = elabExp env e2
        in
          PC.PLCASEM
            (
             [ple1],
             [
              ([truePat loc], trueExp loc),
              ([falsePat loc], ple2)
             ],
             PC.MATCH,
             loc
            )
             
        end
      | A.EXPHANDLE (e1, match, loc) =>
        PC.PLHANDLE
            (
              elabExp env e1,
              map (fn (x, y) => (elabPat env x, elabExp env y)) match,
              loc
            )
      | A.EXPRAISE (e, loc) => PC.PLRAISE(elabExp env e, loc)
      | A.EXPIF (e1, e2, e3, loc) =>
        let
          val ple1 = elabExp env e1
          val ple2 = elabExp env e2
          val ple3 = elabExp env e3
        in
          PC.PLCASEM
          ([ple1],
           [([truePat loc], ple2), ([falsePat loc], ple3)], PC.MATCH, loc)
        end
      | A.EXPWHILE (condExp, bodyExp, loc) =>
        let
          val newid = VarName.generate ()
          val condPl = elabExp env condExp
          val bodyPl = elabExp env bodyExp
          (* (fn _ => newid ()) body *)
          val whbody =
              PC.PLAPPM
              (
                PC.PLFNM
                (
                  [
                    (
                     [PC.PLPATWILD loc],
                     PC.PLAPPM(PC.PLVAR(mkLongsymbol [newid] loc), 
                               [unitExp loc], loc)
                    )
                  ],
                  loc
                ),
                [bodyPl],
                loc
              )
          (* fn () => (fn true => whbody | false => ()) cond *)
          val body =
              PC.PLFNM
              (
               [
                (
                 [unitPat loc],
                 PC.PLAPPM
                   (
                    PC.PLFNM
                      (
                       [([truePat loc], whbody),
                        ([falsePat loc], unitExp loc)],
                       loc
                      ),
                    [condPl],
                    loc
                   )
                )
               ],
               loc
              )
        in
          PC.PLLET
          (
            [PC.PDVALREC(emptyTvars, [(PC.PLPATID(mkLongsymbol [newid] loc), body)], loc)],
            [PC.PLAPPM(PC.PLVAR(mkLongsymbol [newid] loc), [unitExp loc], loc)],
            loc
          )
        end
      | A.EXPCASE (objectExp, match, loc) =>
        PC.PLCASEM
        (
          [elabExp env objectExp],
          map (fn (x, y) => ([elabPat env x], elabExp env y)) match,
          PC.MATCH,
          loc
        )
      | A.EXPFN (match, loc) =>
        PC.PLFNM(map (fn (x, y) => ([elabPat env x], elabExp env y)) match,
                 loc)
      | A.EXPLET (decs, elist, loc) => 
        let
          val (pdecs, env') = elabDecs env decs
          val newEnv = SEnv.unionWith #1 (env',env)
        in
          PC.PLLET (pdecs, map (elabExp newEnv) elist, loc)
        end
      | A.EXPFFIIMPORT (exp, ty, loc) =>
        (case ty of A.FFIFUNTY _ => ()
                  | _ => enqueueError (loc, E.NotForeignFunctionType {ty=ty});
         PC.PLFFIIMPORT (elabFFIFun env exp, elabFFITy ty, loc))
      | A.EXPFFIAPPLY (attrs, funExp, args, retTy, loc) =>
        PC.PLFFIAPPLY (case attrs of
                         nil => NONE
                       | _ => SOME (elabFFIAttributes loc attrs),
                       elabFFIFun env funExp,
                       map (fn A.FFIARG (exp, ty, loc) =>
                               PC.PLFFIARG (elabExp env exp,
                                            elabFFITy ty, loc)
                             | A.FFIARGSIZEOF (ty, SOME exp, loc) =>
                               PC.PLFFIARGSIZEOF (ty,
                                                  SOME (elabExp env exp),
                                                  loc
                                                  )
                             | A.FFIARGSIZEOF (ty, NONE, loc) =>
                               PC.PLFFIARGSIZEOF (ty, NONE, loc))
                           args,
                       map elabFFITy retTy, loc)
      | A.EXPSQL (sqlexp, loc) =>
        ElaborateSQL.elaborateExp
          {elabExp = elabExp env, elabPat = elabPat env}
          sqlexp
      | A.EXPJOIN (exp1, exp2, loc) =>
        PC.PLJOIN (elabExp env exp1, elabExp env exp2, loc)

  and elabFFIFun env ffiFun =
      case ffiFun of
        A.FFIFUN exp => PC.PLFFIFUN (elabExp env exp)
      | A.FFIEXTERN s => PC.PLFFIEXTERN s

  and elabPat env pat = 
      case pat of
        A.PATWILD loc => PC.PLPATWILD loc
      | A.PATCONSTANT constant =>
        (case constant of
           A.REAL (_, loc) =>
           (* According to syntactic restriction of ML Definition, real
            * constant pattern is not allowed. *)
           (enqueueError (loc, E.RealConstantInPattern); PC.PLPATCONSTANT constant)
         | _ => PC.PLPATCONSTANT constant)
      | A.PATID {opPrefix=b, longsymbol, loc} => PC.PLPATID longsymbol
      | A.PATAPPLY (plist, loc) => resolveInfixPat env plist
      | A.PATRECORD {ifFlex=flex, fields=pfields, loc=loc} =>
        (
          checkNameDuplication
              getLabelOfPatRow pfields loc E.DuplicateRecordLabelInPat;
          PC.PLPATRECORD (flex, map (elabPatRow env) pfields, loc)
        )
      | A.PATTUPLE (plist, loc) =>
        PC.PLPATRECORD (false, listToTuple (map (elabPat env) plist), loc)
      | A.PATLIST (elist, loc) =>
        let
          val plexp =
              foldr
              (fn (x, y) =>
                  PC.PLPATCONSTRUCT
                  (
                    PC.PLPATID(mkLongsymbol ["::"] loc),
                    PC.PLPATRECORD(false, listToTuple [elabPat env x, y], loc),
                    loc
                  ))
              (PC.PLPATID(mkLongsymbol ["nil"] loc))
              elist
        in
          plexp
         (*
          case plexp of
            PC.PLPATID x => PC.PLPATID x
          | PC.PLPATCONSTRUCT(x, y, l) => PC.PLPATCONSTRUCT(x, y, loc)
          | _ => raise Bug.Bug "elab EXPLIST"
         *)
        end
      | A.PATTYPED (pat, ty, loc) => PC.PLPATTYPED(elabPat env pat, ty, loc)
      | A.PATLAYERED (A.PATID {opPrefix=b, longsymbol, loc=_}, pat, loc) =>
        let
          val longid = longsymbolToLongid longsymbol
          val longsymbolLoc = Symbol.longsymbolToLoc longsymbol
          val (symbol, string) =
              case longid of
                [id] => (mkSymbol id longsymbolLoc, id)
              | _ => 
                (enqueueError (loc, E.LeftOfASMustBeVariable);
                 (mkSymbol (longsymbolToString(longsymbol)) longsymbolLoc, 
                  longsymbolToString(longsymbol))
                )
        in
          checkReservedNameForValBind symbol;
          PC.PLPATLAYERED(symbol, NONE, elabPat env pat, loc)
        end
      | A.PATLAYERED
          (A.PATTYPED
             (A.PATID{opPrefix, longsymbol, loc=loc1}, ty, loc2), pat, loc) =>
        let
          val longid = longsymbolToLongid longsymbol
          val longsymbolLoc = Symbol.longsymbolToLoc longsymbol
          val (symbol, string) =
              case longid of
                [id] => (mkSymbol id longsymbolLoc, id)
              | _ => 
                (enqueueError (loc, E.LeftOfASMustBeVariable);
                 (mkSymbol (longsymbolToString(longsymbol)) longsymbolLoc,
                  longsymbolToString(longsymbol))
                )
          val elabedPat = elabPat env pat
        in
          checkReservedNameForValBind symbol;
          PC.PLPATLAYERED(symbol, SOME ty, elabedPat, loc)
        end
      | A.PATLAYERED
          (A.PATTYPED(A.PATAPPLY([pat], _), ty, loc1), pat2, loc2) =>
        (* The first argument of PATLAYERED and PATTYPED is always be PATAPPLY 
         * (see iml.grm). This is because sequence of at least one pat should
         * be checked for infix occurrence.
         *)
        elabPat env (A.PATLAYERED(A.PATTYPED(pat, ty, loc1), pat2, loc2))
      | A.PATLAYERED (A.PATAPPLY([pat], _), pat2, loc2) =>
        elabPat env (A.PATLAYERED(pat, pat2, loc2))
      | A.PATLAYERED (pat1, pat2, loc2) =>
        (
          enqueueError (loc2, E.LeftOfASMustBeVariable);
          elabPat env pat1;
          elabPat env pat2
        )

    and elabPatRow env patrow =
        case patrow of
          (* label = pat *)
          A.PATROWPAT (string, pat, loc) => (string, elabPat env pat)
        (* label < : ty > < as pat > *)
        | A.PATROWVAR (string, optTy, optPat, loc) => 
          let
            val _ = checkReservedNameForValBind (mkSymbol string loc)
            val pat =
                case optPat of
                  SOME pat =>
                  PC.PLPATLAYERED(mkSymbol string loc, optTy, elabPat env pat,loc)
                | _ =>
                  case optTy of
                    SOME ty => PC.PLPATTYPED (PC.PLPATID(mkLongsymbol [string] loc), ty, loc)
                  | _ => PC.PLPATID(mkLongsymbol [string] loc)
          in (string, pat)
          end

    and elabDec env dec = 
        case dec of
          A.DECVAL (tyvs, decls, loc) =>
          let
            val newDecls =
                map (fn (pat, e) => (elabPat env pat, elabExp env e)) decls
          in
            ([PC.PDVAL (tyvs, newDecls, loc)],
             SEnv.empty)
          end
        | A.DECREC (tyvs, decls, loc) =>
          let
            (* right hand side of val rec must be "fn". *)
            fun assertExp (A.EXPFN _) = ()
              (* fix attempt for val rec x = (fn x =>x) is rejected  ??? *)
              | assertExp (A.EXPAPP ([exp],_)) = assertExp exp
              | assertExp exp = enqueueError (loc, E.NotFnBoundInValRec)
            (* check pattern AFTER elaboration, because even single var pattern
             * is parsed as application pattern. *)
            fun assertPattern pat =
                case pat of
                  PC.PLPATWILD _ => 
                  enqueueError(loc, E.NonVariablePatternInValRec)
                | PC.PLPATID _ => ()
                | PC.PLPATLAYERED(name, _, rightPat, _) => 
                  enqueueError(loc, E.NonVariablePatternInValRec)
                | PC.PLPATTYPED(innerPat, _, _) => assertPattern innerPat
                | _ => enqueueError(loc, E.NonVariablePatternInValRec)
            fun elabBind (pat, exp) =
                let
                  val elabedPat = elabPat env pat
                  val elabedExp = elabExp env exp
                in
                  assertPattern elabedPat; (* after elab *)
                  assertExp exp; (* before elab *)
                  (elabedPat, elabedExp)
                end
            fun getNameOfBound (PC.PLPATID [symbol], _) =
                SOME symbol
              | getNameOfBound (PC.PLPATTYPED (pat, _, _), exp) =
                getNameOfBound (pat, exp)
              | getNameOfBound (pat, _) =
                (* this case will be rejected by the above assertPat. *)
                NONE
            val elabedBinds = map elabBind decls
            val _ =
                (* NOTE: use primed version. a trick. *)
                checkSymbolDuplication'
                    getNameOfBound
                    elabedBinds
                    E.DuplicateVarNameInValRec
          in
            ([PC.PDVALREC(tyvs, elabedBinds, loc)],
             SEnv.empty)
          end
        | A.DECPOLYREC ( decls, loc) =>
          let
            (* right hand side of val rec must be "fn". *)
            fun assertExp (A.EXPFN _) = ()
              (* fix attempt for val rec x = (fn x =>x) is rejected  ??? *)
              | assertExp (A.EXPAPP ([exp],_)) = assertExp exp
              | assertExp exp = enqueueError (loc, E.NotFnBoundInValRec)
            fun elabBind (symbol, ty, exp) =
                let
                  val elabedExp = elabExp env exp
                in
                  assertExp exp; (* before elab *)
                  (symbol, ty, elabedExp)
                end
            val elabedBinds = map elabBind decls
            val _ =
                checkSymbolDuplication
                    (fn (f, ty, e) => f)
                    elabedBinds
                    E.DuplicateVarNameInValRec
          in
            ([PC.PDVALPOLYREC(elabedBinds, loc)],
             SEnv.empty)
          end
        | A.DECFUN (tyvs, fbinds, loc) =>
          let
            val elabFBind = elabFunDecls env o resolveFunDecls env
            val elabedFunBinds = map elabFBind fbinds
            fun getNameOfBind {fdecl=(PC.PLPATID [symbol], _), loc} = symbol
              | getNameOfBind {fdecl=(PC.PLPATTYPED(innerPat, ty, _), a), loc} = 
                getNameOfBind {fdecl=(innerPat, a), loc=loc}
              | getNameOfBind _ =
                raise Bug.Bug "not PATID nor PATTYPED getNameOfBound"
            val _ =
                checkSymbolDuplication
                    getNameOfBind
                    elabedFunBinds
                    E.DuplicateVarNameInValRec
          in
            ([PC.PDDECFUN (tyvs, elabedFunBinds, loc)],
             SEnv.empty)
          end
        | A.DECTYPE {tbs=tyBinds, loc,...} =>
          let
            fun elabTyBind {tyvars=tvars, tyConSymbol=symbol, ty,...} =
                let
                  val newTVars =
                      map
                        (fn {symbol, eq} => {symbol=symbol, eq=A.NONEQ})
                        tvars
                  val newTy =
                      substTyVarInTy
                          (fn ({symbol, eq}, loc) =>
                              A.TYID({symbol=symbol, eq=A.NONEQ}, loc))
                          ty
                in
                  (newTVars, symbol, newTy)
                end
            val newTyBinds = map elabTyBind tyBinds
          in
            checkSymbolDuplication
                #2
                newTyBinds E.DuplicateTypeNameInType;
            ([PC.PDTYPE (newTyBinds, loc)], SEnv.empty)
          end
        | A.DECDATATYPE {datatys=dataBinds, withtys=withTypeBinds, loc,...} =>
          let
            val (newDataBinds, newWithTypeBinds) =
                elabDataBindsWithTypeBinds env (dataBinds, withTypeBinds, loc)
          in
            (
              (PC.PDDATATYPE (newDataBinds, loc)) 
              :: (case newWithTypeBinds of
                    [] => [] | _ => [PC.PDTYPE(newWithTypeBinds, loc)]),
              SEnv.empty
            )
          end
        | A.DECREPLICATEDAT {defSymbol, formatComments, refLongsymbol, loc} =>
          ([PC.PDREPLICATEDAT (defSymbol, refLongsymbol, loc)], SEnv.empty) 
        | A.DECABSTYPE {abstys=dataBinds, withtys=withTypeBinds, body=decs, loc,...} =>
          let
            val (newDataBinds, newWithTypeBinds) =
                elabDataBindsWithTypeBinds env (dataBinds, withTypeBinds, loc)
            val (newDecs, newEnv) = elabDecs env decs
            val newVisibleDecs =
                case newWithTypeBinds of
                  [] => newDecs
                | _ => PC.PDTYPE(newWithTypeBinds, loc) :: newDecs
          in
            ([PC.PDABSTYPE(newDataBinds, newVisibleDecs, loc)], newEnv)
          end
        | A.DECEXN {exbinds=exnBinds, loc,...} =>
          let
            fun elabExnBind (A.EXBINDDEF{opFlag, conSymbol, tyOpt=NONE, loc,...}) =
                PC.PLEXBINDDEF(conSymbol, NONE, loc)
              | elabExnBind (A.EXBINDDEF{conSymbol, tyOpt=SOME ty, loc,...}) =
                PC.PLEXBINDDEF(conSymbol, SOME ty, loc)
              | elabExnBind
                (A.EXBINDREP{conSymbol, refLongsymbol, loc,...}) =
                PC.PLEXBINDREP(conSymbol, refLongsymbol, loc)
            fun getExnName (A.EXBINDDEF {conSymbol,...}) = conSymbol
              | getExnName (A.EXBINDREP {conSymbol,...}) = conSymbol
            fun getExnLoc (A.EXBINDDEF {loc,...}) = loc
              | getExnLoc (A.EXBINDREP {loc,...}) = loc
            val _ =
                checkSymbolDuplication
                    getExnName exnBinds
                    E.DuplicateConstructorNameInException
            val _ =
                app
                  checkReservedNameForConstructorBind 
                  (map getExnName exnBinds)
          in
            ([PC.PDEXD (map elabExnBind exnBinds, loc)], SEnv.empty)
          end
        | A.DECLOCAL (dec1, dec2, loc) => 
          let
            val (pdecs1, env1) = elabDecs env dec1
            val (pdecs2, env2) = elabDecs (SEnv.unionWith #1 (env1, env)) dec2
          in
            ([PC.PDLOCALDEC(pdecs1, pdecs2, loc)], env2)
          end
        | A.DECOPEN(longids,loc) => ([PC.PDOPEN(longids, loc)], SEnv.empty)
        | A.DECINFIX (n, idlist, loc) =>
          let
            val n = elabInfixPrec (n, loc)
          in
            (
              [PC.PDINFIXDEC(n, idlist, loc)],
              foldr
                (fn (x, env) => SEnv.insert (env, symbolToString x, INFIX n))
                SEnv.empty
                idlist
            )
          end
        | A.DECINFIXR (n, idlist, loc) =>
          let
            val n = elabInfixPrec (n, loc)
          in
            (
              [PC.PDINFIXRDEC(n, idlist, loc)],
              foldr
                (fn (x, env) => SEnv.insert (env, symbolToString x, INFIXR n))
                SEnv.empty
                idlist
            )
          end
        | A.DECNONFIX (idlist, loc) =>
          (
            [PC.PDNONFIXDEC(idlist, loc)],
            foldr
                (fn (x, env) => SEnv.insert (env, symbolToString x, NONFIX))
                SEnv.empty
                idlist
          )

    and elabDecs env decs = elabSequence elabDec env decs

end
