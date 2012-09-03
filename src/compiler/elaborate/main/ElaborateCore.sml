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
    occurrence of an identifier vid which has infix status; elsewhere op,
    where permitted, has no effect.
  This means, if vid has infix status, occurrences of vid without using op:
    elm vid elm
  are accepted (elm is either an expression or a pattern), but non-infixed
  occurrences without using op:
    vid
    ... elm vid
    vid elm ...
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
structure ElaborateCore : sig

  val elabFFITy : Absyn.ffiTy -> PatternCalc.ffiTy
  val elabDec : Fixity.fixity SEnv.map
                -> Absyn.dec
                -> PatternCalc.pdecl list * Fixity.fixity SEnv.map

end =
struct
local
  structure C = Control
  structure A = Absyn
  structure E = ElaborateError
  structure UE = UserError
  structure PC = PatternCalc
in

  datatype fixity = datatype Fixity.fixity

  (***************************************************************************)

  val initializeErrorQueue = ElaboratorUtils.initializeErrorQueue
  val getErrorsAndWarnings = ElaboratorUtils.getErrorsAndWarnings
  val getErrors = ElaboratorUtils.getErrors
  val getWarnings = ElaboratorUtils.getWarnings
  val enqueueError = ElaboratorUtils.enqueueError
  val enqueueWarning = ElaboratorUtils.enqueueWarning
  val listToTuple = Utils.listToTuple
  val checkNameDuplication = UserErrorUtils.checkNameDuplication
  val checkNameDuplication' = UserErrorUtils.checkNameDuplication'
  val emptyTvars = nil : PC.scopedTvars

  (**************************************************************)

  local
    fun isReservedConstructorName name =
        case name of
          "true" => true
        | "false" => true
        | "nil" => true
        | "::" => true
        | "ref" => true
        | _ => false
  in
    fun checkReservedNameForConstructorBind (name, loc) =
      if isReservedConstructorName name orelse name = "it"
        then enqueueError(loc, E.BindReservedName name)
      else ()
    fun checkReservedNameForValBind (name, loc) =
      if isReservedConstructorName name
        then enqueueError(loc, E.BindReservedName name)
      else ()
  end

  fun getLabelOfPatRow (A.PATROWPAT(label, _, _)) = label
    | getLabelOfPatRow (A.PATROWVAR(label, _, _, _)) = label

  fun elabFFIAttributes loc attr : A.ffiAttributes =
      foldl
        (fn (attr, attrs as {isPure,noCallback,allocMLValue,suspendThread,
                             callingConvention}) =>
            case attr of
              "cdecl" => {isPure = isPure,
                          noCallback = noCallback,
                          allocMLValue = allocMLValue,
                          suspendThread = suspendThread,
                          callingConvention = SOME A.FFI_CDECL}
            | "stdcall" => {isPure = isPure,
                            noCallback = noCallback,
                            allocMLValue = allocMLValue,
                            suspendThread = suspendThread,
                            callingConvention = SOME A.FFI_STDCALL}
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
        Absyn.defaultFFIAttributes
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
          raise Control.Bug "TYTUPLE in substTyVarInTy"
*)
          A.TYTUPLE(map subst tys, loc)
        | A.TYFUN(rangeTy, domainTy, loc) =>
            A.TYFUN(subst rangeTy, subst domainTy, loc)
        | A.TYPOLY(tvarList, ty, loc) => 
            let
              val shadowNameList = map (fn ({name,...},_) => name) tvarList
              fun newSubstFun  (tyID as ({name, ...}, loc)) =
                if List.exists (fn x => x = name) shadowNameList then
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
              fun subst (tyID as ({name, eq}, loc)) =
                  case SEnv.find(tyVarMap, name) of
                    NONE =>
                    (enqueueError(loc, E.NotBoundTyvar {tyvar = name});
                     A.TYID tyID)
                  | SOME destTy => destTy
            in substTyVarInTy subst ty
            end
        val typeMap =
            foldr
            (fn ((tyargs, name, ty), map) =>
                SEnv.insert(map, name, (tyargs, ty)))
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
              let val expandedArgTys = map expandInTy argTys
              in
                case tyConPath of
                  [tyConName] =>
                  (case SEnv.find (typeMap, tyConName) of
                     SOME (withTyVars, withTy) =>
                     let
                       val withTyVarNames = map #name withTyVars
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
              raise Control.Bug "TYTUPLE in expandWithTypesInDataBind"
*)
              A.TYTUPLE(map expandInTy tys, loc)
            | A.TYFUN(rangeTy, domainTy, loc) =>
              A.TYFUN(expandInTy rangeTy, expandInTy domainTy, loc)
            | A.TYPOLY(tvarList, ty, loc) => 
              A.TYPOLY(tvarList, expandInTy ty, loc)
        fun expandInDataCon {vid, ty} =
            let
              val newTyOpt =
                  case ty of NONE => NONE | SOME ty => SOME(expandInTy ty)
            in {vid = vid, ty = newTyOpt} end
      in
        fn {tyvars, tycon, conbind} =>
           {tyvars=tyvars, tycon=tycon, conbind = map expandInDataCon conbind}
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
    | stronger (NONFIX, _) = raise Control.Bug "NONFIX in Elab.stronger"
    | stronger (_, NONFIX) = raise Control.Bug "NONFIX in Elab.stronger"
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
         {makeApp, makeUserOp, elab, findFixity, getIDInfo}
         env
         elist =
      let
        (*  assert infix id does not occur at the first position or at the
         * last position in the list. *)
        (* ToDo : getIDInfo and findFixity should be merged ?
         * Both operates on ID term (EXPID/PATID). *)
        val (first, last) = (hd elist, List.last elist)
        val validFirst = 
            case findFixity env first of
              NONFIX => true
            | _ => let val (id, loc) = getIDInfo first
                   in enqueueError (loc, E.BeginWithInfixID id); false
                   end
        val validLast =
            case elist of
              [_] => true (* first and last is the same element. *)
            | _ =>
              case findFixity env last of
                NONFIX => true
              | _ => let val (id, loc) = getIDInfo last
                     in enqueueError (loc, E.EndWithInfixID id); false
                     end

        fun getLastArg x =
            case findFixity env x of
              NONFIX => elab env x
            | _ => 
              let val (id, loc) = getIDInfo x
              in 
                enqueueError (loc, E.EndWithInfixID id); 
                 elab env x
              end

        fun getNextArg x =
            case findFixity env x of
              NONFIX => elab env x
            | _ => 
              let val (id, loc) = getIDInfo x
              in 
                enqueueError (loc, E.ArgWithInfixID id); 
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
                    val (id, loc) = getIDInfo lexp
                  in
                    enqueueError (loc, E.InvalidOpAssociativity id)
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
          | resolve _ _ _ = raise Control.Bug "Elab.resolveInfix"
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

  fun truePat loc = PC.PLPATID(["true"], loc)
  fun falsePat loc = PC.PLPATID(["false"], loc)
  fun trueExp loc = PC.PLVAR(["true"], loc)
  fun falseExp loc = PC.PLVAR(["false"], loc)
  fun unitPat loc = PC.PLPATCONSTANT(A.UNITCONST loc, loc)
  fun unitExp loc = PC.PLCONSTANT(A.UNITCONST loc, loc)

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
      | A.FFIFUNTY(attrs, domTys, ranTys, loc) =>
        PC.FFIFUNTY(case attrs of nil => NONE
                                | _ => SOME (elabFFIAttributes loc attrs),
                    map elabFFITy domTys, map elabFFITy ranTys, loc)

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
              A.EXPID (id, _) =>
              (case SEnv.find (env, A.longidToString(id)) of
                 SOME v => v | _ => NONFIX)
            | _ => NONFIX
        fun getIDInfo (A.EXPID (id, loc)) = (A.longidToString(id), loc)
          | getIDInfo exp = raise Control.Bug "getIDInfo expects EXPID."

      in
        resolveInfix
        {
          makeApp = makeApp,
          makeUserOp = makeUserOp,
          elab = elabExp,
          findFixity = findFixity,
          getIDInfo = getIDInfo
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
              A.PATID {opPrefix=false, id, loc} => 
              (case (SEnv.find (env, A.longidToString(id))) of
                 SOME v => v | _ => NONFIX)
            | _ => NONFIX
        fun getIDInfo (A.PATID {opPrefix, id=id, loc=loc}) =
            (A.longidToString(id), loc)
          | getIDInfo pat = raise Control.Bug "getIDInfo expects PATID"

      in
        resolveInfix
        {
          makeApp = makeApp,
          makeUserOp = makeUserOp,
          elab = elabPat,
          findFixity = findFixity,
          getIDInfo = getIDInfo
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
  and resolveFunDecls env fdecls =
      let
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
              A.PATID {opPrefix=opf, id=fid, loc=loc} =>
              if 
                (case findFixity env (A.longidToString(fid)) of
                   NONFIX => true | _ => opf)
              then arg 
              else
                (
                  enqueueError
                      (loc, E.InfixUsedWithoutOP (A.longidToString(fid)));
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
              A.PATID {opPrefix=opf, id=fid, loc=loc} :: argPats =>
              if
                (case findFixity env (A.longidToString(fid)) of
                   NONFIX => true | _ => opf)
              then (opf, fid, map getArg argPats, tyOpt, exp)
              else
                (
                  enqueueError
                      (loc, E.InfixUsedWithoutOP (A.longidToString(fid)));
                  (opf, fid, argPats, tyOpt, exp)
                )
            | _ =>
              (
                enqueueError (A.getLocPat (hd pats), E.IllegalFunctionSymbol);
                (false, ["<dummy>"], tl pats, tyOpt, exp)
              )

        (**
         * infix function header is converted to nonfix function header.
         *)
        fun resolveCase2 (args, tyOpt, exp) =
             case args of
               A.PATAPPLY([leftArg,
                           A.PATID {opPrefix=false, id, loc},
                           rightArg], _)
               :: otherArgs =>
               (case findFixity env (A.longidToString(id)) of
                  NONFIX => transNonfixForm (args, tyOpt, exp)
                | _ =>
                  let val newArg = make2TuplePat(getArg leftArg, getArg rightArg)
                  in (true, id, newArg :: otherArgs, tyOpt, exp)
                  end)
             | _ => transNonfixForm (args, tyOpt, exp)

        (**
         * infix function header is converted to nonfix function header.
         *)
        fun resolveCase1 (args, tyOpt, exp) =
             case args of
               [leftArg, A.PATID {opPrefix=false, id, loc}, rightArg]
               =>
               (case findFixity env (A.longidToString(id)) of
                  NONFIX => resolveCase2 (args, tyOpt, exp)
                | _ =>
                  let val newArg = make2TuplePat(getArg leftArg, getArg rightArg)
                  in (true, id, [newArg], tyOpt, exp)
                  end)
             | _ => resolveCase2 (args, tyOpt, exp)
      in
        map resolveCase1 fdecls
      end

  and elabFunDecls loc env fdecls =
      let
        val (opfs, fids, args, exps) = 
            foldr
                (fn ((opf, fid, arg, optTy, exp), (opfs, fids, args, exps)) =>
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
                       fid :: fids, newArg :: args,
                       newExp :: exps
                      )
                    end)
                (nil, nil, nil, nil)
                fdecls

        val fid = hd fids
        val _ =
            if List.all (fn x => x = fid) fids
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

        val fdecl = (PC.PLPATID (fid, loc), ListPair.zip (args,exps))
      in
        fdecl
      end

  and elabDataBindsWithTypeBinds env (dataBinds, withTypeBinds, loc) =
      let
        fun elabDataCon (_, name, optTy) = {vid=name, ty=optTy}
        fun elabDataBind (tvars, name, dataCons) =
            {tyvars=tvars, tycon=name, conbind = map elabDataCon dataCons}
        val dataCons =
            List.concat (map (fn (_, _, dataCons) => dataCons) dataBinds)
        val boundTypeNames = (map #2 dataBinds) @ (map #2 withTypeBinds)
        fun id x = x
        val _ =
            checkNameDuplication
              id boundTypeNames loc E.DuplicateTypeNameInDatatype
        val _ =
            checkNameDuplication
              #2 dataCons loc E.DuplicateConstructorNameInDatatype
        val _ =
            app
              (fn dataCon =>
                  checkReservedNameForConstructorBind(#2 dataCon, loc))
              dataCons
        val newDataBinds = map elabDataBind dataBinds
        val _ = 
            map (fn (tvars,name,ty) => 
                    UserErrorUtils.checkNameDuplication
                      (fn {name,eq} => name) tvars loc E.DuplicateTypParam)
                withTypeBinds
        val expandedDataBinds =
            map (expandWithTypesInDataBind withTypeBinds) newDataBinds
      in
        (expandedDataBinds, withTypeBinds)
      end

  and elabExp env ast = 
      case ast of 
        A.EXPCONSTANT x => PC.PLCONSTANT x
      | A.EXPGLOBALSYMBOL x => PC.PLGLOBALSYMBOL x
      | A.EXPID (x,loc) => PC.PLVAR (x,loc)
      | A.EXPOPID (x,loc) => PC.PLVAR (x,loc)
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
      | A.EXPRECORD_SELECTOR (x, loc) =>  PC.PLRECORD_SELECTOR(x, loc)
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
                (PC.PLVAR(["::"], loc),
                 [PC.PLRECORD(listToTuple [elabExp env x, y], loc)],
                 loc)
          val plexp = foldr folder (PC.PLVAR(["nil"], loc)) elist
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
      | A.EXPRAISE (e, loc) =>PC.PLRAISE(elabExp env e, loc)
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
                     PC.PLAPPM(PC.PLVAR([newid], loc), [unitExp loc], loc)
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
            [PC.PDVALREC(emptyTvars, [(PC.PLPATID([newid], loc), body)], loc)],
            [PC.PLAPPM(PC.PLVAR([newid], loc), [unitExp loc], loc)],
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
      | A.EXPCAST (exp,loc) => PC.PLCAST(elabExp env exp, loc)
      | A.EXPFFIIMPORT (exp, ty, loc) =>
        (case ty of A.FFIFUNTY _ => ()
                  | _ => enqueueError (loc, E.NotForeignFunctionType {ty=ty});
         PC.PLFFIIMPORT (elabExp env exp, elabFFITy ty, loc))
      | A.EXPFFIEXPORT (exp, ty, loc) =>
        (case ty of A.FFIFUNTY _ => ()
                  | _ => enqueueError (loc, E.NotForeignFunctionType {ty=ty});
         PC.PLFFIEXPORT (elabExp env exp, elabFFITy ty, loc))
      | A.EXPFFIAPPLY (attrs, funExp, args, retTy, loc) =>
        PC.PLFFIAPPLY (case attrs of
                         nil => NONE
                       | _ => SOME (elabFFIAttributes loc attrs),
                       elabExp env funExp,
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
                       elabFFITy retTy, loc)
      | A.EXPSQL (sqlexp, loc) =>
        ElaborateSQL.elaborateExp
          {elabExp = elabExp env, elabPat = elabPat env}
          sqlexp

  and elabPat env pat = 
      case pat of
        A.PATWILD loc => PC.PLPATWILD loc
      | A.PATCONSTANT (x as (constant, loc)) =>
        (case constant of
           A.REAL (_, loc) =>
           (* According to syntactic restriction of ML Definition, real
            * constant pattern is not allowed. *)
           (enqueueError (loc, E.RealConstantInPattern); PC.PLPATCONSTANT x)
         | _ => PC.PLPATCONSTANT x)
      | A.PATID {opPrefix=b, id, loc} => PC.PLPATID (id, loc)
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
                    PC.PLPATID(["::"], loc),
                    PC.PLPATRECORD(false, listToTuple [elabPat env x, y], loc),
                    loc
                  ))
              (PC.PLPATID(["nil"], loc))
              elist
        in
          case plexp of
            PC.PLPATID(x, l) => PC.PLPATID(x, loc)
          | PC.PLPATCONSTRUCT(x, y, l) => PC.PLPATCONSTRUCT(x, y, loc)
          | _ => raise Control.Bug "elab EXPLIST"
        end
      | A.PATTYPED (pat, ty, loc) => PC.PLPATTYPED(elabPat env pat, ty, loc)
      | A.PATLAYERED (A.PATID {opPrefix=b, id=path, loc=loc1}, pat, loc) =>
        let
          val _ =
              if A.isShortId path
              then ()
              else enqueueError (loc, E.LeftOfASMustBeVariable)
          val id = A.longidToString(path)
        in
          checkReservedNameForValBind (id, loc1);
          PC.PLPATLAYERED(id, NONE, elabPat env pat, loc)
        end
      | A.PATLAYERED
            (A.PATTYPED
                 (A.PATID{opPrefix, id=path, loc=loc1}, ty, loc2), pat, loc) =>
        let
          val _ =
              if A.isShortId path
              then ()
              else enqueueError (loc, E.LeftOfASMustBeVariable)
          val id = A.longidToString(path)
          val elabedPat = elabPat env pat
        in
          checkReservedNameForValBind (id, loc1);
          PC.PLPATLAYERED(id, SOME ty, elabedPat, loc)
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
          A.PATROWPAT (id, pat, loc) => (id, elabPat env pat)
        (* label < : ty > < as pat > *)
        | A.PATROWVAR (id, optTy, optPat, loc) => 
          let
            val _ = checkReservedNameForValBind (id, loc)
            val pat =
                case optPat of
                  SOME pat =>
                  PC.PLPATLAYERED(id, optTy, elabPat env pat,loc)
                | _ =>
                  case optTy of
                    SOME ty => PC.PLPATTYPED (PC.PLPATID([id], loc), ty, loc)
                  | _ => PC.PLPATID([id], loc)
          in (id, pat)
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
            fun getNameOfBound (PC.PLPATID(name, _), _) =
                SOME(A.longidToString name)
              | getNameOfBound (PC.PLPATTYPED (pat, _, _), exp) =
                getNameOfBound (pat, exp)
              | getNameOfBound (pat, _) =
                (* this case will be rejected by the above assertPat. *)
                NONE
            val elabedBinds = map elabBind decls
            val _ =
                (* NOTE: use primed version. a trick. *)
                checkNameDuplication'
                    getNameOfBound
                    elabedBinds
                    loc
                    E.DuplicateVarNameInValRec
          in
            ([PC.PDVALREC(tyvs, elabedBinds, loc)],
             SEnv.empty)
          end
        | A.DECFUN (tyvs, fbinds, loc) =>
          let
            val elabFBind = elabFunDecls loc env o resolveFunDecls env
            val elabedFunBinds = map elabFBind fbinds
            fun getNameOfBind (PC.PLPATID (name, _), _) = A.longidToString name
              | getNameOfBind _ =
                raise Control.Bug "not PATID nor PATTYPED getNameOfBound"
            val _ =
                checkNameDuplication
                    getNameOfBind
                    elabedFunBinds
                    loc
                    E.DuplicateVarNameInValRec
          in
            ([PC.PDDECFUN (tyvs, elabedFunBinds, loc)],
             SEnv.empty)
          end
        | A.DECTYPE (tyBinds, loc) =>
          let
            fun elabTyBind (tvars, name, ty) =
                let
                  val newTVars =
                      map
                        (fn {name=tvarName, eq} => {name=tvarName, eq=A.NONEQ})
                        tvars
                  val newTy =
                      substTyVarInTy
                          (fn ({name=tvarName, eq}, loc) =>
                              A.TYID({name=tvarName, eq=A.NONEQ}, loc))
                          ty
                in
                  (newTVars, name, newTy)
                end
            val newTyBinds = map elabTyBind tyBinds
          in
            checkNameDuplication
                #2 newTyBinds loc E.DuplicateTypeNameInType;
            ([PC.PDTYPE (newTyBinds, loc)], SEnv.empty)
          end
        | A.DECDATATYPE (dataBinds, withTypeBinds, loc) =>
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
        | A.DECREPLICATEDAT (tyCon, longTyCon, loc) =>
          ([PC.PDREPLICATEDAT (tyCon, longTyCon, loc)], SEnv.empty) 
        | A.DECABSTYPE (dataBinds, withTypeBinds, decs, loc) =>
(*
          let
            val (newDataBinds, newWithTypeBinds) =
                elabDataBindsWithTypeBinds env (dataBinds, withTypeBinds, loc)
            val (newDecs, newEnv) = elabDecs env decs
            val newVisibleDecs =
                case newWithTypeBinds of
                  [] => newDecs
                | _ => PC.PDTYPE(newWithTypeBinds, loc) :: newDecs
                    newDataBinds
          in
            ([PC.PDABSTYPE(newDataBinds, newVisibleDecs, loc)], newEnv)
          end
*)
          let
            val (newDataBinds, newWithTypeBinds) =
                elabDataBindsWithTypeBinds env (dataBinds, withTypeBinds, loc)
            val (newDecs, newEnv) = elabDecs env decs
            val typeDecs =
                case newWithTypeBinds of
                  [] => nil
                | _ => [PC.PDTYPE(newWithTypeBinds, loc)]
            val typbinds =
                map (fn {tyvars, tycon,...} =>
                        (tyvars, tycon,
                         A.TYCONSTRUCT
                           (map (fn t => A.TYID (t, loc)) tyvars,
                            [tycon], loc)) : PC.typbind)
                    newDataBinds
          in
            enqueueWarning (loc, E.AbstypeNotSupported);
            ([PC.PDLOCALDEC
                (PC.PDDATATYPE (newDataBinds, loc) :: typeDecs,
                 newDecs @ [PC.PDTYPE (typbinds, loc)],
                 loc)],
             newEnv)
          end
        | A.DECEXN (exnBinds, loc) =>
          let
            fun elabExnBind (A.EXBINDDEF(isOp, name, NONE, loc)) =
                PC.PLEXBINDDEF(name, NONE, loc)
              | elabExnBind (A.EXBINDDEF(isOp, name, SOME ty, loc)) =
                PC.PLEXBINDDEF(name, SOME ty, loc)
              | elabExnBind
                (A.EXBINDREP(bool1, name, bool2, exnlongid, loc)) =
                PC.PLEXBINDREP(name, exnlongid, loc)
            fun getExnName (A.EXBINDDEF(_, name, _, _)) = name
              | getExnName (A.EXBINDREP(_, name, _, _, _)) = name
            fun getExnLoc (A.EXBINDDEF(_, _, _, loc)) = loc
              | getExnLoc (A.EXBINDREP(_, _, _, _, loc)) = loc
            val _ =
                checkNameDuplication
                    getExnName exnBinds loc
                    E.DuplicateConstructorNameInException
            val _ =
                app
                  checkReservedNameForConstructorBind 
                  (ListPair.zip
                     (map getExnName exnBinds, map getExnLoc exnBinds))
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
            val n = ElaboratorUtils.elabInfixPrec (n, loc)
          in
            (
              [PC.PDINFIXDEC(n, idlist, loc)],
              foldr
                (fn (x, env) => SEnv.insert (env, x, INFIX n))
                SEnv.empty
                idlist
            )
          end
        | A.DECINFIXR (n, idlist, loc) =>
          let
            val n = ElaboratorUtils.elabInfixPrec (n, loc)
          in
            (
              [PC.PDINFIXRDEC(n, idlist, loc)],
              foldr
                (fn (x, env) => SEnv.insert (env, x, INFIXR n))
                SEnv.empty
                idlist
            )
          end
        | A.DECNONFIX (idlist, loc) =>
          (
            [PC.PDNONFIXDEC(idlist, loc)],
            foldr
                (fn (x, env) => SEnv.insert (env, x, NONFIX))
                SEnv.empty
                idlist
          )

    and elabDecs env decs = elabSequence elabDec env decs

end
end
