(**
 * FFI compilation.
 *
 * @copyright (c) 2016, Tohoku University.
 * @author Atsushi Ohori
 * @author Tomohiro Sasaki
 * @author UENO Katsuhiro
 *)
structure FFICompilation =
struct

  structure T = Types
  structure A = AbsynConst
  structure C = TypedCalc
  structure D = TypedCalcCon
  structure BT = BuiltinTypes
  structure BP = BuiltinPrimitive
  structure U = UserLevelPrimitive
  structure RyU = ReifyUtils
  structure RyD = ReifiedTyData

  fun isSimpleExp tpexp =
      case tpexp of
        C.TPERROR => true
      | C.TPCONSTANT _ => true
      | C.TPVAR _ => true
      | C.TPEXVAR _ => true
      | C.TPRECFUNVAR _ => true
      | C.TPFNM _ => false
      | C.TPAPPM _ => false
      | C.TPDATACONSTRUCT _ => false
      | C.TPEXNCONSTRUCT _ => false
      | C.TPEXNTAG _ => true
      | C.TPEXEXNTAG _ => true
      | C.TPCASEM _ => false
      | C.TPSWITCH _ => false
      | C.TPCATCH _ => false
      | C.TPTHROW _ => false
      | C.TPDYNAMICCASE _ => false
      | C.TPDYNAMICEXISTTAPP _ => false
      | C.TPPRIMAPPLY _ => false
      | C.TPOPRIMAPPLY _ => false
      | C.TPRECORD _ => false
      | C.TPSELECT _ => false
      | C.TPMODIFY _ => false
      | C.TPMONOLET _ => false
      | C.TPLET _ => false
      | C.TPRAISE _ => false
      | C.TPHANDLE _ => false
      | C.TPPOLY _ => false
      | C.TPTAPP _ => false
      | C.TPFFIIMPORT _ => false
      | C.TPFOREIGNSYMBOL _ => true
      | C.TPFOREIGNAPPLY _ => false
      | C.TPCALLBACKFN _ => false
      | C.TPCAST ((tpexp1, ty1), ty2, loc1) => isSimpleExp tpexp1
      | C.TPSIZEOF _ => true
      | C.TPJOIN _ => false
      | C.TPDYNAMIC _ => false
      | C.TPDYNAMICIS _ => false
      | C.TPDYNAMICVIEW _ => false
      | C.TPDYNAMICNULL _ => false
      | C.TPDYNAMICTOP _ => false
      | C.TPREIFYTY _ => true

  val newVar = TypedCalcUtils.newTCVarInfo

  fun toSimpleExp loc (exp, ty) =
      if isSimpleExp exp
      then (fn x => x, (exp, ty))
      else
        let
          val var = newVar loc ty
        in
          (fn body => D.TPLET {decls = [C.TPVAL ((var, exp), loc)],
                               body = body,
                               loc = loc},
           D.TPVAR var)
        end

  fun toSimpleExpList loc exps =
      foldr (fn (exp, (g, exps)) =>
                let
                  val (f, e) = toSimpleExp loc exp
                in
                  (f o g, e :: exps)
                end)
            (fn x => x, nil)
            exps

  fun bitCast loc (exp as (_, ty), ty2) =
      D.TPPRIMAPPLY
        {primOp = {primitive = BP.Cast BP.BitCast,
                   ty = T.FUNMty ([ty], ty2)},
         instTyList = NONE,
         argExp = exp,
         loc = loc}

  fun explodeRecord loc (C.TPRECORD {fields, ...}, T.RECORDty tys) =
      RecordLabel.Map.listItems
        (RecordLabel.Map.mergeWith
           (fn (SOME exp, SOME ty) => SOME (exp, ty)
             | _ => raise Bug.Bug "explodeRecord")
           (fields, tys))
    | explodeRecord loc (exp as (_, T.RECORDty tys)) =
      map (fn label =>
              D.TPSELECT
                NONE
                {exp = exp, label = label, loc = loc})
          (RecordLabel.Map.listKeys tys)
    | explodeRecord _ _ = raise Bug.Bug "explodeRecord"

  fun recordLabelMapFromList fields =
      foldl (fn ((k, v), z) => RecordLabel.Map.insert (z, k, v))
            RecordLabel.Map.empty
            fields

  fun implodeRecord loc fields =
      D.TPRECORD
        {fields = recordLabelMapFromList fields,
         loc = loc}

  fun unitExp loc =
      D.TPCONSTANT {const = A.UNITCONST, ty = BT.unitTy, loc = loc}

  fun composeArg loc nil = unitExp loc
    | composeArg loc [exp] = exp
    | composeArg loc exps = implodeRecord loc (RecordLabel.tupleList exps)

  fun decomposeArg loc nil = (newVar loc BT.unitTy, nil)
    | decomposeArg loc [ty] = let val v = newVar loc ty in (v, [D.TPVAR v]) end
    | decomposeArg loc tys =
      let val var = newVar loc (T.RECORDty (RecordLabel.tupleMap tys))
      in (var, explodeRecord loc (D.TPVAR var))
      end

  fun hasFunTy ffity =
      case ffity of
        C.FFIBASETY _ => false
      | C.FFIFUNTY _ => true
      | C.FFIRECORDTY (fields, loc) =>
        List.exists (fn (k,v) => hasFunTy v) fields

  fun hasSortedField nil = true
    | hasSortedField [_] = true
    | hasSortedField ((l1,_)::(t as (l2,_)::_)) =
      RecordLabel.compare (l1, l2) = LESS andalso hasSortedField t

  fun zipApp nil nil = nil
    | zipApp (f::ft) (h::t) = f h :: zipApp ft t
    | zipApp _ _ = raise Bug.Bug "zipApp"

  fun HandleAndReRaise loc exnCon {exp, ty} =
      let
        val exnVar = RyU.newVar (BT.exnTy)
        val exnExp = C.TPEXNCONSTRUCT
                       {exn = exnCon,
                        argExpOpt = NONE,
                        loc = loc}
        val raiseExp = C.TPRAISE {exp = exnExp, ty = ty, loc=loc}
        val exnCaseExp =
            C.TPSWITCH
              {exp = C.TPVAR exnVar,
               defaultExp = C.TPRAISE {exp = C.TPVAR exnVar, ty = ty, loc=loc},
               expTy = BT.exnTy,
               loc = loc,
               ruleList = C.EXNCASE [{exn = exnCon, argVarOpt = NONE,
                                      body = raiseExp}],
               ruleBodyTy = ty}
      in
        C.TPHANDLE
          {exp = exp,
           exnVar = exnVar,
           handler = exnCaseExp,
           resultTy = ty,
           loc = loc}
      end

  fun stubExport ffity =
      case ffity of
        C.FFIBASETY (ty, loc) => (ty, fn x => x)
      | C.FFIRECORDTY (fields, loc) =>
        let
          val stubs = map (fn (k, ty) => (k, stubExport ty)) fields
          val retTys = map (fn (k, (ty, _)) => (k, ty)) stubs
          fun stubFields exps =
              RecordLabel.tupleList
                (zipApp (map (fn (_,(_,f)) => f) stubs) exps)
        in
          (T.RECORDty (recordLabelMapFromList retTys),
           if hasSortedField fields andalso not (hasFunTy ffity)
           then fn x => x
           else fn exp =>
                   implodeRecord loc (stubFields (explodeRecord loc exp)))
        end
      | C.FFIFUNTY (attributes, argTys, NONE, retTys, loc) =>
        let
          val attributes =
              getOpt (attributes, FFIAttributes.defaultFFIAttributes)
          val (argTys, importFns) =
              ListPair.unzip (map stubImport argTys)
          val ffiArgVars = map (newVar loc) argTys
          val argExps = zipApp importFns (map D.TPVAR ffiArgVars)
          val argExp = composeArg loc argExps
          val (retTys, exportFns) = ListPair.unzip (map stubExport retTys)
          val (retVar, retExps) = decomposeArg loc retTys
          val ffiRetExps = zipApp exportFns retExps
          val ffiRetExp = composeArg loc ffiRetExps
          val isVoid = case ffiRetExps of nil => true | _::_ => false
        in
          (T.FUNMty ([#2 argExp], #ty retVar),
           fn funExp =>
              D.TPCALLBACKFN
                {attributes = attributes,
                 isVoid = isVoid,
                 argVarList = ffiArgVars,
                 bodyExp =
                   D.TPLET
                     {decls =
                        [#1 (D.TPVAL
                               ((retVar,
                                 D.TPAPPM
                                   {funExp = funExp,
                                    argExpList = [argExp],
                                    loc = loc}),
                                loc))],
                      body = ffiRetExp,
                      loc = loc},
                 loc = loc})
        end
      | C.FFIFUNTY (attributes, argTys, SOME _, retTys, loc) =>
        raise Bug.Bug "stubExport: FFIFUNTY"

  and stubImport ffity =
      case ffity of
        C.FFIBASETY (ty, loc) => (ty, fn x => x)
      | C.FFIRECORDTY _ => raise Bug.Bug "stubImport: FFIRECORDTY"
      | C.FFIFUNTY (attributes, argTys, varTys, retTys, loc) =>
        let
          val attributes =
              getOpt (attributes, FFIAttributes.defaultFFIAttributes)
          val (argTys1, exportFns1) =
              ListPair.unzip (map stubExport argTys)
          val (argTys2, exportFns2) =
              case varTys of
                NONE => (nil, nil)
              | SOME varTys => ListPair.unzip (map stubExport varTys)
          val stubArgTys = argTys1 @ argTys2
          val (argVar, argExps) = decomposeArg loc stubArgTys
          val ffiArgExps = zipApp (exportFns1 @ exportFns2) argExps
          val ffiArgTys = map #2 ffiArgExps
          val (ffiArgTyList, ffiVarArgTyList) =
              case varTys of
                NONE => (ffiArgTys, NONE)
              | SOME _ => ListUtils.split ffiArgTys (length argTys2)
          val (ffiRetTys, importFns) =
              ListPair.unzip (map stubImport retTys)
          val ffiRetTy =
              case ffiRetTys of
                nil => NONE
              | [ty] => SOME ty
              | _ => raise Bug.Bug "stubImport: FFIFUNTY"
          val (ffiRetVar, ffiRetExps) = decomposeArg loc ffiRetTys
          val retExps = zipApp importFns ffiRetExps
          val retExp = composeArg loc retExps
        in
          (T.BACKENDty
             (T.FOREIGNFUNPTRty
                {argTyList = ffiArgTyList,
                 varArgTyList = ffiVarArgTyList,
                 resultTy = ffiRetTy,
                 attributes = attributes}),
           fn funExp =>
              D.TPFNM
                {argVarList = [argVar],
                 bodyExp =
                   D.TPLET
                     {decls =
                        [#1 (D.TPVAL
                               ((ffiRetVar,
                                 D.TPFOREIGNAPPLY
                                   {funExp = funExp,
                                    argExpList = ffiArgExps,
                                    loc = loc}),
                                loc))],
                      body = retExp,
                      loc = loc},
                 loc = loc})
        end

  fun compileFFIexp {funExp, ffiTy, stubTy, loc} =
      case funExp of
        C.TPFFIFUN (ptrExp, ptrTy) =>
        let
          val ptrExp = (compileExp ptrExp, ptrTy)
          val (letFn, ptrExp) = toSimpleExp loc ptrExp
          val (funptrTy, importExpFn) = stubImport ffiTy
        in
          #1 (letFn (importExpFn (bitCast loc (ptrExp, funptrTy))))
        end
      | C.TPFFIEXTERN name =>
        let
          val (funptrTy, importExpFn) = stubImport ffiTy
          val symbolExp = D.TPFOREIGNSYMBOL {name=name, ty=funptrTy, loc=loc}
        in
          #1 (importExpFn symbolExp)
        end

  and compileJoinExp isJoin loc {resultTy, args = (arg1, arg2),
                                 argTys = (argTy1, argTy2)} =
      (* 2016-10-27 sasaki : JOINの試験実装 *)
      (* _join(arg1:argTy1,arg2:argTy2):resultTy
       * =>
       * ReifiedTermToML.reifiedTermToML
       *   (NaturalJoin.naturalJoin
       *      (ReifyTerm.toReifiedTerm (arg1 : argTy1),
       *       ReifyTerm.toReifiedTErm (arg2 : argTy2)))
       * : resultTy
       *)
      let
        val NaturalJoin =
            if isJoin then RyU.MonoVar (U.REIFY_exInfo_naturalJoin ())
            else RyU.MonoVar (U.REIFY_exInfo_extend ())
        fun ToReifiedTerm instTy =
            RyU.InstVar {exVarInfo = U.REIFY_exInfo_toReifiedTerm (),
                         instTy = instTy}
        val Arg1 = {exp = compileExp arg1, ty= argTy1}
        val Arg2 = {exp = compileExp arg2, ty= argTy2}
        val Term1 = RyU.Apply loc (ToReifiedTerm argTy1) Arg1
        val Term2 = RyU.Apply loc (ToReifiedTerm argTy2) Arg2
        val JoinedTerm = RyU.Apply loc NaturalJoin (RyU.Pair loc Term1 Term2)
        val ReifiedTermToML =
            RyU.InstVar {exVarInfo = U.REIFY_exInfo_reifiedTermToML (),
                         instTy = resultTy}
      in
        #exp (RyU.Apply loc ReifiedTermToML JoinedTerm)
      end

  and compileExp tpexp =
      case tpexp of
        C.TPERROR => tpexp
      | C.TPCONSTANT _ => tpexp
      | C.TPVAR _ => tpexp
      | C.TPEXVAR _ => tpexp
      | C.TPRECFUNVAR _ => tpexp
      | C.TPFNM {argVarList, bodyTy, bodyExp, loc} =>
        C.TPFNM
          {argVarList = argVarList,
           bodyTy = bodyTy,
           bodyExp = compileExp bodyExp,
           loc = loc}
      | C.TPAPPM {funExp, funTy, argExpList, loc} =>
        C.TPAPPM
          {funExp = compileExp funExp,
           funTy = funTy,
           argExpList = map compileExp argExpList,
           loc = loc}
      | C.TPDATACONSTRUCT {con, instTyList, argExpOpt, loc} =>
        C.TPDATACONSTRUCT
          {con = con,
           instTyList = instTyList,
           argExpOpt = Option.map compileExp argExpOpt,
           loc = loc}
      | C.TPEXNCONSTRUCT {exn, argExpOpt, loc} =>
        C.TPEXNCONSTRUCT
          {exn = exn,
           argExpOpt = Option.map compileExp argExpOpt,
           loc = loc}
      | C.TPEXNTAG _ => tpexp
      | C.TPEXEXNTAG _ => tpexp
      | C.TPCASEM {expList, expTyList, ruleList, ruleBodyTy, caseKind, loc} =>
        C.TPCASEM
          {expList = map compileExp expList,
           expTyList = expTyList,
           ruleList = map (fn {args, body} =>
                              {args = args, body = compileExp body})
                          ruleList,
           ruleBodyTy = ruleBodyTy,
           caseKind = caseKind,
           loc = loc}
      | C.TPSWITCH {exp, expTy, ruleList, defaultExp, ruleBodyTy, loc} =>
        let
          fun compileRule (r as {body, ...}) = r # {body = compileExp body}
        in
          C.TPSWITCH
            {exp = compileExp exp,
             expTy = expTy,
             ruleList =
               case ruleList of
                 C.CONSTCASE rules => C.CONSTCASE (map compileRule rules)
               | C.CONCASE rules => C.CONCASE (map compileRule rules)
               | C.EXNCASE rules => C.EXNCASE (map compileRule rules),
             defaultExp = compileExp defaultExp,
             ruleBodyTy = ruleBodyTy,
             loc = loc}
        end
      | C.TPCATCH {catchLabel, tryExp, argVarList, catchExp, resultTy, loc} =>
        C.TPCATCH
          {catchLabel = catchLabel,
           tryExp = compileExp tryExp,
           argVarList = argVarList,
           catchExp = compileExp catchExp,
           resultTy = resultTy,
           loc = loc}
      | C.TPTHROW {catchLabel, argExpList, resultTy, loc} =>
        C.TPTHROW
          {catchLabel = catchLabel,
           argExpList = map compileExp argExpList,
           resultTy = resultTy,
           loc = loc}
      | C.TPPRIMAPPLY {primOp, instTyList, argExp, loc} =>
        C.TPPRIMAPPLY
          {primOp = primOp,
           instTyList = instTyList,
           argExp = compileExp argExp,
           loc = loc}
      | C.TPOPRIMAPPLY {oprimOp, instTyList, argExp, loc} =>
        C.TPOPRIMAPPLY
          {oprimOp = oprimOp,
           instTyList = instTyList,
           argExp = compileExp argExp,
           loc = loc}
      | C.TPRECORD {fields, recordTy, loc} =>
        C.TPRECORD
          {fields = RecordLabel.Map.map compileExp fields,
           recordTy = recordTy,
           loc = loc}
      | C.TPSELECT {label, exp, expTy, resultTy, loc} =>
        C.TPSELECT
          {label = label,
           exp = compileExp exp,
           expTy = expTy,
           resultTy = resultTy,
           loc = loc}
      | C.TPMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
        C.TPMODIFY
          {label = label,
           recordExp = compileExp recordExp,
           recordTy = recordTy,
           elementExp = compileExp elementExp,
           elementTy = elementTy,
           loc = loc}
      | C.TPMONOLET {binds, bodyExp, loc} =>
        C.TPMONOLET
          {binds = map (fn (v, e) => (v, compileExp e)) binds,
           bodyExp = compileExp bodyExp,
           loc = loc}
      | C.TPLET {decls, body, loc} =>
        C.TPLET
          {decls = map compileDecl decls,
           body = compileExp body,
           loc = loc}
      | C.TPRAISE {exp, ty, loc} =>
        C.TPRAISE
          {exp = compileExp exp,
           ty = ty,
           loc = loc}
      | C.TPHANDLE {exp, exnVar, handler, resultTy, loc} =>
        C.TPHANDLE
          {exp = compileExp exp,
           exnVar = exnVar,
           handler = compileExp handler,
           resultTy = resultTy,
           loc = loc}
      | C.TPPOLY {btvEnv, constraints, expTyWithoutTAbs, exp, loc} =>
        C.TPPOLY
          {btvEnv = btvEnv,
           constraints = constraints,
           expTyWithoutTAbs = expTyWithoutTAbs,
           exp = compileExp exp,
           loc = loc}
      | C.TPTAPP {exp, expTy, instTyList, loc} =>
        C.TPTAPP
          {exp = compileExp exp,
           expTy = expTy,
           instTyList = instTyList,
           loc = loc}
      | C.TPFOREIGNSYMBOL _ => tpexp
      | C.TPFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        C.TPFOREIGNAPPLY
          {funExp = compileExp funExp,
           argExpList = map compileExp argExpList,
           attributes = attributes,
           resultTy = resultTy,
           loc = loc}
      | C.TPCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        C.TPCALLBACKFN
          {attributes = attributes,
           argVarList = argVarList,
           bodyExp = compileExp bodyExp,
           resultTy = resultTy,
           loc = loc}
      | C.TPCAST ((exp, ty), ty2, loc) =>
        C.TPCAST ((compileExp exp, ty), ty2, loc)
      | C.TPSIZEOF _ => tpexp
      | C.TPREIFYTY _ => tpexp
      | C.TPFFIIMPORT arg =>
        compileFFIexp arg
      | C.TPJOIN {ty, args, argtys, isJoin, loc} =>
        if isJoin then
          let
            val Body = {exp = compileJoinExp isJoin
                                loc
                                {resultTy=ty, args=args, argTys=argtys},
                        ty = ty}
            val exnCon = C.EXEXN (U.REIFY_exExnInfo_NaturalJoin ())
          in
            HandleAndReRaise loc exnCon Body
          end
        else
          compileJoinExp isJoin
                         loc
                         {resultTy=ty, args=args, argTys=argtys}
      | C.TPDYNAMIC {exp, ty, elemTy, coerceTy, loc} =>
        let
          fun TypeOf loc ty = {exp = C.TPREIFYTY (ty, loc),
                               ty = RyD.TyRepTy()}
          val exnCon = C.EXEXN (U.REIFY_exExnInfo_RuntimeTypeError ())
          val Body =
              RyU.Apply
                loc
                (RyU.InstListVar
                   {exVarInfo = U.REIFY_exInfo_coerceTermGeneric (),
                    instTyList = [elemTy, coerceTy]})
                (RyU.Pair loc {exp=exp,ty=ty} (TypeOf loc coerceTy))
        in
          HandleAndReRaise loc exnCon Body
        end
      | C.TPDYNAMICIS {exp, ty, elemTy, coerceTy, loc} =>
        let
          fun TypeOf loc ty = {exp = C.TPREIFYTY (ty, loc),
                               ty = RyD.TyRepTy()}
          val exnCon = C.EXEXN (U.REIFY_exExnInfo_RuntimeTypeError ())
          val Body =
              RyU.Apply
                loc
                (RyU.InstListVar
                   {exVarInfo = U.REIFY_exInfo_checkTermGeneric (),
                    instTyList = [elemTy]})
                (RyU.Pair loc {exp=exp,ty=ty} (TypeOf loc coerceTy))
        in
          HandleAndReRaise loc exnCon Body
        end
      | C.TPDYNAMICVIEW {exp, ty, elemTy, coerceTy, loc} =>
        let
          fun TypeOf loc ty = {exp = C.TPREIFYTY (ty, loc),
                               ty = RyD.TyRepTy()}
          val exnCon = C.EXEXN (U.REIFY_exExnInfo_RuntimeTypeError ())
          val Body =
              RyU.Apply
                loc
                (RyU.InstListVar {exVarInfo = U.REIFY_exInfo_viewTermGeneric (),
                                  instTyList = [elemTy, coerceTy]})
                (RyU.Pair loc {exp=exp,ty=ty} (TypeOf loc coerceTy))
        in
          HandleAndReRaise loc exnCon Body
        end
      | C.TPDYNAMICNULL {ty, coerceTy, loc} =>
        let
          fun TypeOf loc ty = {exp = C.TPREIFYTY (ty, loc),
                               ty = RyD.TyRepTy()}
          val {exp,...} =
              RyU.Apply
                loc
                (RyU.InstListVar {exVarInfo = U.REIFY_exInfo_null (),
                                  instTyList = [ty]})
                (TypeOf loc ty)
        in
          exp
        end
      | C.TPDYNAMICTOP {ty, coerceTy, loc} =>
        let
          fun TypeOf loc ty = {exp = C.TPREIFYTY (ty, loc),
                               ty = RyD.TyRepTy()}
          val {exp,...} =
              RyU.Apply
                loc
                (RyU.InstListVar {exVarInfo = U.REIFY_exInfo_void (),
                                  instTyList = [ty]})
                (TypeOf loc ty)
        in
          exp
        end
      | C.TPDYNAMICCASE {groupListTerm, groupListTy, dynamicTerm, dynamicTy,
                         elemTy, ruleBodyTy, loc} =>
        let
          val groupListTerm = compileExp groupListTerm
          val dynamicTerm = compileExp dynamicTerm
        in
          #exp
            (RyU.ApplyList
               loc
               (RyU.InstListVar
                  {exVarInfo = U.REIFY_exInfo_dynamicTypeCase (),
                   instTyList = [elemTy, ruleBodyTy]})
               [{exp=dynamicTerm, ty = dynamicTy},
                {exp=groupListTerm, ty=groupListTy}]
             handle exn => raise exn
            )
        end
      | C.TPDYNAMICEXISTTAPP {existInstMap, exp, expTy, instTyList, loc} =>
        C.TPDYNAMICEXISTTAPP
          {existInstMap = compileExp existInstMap,
           exp = compileExp exp,
           expTy = expTy,
           instTyList = instTyList,
           loc = loc}

  and compileFunBinds binds =
      map (fn {funVarInfo, argTyList, bodyTy, ruleList} =>
              {funVarInfo = funVarInfo,
               argTyList = argTyList,
               bodyTy = bodyTy,
               ruleList = map (fn {args, body} =>
                                  {args = args, body = compileExp body})
                              ruleList})
          binds

  and compileDecl tpdecl =
      case tpdecl of
        C.TPVAL ((var, exp), loc) =>
        C.TPVAL ((var, compileExp exp), loc)
      | C.TPFUNDECL (binds, loc) =>
        C.TPFUNDECL (compileFunBinds binds, loc)
      | C.TPPOLYFUNDECL {btvEnv, constraints, recbinds, loc} =>
        C.TPPOLYFUNDECL
          {btvEnv = btvEnv,
           constraints = constraints,
           recbinds = compileFunBinds recbinds,
           loc = loc}
      | C.TPVALREC (binds, loc) =>
        C.TPVALREC
          (map (fn {var, exp} =>
                   {var = var, exp = compileExp exp})
               binds,
           loc)
      | C.TPVALPOLYREC {btvEnv, constraints, recbinds, loc} =>
        C.TPVALPOLYREC
          {btvEnv = btvEnv,
           constraints = constraints,
           recbinds =
             map (fn {var, exp} =>
                     {var = var, exp = compileExp exp})
                 recbinds,
           loc = loc}
      | C.TPEXD _ => tpdecl
      | C.TPEXNTAGD _ => tpdecl
      | C.TPEXPORTVAR {var, exp} =>
        C.TPEXPORTVAR {var = var, exp = compileExp exp}
      | C.TPEXPORTEXN _ => tpdecl
      | C.TPEXTERNVAR _ => tpdecl
      | C.TPEXTERNEXN _ => tpdecl
      | C.TPBUILTINEXN _ => tpdecl

  fun compile decls =
      map compileDecl decls

end
