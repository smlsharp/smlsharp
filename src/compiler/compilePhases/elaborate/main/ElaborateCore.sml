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
 * @copyright (C) 2021 SML# Development Team.
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
  val eqLongsymbol = Symbol.eqLongsymbol
  val eqSymbol = Symbol.eqSymbol

  val initializeErrorQueue = EU.initializeErrorQueue
  val getErrorsAndWarnings = EU.getErrorsAndWarnings
  val getErrors = EU.getErrors
  val getWarnings = EU.getWarnings
  val enqueueError = EU.enqueueError
  val enqueueWarning = EU.enqueueWarning
  val checkRecordLabelDuplication = UserErrorUtils.checkRecordLabelDuplication
  val checkSymbolDuplication = UserErrorUtils.checkSymbolDuplication
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
    | getLabelOfPatRow (A.PATROWVAR(label, _, _, _)) =
      RecordLabel.fromSymbol label

  fun elabFFIAttributes loc attr : F.attributes =
      foldl
        (fn (attr, attrs) =>
            case attr of
              "cdecl" => attrs # {callingConvention = SOME F.FFI_CDECL}
            | "stdcall" => attrs # {callingConvention = SOME F.FFI_STDCALL}
            | "fastcc" => attrs # {callingConvention = SOME F.FFI_FASTCC}
            | "pure" => attrs # {isPure = true}
            | "fast" => attrs # {fast = true}
            | "unsafe" => attrs # {unsafe = true}
            | "gc" => attrs # {causeGC = true}
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
        | A.FREE_TYID {freeTvar, tvarKind, loc} =>
          raise Bug.Bug "FREE_TYID in substTyVarInTy"
        | A.TYRECORD {ifFlex, fields = labelTys, loc} =>
            let
              val newLabelTys =
                map (fn (label, ty) => (label, subst ty)) labelTys
            in
              A.TYRECORD {ifFlex=ifFlex, fields = newLabelTys, loc=loc}
            end
        | A.TYCONSTRUCT (argTys, tyConPath, loc) =>
            let val newArgTys = map subst argTys
            in A.TYCONSTRUCT(newArgTys, tyConPath, loc)
            end
        | A.TYTUPLE(tys, loc) =>
          A.TYTUPLE(map subst tys, loc)
        | A.TYFUN(rangeTy, domainTy, loc) =>
          A.TYFUN(subst rangeTy, subst domainTy, loc)
        | A.TYPOLY(tvarList, ty, loc) => 
          let
            val shadowNameList =
                SymbolSet.fromList
                  (map (fn ({symbol,...},_) => symbol) tvarList)
            fun newSubstFun  (tyID as ({symbol,...}, loc)) =
                if SymbolSet.member (shadowNameList, symbol)
                then A.TYID tyID
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
                        SymbolEnv.insert(map, tyVar, destTy))
                    SymbolEnv.empty
                    (ListPair.zip(tyVars, argTys))
              fun subst (tyID as ({symbol, isEq}, loc)) =
                  case SymbolEnv.find(tyVarMap, symbol) of
                    NONE =>
                    (enqueueError(loc, E.NotBoundTyvar {tyvar = symbol});
                     A.TYID tyID)
                  | SOME destTy => destTy
            in substTyVarInTy subst ty
            end
        val typeMap =
            foldr
            (fn ({tyvars=tyargs, tyConSymbol=symbol, ty = (ty, _),...}, map) =>
                SymbolEnv.insert(map, symbol, (tyargs, ty)))
            SymbolEnv.empty
            withTypeBinds
        fun expandInTy ty =
            case ty of
              A.TYWILD _ => ty
            | A.TYID _ => ty
            | A.FREE_TYID _ => ty
            | A.TYRECORD {ifFlex, fields=labelTys, loc} =>
              let
                val newLabelTys =
                    map (fn (label, ty) => (label, expandInTy ty)) labelTys
              in
                A.TYRECORD {ifFlex=ifFlex, fields=newLabelTys, loc=loc}
              end
            | A.TYCONSTRUCT (argTys, tyConPath, loc) =>
              let 
                val expandedArgTys = map expandInTy argTys
              in
                case tyConPath of
                  [tyConName] =>
                  (case SymbolEnv.find (typeMap, tyConName) of
                     SOME (withTyVars, withTy) =>
                     let
                       val withTyVarNames = map #symbol withTyVars
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
        fun expandInDataCon {symbol, ty, loc} =
            let
              val newTyOpt =
                  case ty of NONE => NONE | SOME ty => SOME(expandInTy ty)
            in {symbol = symbol, ty = newTyOpt, loc = loc} end
      in
        fn {tyvars, symbol, conbind, loc} =>
           {tyvars=tyvars, symbol = symbol, loc = loc,
            conbind = map expandInDataCon conbind}
      end

  type env = (fixity * loc) SymbolEnv.map

  fun extendFixEnv (newFixEnv, fixEnv:env) : env =
      SymbolEnv.unionWith #1 (newFixEnv, fixEnv)

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
  fun findFixity (fixEnv:env) longsymbol =
      case longsymbol of
        [symbol] =>
        (case SymbolEnv.find (fixEnv, symbol) of
           SOME (v,loc) => 
           let
             val defSym = 
                 Symbol.mkSymbol (Symbol.symbolToString symbol) loc
             val _ = 
                 Analyzers.insertUPRefMap (symbol, defSym)
           in
             v
           end
         | _ => NONFIX)
      | _ => NONFIX

  fun resolveInfixError getLongsymbol (Fixity.Conflict, _, loc) =
      EU.enqueueError (loc, E.InvalidFixityPrecedence)
    | resolveInfixError getLongsymbol (Fixity.BeginWithInfix, exp, loc) =
      enqueueError (loc, E.BeginWithInfixID (getLongsymbol exp))
    | resolveInfixError getLongsymbol (Fixity.EndWithInfix, exp, loc) =
      enqueueError (loc, E.EndWithInfixID (getLongsymbol exp))

    fun elabSequence elabolator env elements =
      let
        val (elaborateds, env) =
          foldl
          (fn (element, (elaborateds, env')) =>
           let
             val (elaborated, env'') =
               elabolator (extendFixEnv (env', env)) element
           in
             (
              elaborated :: elaborateds,
              SymbolEnv.unionWith #1 (env'', env')
              )
           end)
          (nil, SymbolEnv.empty)
          elements
      in
        (List.concat(rev elaborateds), env)
      end

  fun truePat loc = PC.PLPATID(mkLongsymbol ["true"] loc)
  fun falsePat loc = PC.PLPATID(mkLongsymbol ["false"] loc)
  fun trueExp loc = PC.PLVAR(mkLongsymbol ["true"] loc)
  fun falseExp loc = PC.PLVAR(mkLongsymbol ["false"] loc)
  fun unitPat loc = PC.PLPATCONSTANT(A.UNITCONST, loc)
  fun unitExp loc = PC.PLCONSTANT(A.UNITCONST, loc)

  fun elabLabeledSequence elaborator elements =
      map (fn (label, element) => (label, elaborator element)) elements

  fun elabFFITy ty =
      case ty of
        A.FFITYVAR x => PC.FFITYVAR x
      | A.FFIRECORDTY (labelTys, loc) =>
        let val newLabelTys = elabLabeledSequence elabFFITy labelTys
        in
          checkRecordLabelDuplication
              #1 labelTys loc E.DuplicateRecordLabelInRawType;
          PC.FFIRECORDTY (newLabelTys, loc)
        end
      | A.FFICONTY (argTys, tyConPath, loc) =>
        PC.FFICONTY (map elabFFITy argTys, tyConPath, loc)
      | A.FFITUPLETY (tys, loc) =>
        PC.FFIRECORDTY (RecordLabel.tupleList (map elabFFITy tys), loc)
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
        fun getLongsymbol (A.EXPID longsymbol) = longsymbol
          | getLongsymbol exp = raise Bug.Bug "getLongsymbol expects EXPID."
        fun elab (Fixity.APP (x, y, loc)) =
            PC.PLAPPM (elab x, [elab y], loc)
          | elab (Fixity.OP2 (f, (x, y), loc)) =
            PC.PLAPPM
              (elab f,
               [PC.PLRECORD (RecordLabel.tupleList [elab x, elab y], loc)],
               loc)
          | elab (Fixity.TERM (x, _)) =
            elabExp env x
        val src =
            map (fn exp as A.EXPID longsymbol =>
                    (findFixity env longsymbol, exp, A.getLocExp exp)
                  | exp => (NONFIX, exp, A.getLocExp exp))
                elist
      in
        elab (Fixity.parse (resolveInfixError getLongsymbol) src)
      end

  (**
   *  transforms infix constructor application pattern into non-infix
   * constructor application pattern.
   * This function also perform elaboration.
   *)
  and resolveInfixPat env elist =
      let
        fun getLongsymbol (A.PATID {longsymbol, ...}) = longsymbol
          | getLongsymbol pat = raise Bug.Bug "getLongsymbol expects PATID"
        fun elab (Fixity.APP (x, y, loc)) =
            PC.PLPATCONSTRUCT (elab x, elab y, loc)
          | elab (Fixity.OP2 (f, (x, y), loc)) =
            PC.PLPATCONSTRUCT
              (elab f,
               PC.PLPATRECORD
                 (false, RecordLabel.tupleList [elab x, elab y], loc),
               loc)
          | elab (Fixity.TERM (x, _)) =
            elabPat env x
        val src =
            map (fn pat as A.PATID {opPrefix=false, longsymbol, loc} =>
                    (findFixity env longsymbol, pat, loc)
                  | pat => (NONFIX, pat, A.getLocPat pat))
                elist
      in
        elab (Fixity.parse (resolveInfixError getLongsymbol) src)
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
                      A.PATROWPAT(RecordLabel.fromInt 1, leftPat, leftLoc),
                      A.PATROWPAT(RecordLabel.fromInt 2, rightPat, rightLoc)
                    ],
                    loc = Loc.mergeLocs (leftLoc, rightLoc)
                  }
            end

        fun getArg arg = 
            case arg of 
              A.PATID {opPrefix=opf, longsymbol=fid, loc=loc} =>
              if 
                (case findFixity env fid of
                   NONFIX => true | _ => opf)
              then arg 
              else
                (
                  enqueueError (loc, E.InfixUsedWithoutOP fid);
                  arg
                )
            | _ => arg
                
        (**
          Picks up the function ID and asserts that it is nonfix id or infix
          id with "op" modifier.
          For other arguments, the resolveInfixPat will check that no infix
          ID is used without "op".
         *)
        fun transNonfixForm (pats, tyOpt, exp, loc) =
            case pats of
              pat :: argPats =>
              let
                val loc = A.getLocPat pat
                val pat = assertPattern pat
                val longsymbol = longsymbolInPattern pat
                val opf = opPrefixInPattern pat
              in
                if
                  (case findFixity env longsymbol of
                     NONFIX => true | _ => opf)
                then (opf, pat, map getArg argPats, tyOpt, exp, loc)
                else
                  (
                   enqueueError
                     (loc, E.InfixUsedWithoutOP longsymbol);
                   (opf, pat, argPats, tyOpt, exp, loc)
                  )
              end
            | nil => raise bug "impossible nil args in transnonfix"

        (**
         * infix function header is converted to nonfix function header.
         *)
        fun resolveCase2 (args, tyOpt, exp, loc) =
             case args of
               A.PATAPPLY([leftArg,
                           pat as A.PATID {opPrefix=false, longsymbol=id, loc},
                           rightArg], _)
               :: otherArgs =>
               (case findFixity env id of
                  NONFIX => transNonfixForm (args, tyOpt, exp, loc)
                | _ =>
                  let val newArg = make2TuplePat(getArg leftArg, getArg rightArg)
                  in (true, pat, newArg :: otherArgs, tyOpt, exp, loc)
                  end)
             | _ => transNonfixForm (args, tyOpt, exp, loc)

        (**
         * infix function header is converted to nonfix function header.
         *)
        fun resolveCase1 (args, tyOpt, exp, loc) =
             case args of
               [leftArg, pat as A.PATID {opPrefix=false, longsymbol=id, loc}, rightArg]
               =>
               (case findFixity env id of
                  NONFIX => resolveCase2 (args, tyOpt, exp, loc)
                | _ =>
                  let val newArg = make2TuplePat(getArg leftArg, getArg rightArg)
                  in (true, pat, [newArg], tyOpt, exp, loc)
                  end)
             | _ => resolveCase2 (args, tyOpt, exp, loc)
      in
        {fdecl=map resolveCase1 fdecls, loc=loc}
      end

  and elabFunDecls env {fdecl=fdecls, loc=loc} =
      let
        val (opfs, funPats, args, exps, locs) =
            foldr
                (fn ((opf, funPat, arg, optTy, exp, loc), (opfs, funPats, args, exps, locs)) =>
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
                       newExp :: exps,
                       loc :: locs
                      )
                    end)
                (nil, nil, nil, nil, nil)
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
        val fdecl = (fpat, map (fn ((x,y),z) => (x,y,z))
                               (ListPair.zip (ListPair.zip (args, exps), locs)))
      in
        {fdecl=fdecl, loc=loc}
      end

  and elabDataBindsWithTypeBinds env (dataBinds, withTypeBinds, loc) =
      let
        fun elabDataCon {conSymbol, tyOpt, loc, ...} = {symbol=conSymbol, ty=tyOpt, loc = loc}
        fun elabDataBind {tyvars=tvars, tyConSymbol=name, loc, rhs=dataCons,...} =
            {tyvars=tvars, symbol=name, conbind = map elabDataCon dataCons, loc=loc}
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
            map (fn {tyvars=tvars,tyConSymbol=name,ty=(ty,_),...} =>
                    UserErrorUtils.checkSymbolDuplication
                      (fn {symbol,isEq} => symbol) tvars E.DuplicateTypParam)
                withTypeBinds
        val expandedDataBinds =
            map (expandWithTypesInDataBind withTypeBinds) newDataBinds
        val withTypeBinds =
            map (fn {tyvars, tyConSymbol, ty=(ty,_), loc,...} => (tyvars, tyConSymbol, ty, loc)) withTypeBinds
      in
        (expandedDataBinds, withTypeBinds)
      end

  and elabExp env ast = 
      case ast of 
        A.EXPCONSTANT x => PC.PLCONSTANT x
      | A.EXPSIZEOF (ty, loc) => PC.PLSIZEOF (ty, loc)
      | A.EXPID x => PC.PLVAR x
      | A.EXPOPID (x,loc) => PC.PLVAR x
      | A.EXPRECORD (stringExpList, loc) =>
        (
          checkRecordLabelDuplication
              #1 stringExpList loc E.DuplicateRecordLabel;
          PC.PLRECORD (elabLabeledSequence (elabExp env) stringExpList, loc)
        )
      | A.EXPRECORD_UPDATE (exp, stringExpList, loc) =>
        (
          checkRecordLabelDuplication
              #1 stringExpList loc E.DuplicateRecordLabel;
          PC.PLRECORD_UPDATE
          (
            elabExp env exp,
            elabLabeledSequence (elabExp env) stringExpList,
            loc
          )
        )
      | A.EXPRECORD_UPDATE2 (exp, exp2, loc) =>
        PC.PLRECORD_UPDATE2
          (
            elabExp env exp,
            elabExp env exp2,
            loc
          )
      | A.EXPRECORD_SELECTOR (x, loc) => PC.PLRECORD_SELECTOR(x, loc)
      | A.EXPTUPLE (elist, loc) =>
        PC.PLRECORD(RecordLabel.tupleList(map (elabExp env) elist), loc)
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
                 [PC.PLRECORD(RecordLabel.tupleList [elabExp env x, y], loc)],
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
              ([falsePat loc], falseExp loc, loc),
              ([truePat loc], ple2, loc)
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
              ([truePat loc], trueExp loc, loc),
              ([falsePat loc], ple2, loc)
             ],
             PC.MATCH,
             loc
            )
             
        end
      | A.EXPHANDLE (e1, match, loc) =>
        PC.PLHANDLE
            (
              elabExp env e1,
              map (fn (x, y, loc) => (elabPat env x, elabExp env y, loc)) match,
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
           [([truePat loc], ple2, loc),
            ([falsePat loc], ple3, loc)],
           PC.MATCH,
           loc)
        end
      | A.EXPWHILE (condExp, bodyExp, loc) =>
        let
          val newid = Symbol.generate ()
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
                     PC.PLAPPM(PC.PLVAR [newid],
                               [unitExp loc], loc),
                     loc
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
                       [([truePat loc], whbody, loc),
                        ([falsePat loc], unitExp loc, loc)],
                       loc
                      ),
                    [condPl],
                    loc
                   ),
                 loc
                )
               ],
               loc
              )
        in
          PC.PLLET
          (
            [PC.PDVALREC(emptyTvars, [(PC.PLPATID [newid], body, Loc.noloc)], loc)],
            PC.PLAPPM(PC.PLVAR [newid], [unitExp loc], loc),
            loc
          )
        end
      | A.EXPCASE (objectExp, match, loc) =>
        PC.PLCASEM
        (
          [elabExp env objectExp],
          map (fn (x, y, loc) => ([elabPat env x], elabExp env y, loc)) match,
          PC.MATCH,
          loc
        )
      | A.EXPFN (match, loc) =>
        PC.PLFNM(map (fn (x, y, loc) => ([elabPat env x], elabExp env y, loc)) match,
                 loc)
      | A.EXPLET (decs, elist, loc) => 
        let
          val (pdecs, env') = elabDecs env decs
          val newEnv = extendFixEnv (env',env)
          val body =
              case map (elabExp newEnv) elist of
                [exp] => exp
              | expList => PC.PLSEQ (expList, loc)
        in
          PC.PLLET (pdecs, body, loc)
        end
      | A.EXPFFIIMPORT (exp, ty, loc) =>
        PC.PLFFIIMPORT (elabFFIFun env exp, elabFFITy ty, loc)
      | A.EXPSQL (sqlexp, loc) =>
        ElaborateSQL.elaborateExp
          {elabExp = elabExp env,
           elabPat = elabPat env}
          env
          (sqlexp, loc)
      | A.EXPFOREACH (foreach, loc) =>
        ElaborateForeach.elaborateExp
          {elabExp = elabExp env, elabPat = elabPat env}
          (foreach, loc)
      | A.EXPJOIN (bool, exp1, exp2, loc) => PC.PLJOIN (bool, elabExp env exp1, elabExp env exp2, loc)
      | A.EXPDYNAMIC (exp, ty, loc) => PC.PLDYNAMIC (elabExp env exp, ty, loc)
      | A.EXPDYNAMICIS (exp, ty, loc) => PC.PLDYNAMICIS (elabExp env exp, ty, loc)
      | A.EXPDYNAMICNULL (ty, loc) => PC.PLDYNAMICNULL (ty, loc)
      | A.EXPDYNAMICTOP (ty, loc) => PC.PLDYNAMICTOP (ty, loc)
      | A.EXPDYNAMICVIEW (exp, ty, loc) => PC.PLDYNAMICVIEW (elabExp env exp, ty, loc)
      | A.EXPDYNAMICCASE (exp, matches, loc) =>
        PC.PLDYNAMICCASE 
          (elabExp env exp, 
           map (fn (tyvars, x, y, loc) => (tyvars, elabPat env x, elabExp env y, loc))
               matches,
           loc)
      | A.EXPREIFYTY (ty, loc) => PC.PLREIFYTY (ty, loc)

  and elabFFIFun env ffiFun =
      case ffiFun of
        A.FFIFUN exp => PC.PLFFIFUN (elabExp env exp)
      | A.FFIEXTERN s => PC.PLFFIEXTERN s

  and elabPat env pat = 
      case pat of
        A.PATWILD loc => PC.PLPATWILD loc
      | A.PATCONSTANT (constant, loc) =>
        (case constant of
           A.REAL _ =>
           (* According to syntactic restriction of ML Definition, real
            * constant pattern is not allowed. *)
           (enqueueError (loc, E.RealConstantInPattern);
            PC.PLPATCONSTANT (constant, loc))
         | _ => PC.PLPATCONSTANT (constant, loc))
      | A.PATID {opPrefix=b, longsymbol, loc} => PC.PLPATID longsymbol
      | A.PATAPPLY (plist, loc) => resolveInfixPat env plist
      | A.PATRECORD {ifFlex=flex, fields=pfields, loc=loc} =>
        (
          checkRecordLabelDuplication
              getLabelOfPatRow pfields loc E.DuplicateRecordLabelInPat;
          PC.PLPATRECORD (flex, map (elabPatRow env) pfields, loc)
        )
      | A.PATTUPLE (plist, loc) =>
        PC.PLPATRECORD (false, RecordLabel.tupleList (map (elabPat env) plist), loc)
      | A.PATLIST (elist, loc) =>
        let
          val plexp =
              foldr
              (fn (x, y) =>
                  PC.PLPATCONSTRUCT
                  (
                    PC.PLPATID(mkLongsymbol ["::"] loc),
                    PC.PLPATRECORD(false, RecordLabel.tupleList [elabPat env x, y], loc),
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
          val symbol =
              case longsymbol of
                [id] => id
              | _ => 
                (enqueueError (loc, E.LeftOfASMustBeVariable);
                 Symbol.coerceLongsymbolToSymbol longsymbol)
        in
          checkReservedNameForValBind symbol;
          PC.PLPATLAYERED(symbol, NONE, elabPat env pat, loc)
        end
      | A.PATLAYERED
          (A.PATTYPED
             (A.PATID{opPrefix, longsymbol, loc=loc1}, ty, loc2), pat, loc) =>
        let
          val symbol =
              case longsymbol of
                [id] => id
              | _ => 
                (enqueueError (loc, E.LeftOfASMustBeVariable);
                 Symbol.coerceLongsymbolToSymbol longsymbol)
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
        | A.PATROWVAR (symbol, optTy, optPat, loc) => 
          let
            val _ = checkReservedNameForValBind symbol
            val pat =
                case optPat of
                  SOME pat =>
                  PC.PLPATLAYERED(symbol, optTy, elabPat env pat,loc)
                | _ =>
                  case optTy of
                    SOME ty => PC.PLPATTYPED (PC.PLPATID [symbol], ty, loc)
                  | _ => PC.PLPATID [symbol]
          in (RecordLabel.fromSymbol symbol, pat)
          end

    and elabDec env dec = 
        case dec of
          A.DECVAL (tyvs, decls, loc) =>
          let
            val newDecls =
                map (fn (pat, e, loc) => (elabPat env pat, elabExp env e, loc)) decls
          in
            ([PC.PDVAL (tyvs, newDecls, loc)],
             SymbolEnv.empty)
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
            fun elabBind (pat, exp, loc) =
                let
                  val elabedPat = elabPat env pat
                  val elabedExp = elabExp env exp
                in
                  assertPattern elabedPat; (* after elab *)
                  assertExp exp; (* before elab *)
                  (elabedPat, elabedExp, loc)
                end
            fun getNameOfBound (PC.PLPATID [symbol], _, _) =
                SOME symbol
              | getNameOfBound (PC.PLPATTYPED (pat, _, _), exp, loc) =
                getNameOfBound (pat, exp, loc)
              | getNameOfBound (pat, _, _) =
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
             SymbolEnv.empty)
          end
        | A.DECPOLYREC ( decls, loc) =>
          let
            (* right hand side of val rec must be "fn". *)
            fun assertExp (A.EXPFN _) = ()
              (* fix attempt for val rec x = (fn x =>x) is rejected  ??? *)
              | assertExp (A.EXPAPP ([exp],_)) = assertExp exp
              | assertExp exp = enqueueError (loc, E.NotFnBoundInValRec)
            fun elabBind (symbol, ty, exp, loc) =
                let
                  val elabedExp = elabExp env exp
                in
                  assertExp exp; (* before elab *)
                  (symbol, ty, elabedExp, loc)
                end
            val elabedBinds = map elabBind decls
            val _ =
                checkSymbolDuplication
                    (fn (f, ty, e, loc) => f)
                    elabedBinds
                    E.DuplicateVarNameInValRec
          in
            ([PC.PDVALPOLYREC(elabedBinds, loc)],
             SymbolEnv.empty)
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
             SymbolEnv.empty)
          end
        | A.DECTYPE {tbs=tyBinds, loc,...} =>
          let
            fun elabTyBind {tyvars=tvars, tyConSymbol=symbol, ty=(ty,_), loc} =
                let
                  val newTVars =
                      map
                        (fn {symbol, isEq} => {symbol=symbol, isEq=false})
                        tvars
                  val newTy =
                      substTyVarInTy
                          (fn ({symbol, isEq}, loc) =>
                              A.TYID({symbol=symbol, isEq=false}, loc))
                          ty
                in
                  (newTVars, symbol, newTy, loc)
                end
            val newTyBinds = map elabTyBind tyBinds
          in
            checkSymbolDuplication
                #2
                newTyBinds E.DuplicateTypeNameInType;
            ([PC.PDTYPE (newTyBinds, loc)], SymbolEnv.empty)
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
              SymbolEnv.empty
            )
          end
        | A.DECREPLICATEDAT {defSymbol, refLongsymbol, loc} =>
          ([PC.PDREPLICATEDAT (defSymbol, refLongsymbol, loc)], SymbolEnv.empty) 
        | A.DECABSTYPE {abstys=dataBinds, withtys=withTypeBinds, body=(decs,_), loc,...} =>
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
            ([PC.PDEXD (map elabExnBind exnBinds, loc)], SymbolEnv.empty)
          end
        | A.DECLOCAL (dec1, dec2, loc) => 
          let
            val (pdecs1, env1) = elabDecs env dec1
            val (pdecs2, env2) = elabDecs (extendFixEnv (env1, env)) dec2
          in
            ([PC.PDLOCALDEC(pdecs1, pdecs2, loc)], env2)
          end
        | A.DECOPEN(longids,loc) => ([PC.PDOPEN(longids, loc)], SymbolEnv.empty)
        | A.DECINFIX (n, idlist, loc) =>
          let
            val n = elabInfixPrec (n, loc)
          in
            (
              [PC.PDINFIXDEC(n, idlist, loc)],
              foldr
                (fn (x, env) => SymbolEnv.insert (env, x, (INFIX n, loc)))
                SymbolEnv.empty
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
                (fn (x, env) => SymbolEnv.insert (env, x, (INFIXR n, loc)))
                SymbolEnv.empty
                idlist
            )
          end
        | A.DECNONFIX (idlist, loc) =>
          (
            [PC.PDNONFIXDEC(idlist, loc)],
            foldr
                (fn (x, env) => SymbolEnv.insert (env, x, (NONFIX, loc)))
                SymbolEnv.empty
                idlist
          )

    and elabDecs env decs = elabSequence elabDec env decs


    fun elabDec' env dec =
        elabDec env dec

    val elabDec = elabDec'

end
