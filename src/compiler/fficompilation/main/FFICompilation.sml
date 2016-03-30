(**
 * FFI compilation.
 *
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure FFICompilation : sig

  val compile : RecordCalc.rcdecl list -> RecordCalc.rcdecl list

end =
struct

  structure R = RecordCalc
  structure TC = TypedCalc
  structure A = Absyn
  structure T = Types
  structure BT = BuiltinTypes

  fun split l n =
      let
        fun loop (nil, r, i) =
            (rev r, if i > 0 then NONE else SOME nil)
          | loop (h::l, r, i) =
            if i > 0 then loop (l, h::r, i - 1) else (rev r, SOME (h::l))
      in
        loop (l, nil, n)
      end

  fun getLocExp rcexp =
      case rcexp of
        R.RCFOREIGNAPPLY {loc,...} => loc
      | R.RCCALLBACKFN {loc,...} => loc
      | R.RCTAGOF (_,loc) => loc
      | R.RCSIZEOF (_,loc) => loc
      | R.RCINDEXOF (_,_,loc) => loc
      | R.RCCONSTANT {loc,...} => loc
      | R.RCFOREIGNSYMBOL {loc,...} => loc
      | R.RCVAR _ => Loc.noloc
      | R.RCEXVAR _ => Loc.noloc
      | R.RCPRIMAPPLY {loc,...} => loc
      | R.RCOPRIMAPPLY {loc,...} => loc
      | R.RCDATACONSTRUCT {loc,...} => loc
      | R.RCEXNCONSTRUCT {loc,...} => loc
      | R.RCEXN_CONSTRUCTOR {loc,...} => loc
      | R.RCEXEXN_CONSTRUCTOR {loc,...} => loc
      | R.RCAPPM {loc,...} => loc
      | R.RCMONOLET {loc,...} => loc
      | R.RCLET {loc,...} => loc
      | R.RCRECORD {loc,...} => loc
      | R.RCSELECT {loc,...} => loc
      | R.RCMODIFY {loc,...} => loc
      | R.RCRAISE {loc,...} => loc
      | R.RCHANDLE {loc,...} => loc
      | R.RCCASE {loc,...} => loc
      | R.RCEXNCASE {loc,...} => loc
      | R.RCSWITCH {loc,...} => loc
      | R.RCFNM {loc,...} => loc
      | R.RCPOLYFNM {loc,...} => loc
      | R.RCPOLY {loc,...} => loc
      | R.RCTAPP {loc,...} => loc
      | R.RCSEQ {loc,...} => loc
      | R.RCCAST (_,_,loc) => loc
      | R.RCFFI (_,_,loc) => loc

  fun isSimpleExp rcexp =
      case rcexp of
        R.RCFOREIGNAPPLY _ => false
      | R.RCCALLBACKFN _ => false
      | R.RCTAGOF _ => true
      | R.RCSIZEOF _ => true
      | R.RCINDEXOF _ => true
      | R.RCCONSTANT _ => true
      | R.RCFOREIGNSYMBOL _ => true
      | R.RCVAR _ => true
      | R.RCEXVAR _ => true
      | R.RCPRIMAPPLY _ => false
      | R.RCOPRIMAPPLY _ => false
      | R.RCDATACONSTRUCT _ => false
      | R.RCEXNCONSTRUCT _ => false
      | R.RCEXN_CONSTRUCTOR _ => true (* FIXME check this *)
      | R.RCEXEXN_CONSTRUCTOR _ => true (* FIXME check this *)
      | R.RCAPPM _ => false
      | R.RCMONOLET _ => false
      | R.RCLET _ => false
      | R.RCRECORD _ => false
      | R.RCSELECT _ => false
      | R.RCMODIFY _ => false
      | R.RCRAISE _ => false
      | R.RCHANDLE _ => false
      | R.RCCASE _ => false
      | R.RCEXNCASE _ => false
      | R.RCSWITCH _ => false
      | R.RCFNM _=> false
      | R.RCPOLYFNM _ => false
      | R.RCPOLY _ => false
      | R.RCTAPP _ => false
      | R.RCSEQ _ => false
      | R.RCCAST ((exp,_),_,_) => isSimpleExp exp
      | R.RCFFI _ => false

  val emptyEnv = BoundTypeVarID.Map.empty : T.btvEnv

  fun addBoundTyvars env1 env2 : T.btvEnv =
      BoundTypeVarID.Map.unionWith #2 (env1, env2)

  fun newVar ty =
      let
        val id = VarID.generate ()
      in
        {path = ["$" ^ VarID.toString id], ty = ty, id = id} : R.varInfo
      end

  fun toSimpleExp ({ty, exp}, loc) =
      if isSimpleExp exp
      then (fn x => x, {ty=ty, exp=exp})
      else
        let
          val var = newVar ty
        in
          (fn body => R.RCMONOLET {binds=[(var,exp)], bodyExp=body, loc=loc},
           {ty = ty, exp = R.RCVAR var})
        end

  fun BitCast ({ty, exp}, ty2, loc) =
      {ty = ty2,
       exp = R.RCPRIMAPPLY
               {primOp = {primitive = BuiltinPrimitive.Cast
                                        BuiltinPrimitive.BitCast,
                          ty = T.FUNMty ([ty], ty2)},
                instTyList = nil,
                argExp = exp,
                loc = loc}}

  fun tupleLabels l =
      let
        fun loop n nil = nil
          | loop n (h::t) = (Int.toString n, h) :: loop (n+1) t
      in
        loop 1 l
      end

  fun explodeRecord ({ty as T.RECORDty tys, exp}, loc) =
      map (fn (label, fieldTy) =>
              {ty = fieldTy,
               exp = R.RCSELECT {indexExp = R.RCINDEXOF (label, ty, loc),
                                 label = label,
                                 exp = exp,
                                 expTy = ty,
                                 resultTy = fieldTy,
                                 loc = loc}})
          (LabelEnv.listItemsi tys)
    | explodeRecord _ = raise Bug.Bug "explodeRecord"

  fun LabelEnvFromList list =
      List.foldl (fn ((key, item), m) => LabelEnv.insert (m, key, item)) LabelEnv.empty list
  fun implodeRecord (fields, loc) =
      let
        val tys = LabelEnvFromList (map (fn (l,{ty,exp}) => (l,ty)) fields)
        val exps =LabelEnvFromList (map (fn (l,{ty,exp}) => (l,exp)) fields)
        val ty = T.RECORDty tys
      in
        {ty = ty,
         exp = R.RCRECORD {fields = exps, recordTy = ty, loc = loc}}
      end

  fun varExp loc (var as {ty, ...}) =
      {ty = ty, exp = R.RCVAR var}

  fun composeArg (nil, loc) =
      {ty = BT.unitTy,
       exp = R.RCCONSTANT {const=A.UNITCONST loc, ty=BT.unitTy,
                           loc=loc}}
    | composeArg ([exp], loc) = exp
    | composeArg (exps, loc) = implodeRecord (tupleLabels exps, loc)

  fun decomposeArg (nil, loc) = (newVar BT.unitTy, nil)
    | decomposeArg ([ty], loc) =
      let val var = newVar ty
      in (var, [varExp loc var])
      end
    | decomposeArg (tys, loc) =
      let val var = newVar (T.RECORDty (LabelEnvFromList (tupleLabels tys)))
      in (var, explodeRecord (varExp loc var, loc))
      end

  fun hasFunTy ffity =
      case ffity of
        TC.FFIBASETY _ => false
      | TC.FFIFUNTY _ => true
      | TC.FFIRECORDTY (fields, loc) =>
        List.exists (fn (k,v) => hasFunTy v) fields

  fun hasSortedField fields =
      map #1 fields = 
      SEnv.listKeys 
        (List.foldl (fn ((key, item), m) => SEnv.insert (m, key, item)) SEnv.empty fields)

  fun zipApp nil nil = nil
    | zipApp (f::ft) (h::t) = f h :: zipApp ft t
    | zipApp _ _ = raise Bug.Bug "zipApp"

  fun stubImport env ffity =
      case ffity of
        TC.FFIBASETY (ty, loc) => (ty, fn x => x)
      | TC.FFIRECORDTY (fields, loc) =>
        raise Bug.Bug "stubImport: FFIRECORDTY"
      | TC.FFIFUNTY (attributes, argTys, varTys, retTys, loc) =>
        let
          val attributes = getOpt (attributes, FFIAttributes.defaultFFIAttributes)
          val (argTys1, exportFns1) =
              ListPair.unzip (map (stubExport env) argTys)
          val (argTys2, exportFns2) =
              case varTys of
                NONE => (nil, nil)
              | SOME varTys => ListPair.unzip (map (stubExport env) varTys)
          val (argVar, argExps) = decomposeArg (argTys1 @ argTys2, loc)
          val ffiArgExps = zipApp (exportFns1 @ exportFns2) argExps
          val (ffiArgTyList, ffiVarArgTyList) =
              case varTys of
                NONE => (map #ty ffiArgExps, NONE)
              | SOME _ => split (map #ty ffiArgExps) (length exportFns1)
          val (ffiRetTys, importFns) =
              ListPair.unzip (map (stubImport env) retTys)
          val ffiRetTy =
              case ffiRetTys of
                nil => NONE
              | [ty] => SOME ty
              | _ => raise Bug.Bug "stubImport: FFIFUNTY"
          val (ffiRetVar, ffiRetExps) = decomposeArg (ffiRetTys, loc)
          val retExps = zipApp importFns ffiRetExps
          val retExp = composeArg (retExps, loc)
        in
          (T.BACKENDty (T.FOREIGNFUNPTRty {tyvars = env,
                                           argTyList = ffiArgTyList,
                                           varArgTyList = ffiVarArgTyList,
                                           resultTy = ffiRetTy,
                                           attributes = attributes}),
           fn funExp =>
              {ty = T.FUNMty ([#ty argVar], #ty retExp),
               exp = R.RCFNM
                       {loc = loc,
                        argVarList = [argVar],
                        bodyTy = #ty retExp,
                        bodyExp =
                          R.RCMONOLET
                            {loc = loc,
                             binds =
                               [(ffiRetVar,
                                 R.RCFOREIGNAPPLY
                                   {loc = loc,
                                    funExp = #exp funExp,
                                    argExpList = map #exp ffiArgExps,
                                    attributes = attributes,
                                    resultTy = ffiRetTy})],
                               bodyExp = #exp retExp}}})
        end

  and stubExport env ffity =
      case ffity of
        TC.FFIBASETY (ty, loc) => (ty, fn x => x)
      | TC.FFIRECORDTY (fields, loc) =>
        let
          val stubs = map (fn (k,ty) => (k, stubExport env ty)) fields
          val retTys = map (fn (k,(ty,_)) => (k,ty)) stubs
          fun stubFields exps =
              tupleLabels (zipApp (map (fn (_,(_,f)) => f) stubs) exps)
        in
          (T.RECORDty (LabelEnvFromList retTys),
           if hasSortedField fields andalso not (hasFunTy ffity)
           then fn x => x
           else fn exp =>
                   implodeRecord (stubFields (explodeRecord (exp, loc)), loc))
        end
      | TC.FFIFUNTY (attributes, argTys, NONE, retTys, loc) =>
        let
          val attributes = getOpt (attributes, FFIAttributes.defaultFFIAttributes)
          val (argTys, importFns) = ListPair.unzip (map (stubImport env) argTys)
          val ffiArgVars = map newVar argTys
          val argExps = zipApp importFns (map (varExp loc) ffiArgVars)
          val argExp = composeArg (argExps, loc)
          val ffiArgTyList = map #ty ffiArgVars
          val (retTys, exportFns) = ListPair.unzip (map (stubExport env) retTys)
          val (retVar, retExps) = decomposeArg (retTys, loc)
          val ffiRetExps = zipApp exportFns retExps
          val ffiRetExp = composeArg (ffiRetExps, loc)
          val ffiRetTy =
              case ffiRetExps of
                nil => NONE
              | [{ty,...}] => SOME ty
              | _ => raise Bug.Bug "stubExport: FFIFUNTY"
        in
          (T.FUNMty ([#ty argExp], #ty retVar),
           fn funExp =>
              {ty = T.BACKENDty (T.FOREIGNFUNPTRty
                                   {tyvars = env,
                                    argTyList = ffiArgTyList,
                                    varArgTyList = NONE,
                                    resultTy = ffiRetTy,
                                    attributes = attributes}),
               exp = R.RCCALLBACKFN
                       {loc = loc,
                        attributes = attributes,
                        resultTy = ffiRetTy,
                        argVarList = ffiArgVars,
                        bodyExp =
                          R.RCMONOLET
                            {loc = loc,
                             binds =
                               [(retVar,
                                 R.RCAPPM
                                   {loc = loc,
                                    funExp = #exp funExp,
                                    funTy = #ty funExp,
                                    argExpList = [#exp argExp]})],
                             bodyExp = #exp ffiRetExp}}})
        end
      | TC.FFIFUNTY (attributes, argTys, SOME _, retTys, loc) =>
        raise Bug.Bug "stubExport: FFIFUNTY"

  fun infectPoly (ty, exp) =
      case TypesBasics.derefTy ty of
        T.POLYty {boundtvars, body} =>
        (
          case exp of
            R.RCFNM {argVarList, bodyTy, bodyExp, loc} =>
            R.RCPOLYFNM {btvEnv = boundtvars,
                          argVarList = argVarList,
                          bodyTy = bodyTy,
                          bodyExp = bodyExp,
                          loc = loc}
          | _ =>
            R.RCPOLY {btvEnv = boundtvars,
                       expTyWithoutTAbs = body,
                       exp = exp,
                       loc = getLocExp exp}
        )
      | _ => exp

  and compileFFIexp env (rcffiexp, resultTy, loc) =
      case rcffiexp of
        R.RCFFIIMPORT {funExp = R.RCFFIFUN ptrExp, ffiTy} =>
        let
          val ptrExp = {ty = BT.codeptrTy, exp = compileExp env ptrExp}
          val (letFn, ptrExp) = toSimpleExp (ptrExp, loc)
          val (funptrTy, importExpFn) = stubImport env ffiTy
          val ptrExp = BitCast (ptrExp, funptrTy, loc)
        in
          letFn (infectPoly (resultTy, #exp (importExpFn ptrExp)))
        end
      | R.RCFFIIMPORT {funExp = R.RCFFIEXTERN name, ffiTy} =>
        let
          val (funptrTy, importExpFn) = stubImport env ffiTy
          val symbolExp =
              {ty = funptrTy,
               exp = R.RCFOREIGNSYMBOL {name=name, ty=funptrTy, loc=loc}}
        in
          infectPoly (resultTy, #exp (importExpFn symbolExp))
        end

  and compileExp env rcexp =
      case rcexp of
        R.RCFOREIGNAPPLY {funExp, attributes, resultTy, argExpList, loc} =>
        R.RCFOREIGNAPPLY
          {funExp = compileExp env funExp,
           argExpList = map (compileExp env) argExpList,
           attributes = attributes,
           resultTy = resultTy,
           loc = loc}
      | R.RCCALLBACKFN {argVarList, bodyExp, attributes, resultTy, loc} =>
        R.RCCALLBACKFN
          {argVarList = argVarList,
           bodyExp = compileExp env bodyExp,
           attributes = attributes,
           resultTy = resultTy,
           loc = loc}
      | R.RCTAGOF (ty, loc) =>
        R.RCTAGOF (ty, loc)
      | R.RCSIZEOF (ty, loc) =>
        R.RCSIZEOF (ty, loc)
      | R.RCINDEXOF (label, recordTy, loc) =>
        R.RCINDEXOF (label, recordTy, loc)
      | R.RCCONSTANT {const, ty, loc} =>
        R.RCCONSTANT {const=const, ty=ty, loc=loc}
      | R.RCFOREIGNSYMBOL symbol =>
        R.RCFOREIGNSYMBOL symbol
      | R.RCVAR varInfo =>
        R.RCVAR varInfo
      | R.RCEXVAR exVarInfo =>
        R.RCEXVAR exVarInfo
      | R.RCPRIMAPPLY {primOp, instTyList, argExp, loc} =>
        R.RCPRIMAPPLY
          {primOp = primOp,
           instTyList = instTyList,
           argExp = compileExp env argExp,
           loc = loc}
      | R.RCOPRIMAPPLY {oprimOp, instTyList, argExp, loc} =>
        R.RCOPRIMAPPLY
          {oprimOp = oprimOp,
           instTyList = instTyList,
           argExp = compileExp env argExp,
           loc = loc}
      | R.RCDATACONSTRUCT {con, instTyList, argExpOpt, argTyOpt, loc} =>
        R.RCDATACONSTRUCT
          {con = con,
           instTyList = instTyList,
           argExpOpt = Option.map (compileExp env) argExpOpt,
           argTyOpt = argTyOpt,
           loc = loc}
      | R.RCEXNCONSTRUCT {exn, instTyList, argExpOpt, loc} =>
        R.RCEXNCONSTRUCT
          {exn = exn,
           instTyList = instTyList,
           argExpOpt = Option.map (compileExp env) argExpOpt,
           loc = loc}
      | R.RCEXN_CONSTRUCTOR {exnInfo, loc} => (* FIXME chck this *)
        R.RCEXN_CONSTRUCTOR {exnInfo=exnInfo, loc=loc} 
      | R.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} => (* FIXME chck this *)
        R.RCEXEXN_CONSTRUCTOR {exExnInfo=exExnInfo, loc=loc} 
      | R.RCAPPM {funExp, funTy, argExpList, loc} =>
        R.RCAPPM
          {funExp = compileExp env funExp,
           funTy = funTy,
           argExpList = map (compileExp env) argExpList,
           loc = loc}
      | R.RCMONOLET {binds, bodyExp, loc} =>
        R.RCMONOLET
          {binds = map (fn (v,e) => (v, compileExp env e)) binds,
           bodyExp = compileExp env bodyExp,
           loc = loc}
      | R.RCLET {decls, body, tys, loc} =>
        R.RCLET {decls = map compileDecl decls,
                 body = map (compileExp env) body,
                 tys = tys,
                 loc = loc}
      | R.RCRECORD {fields, recordTy, loc} =>
        R.RCRECORD
          {fields = LabelEnv.map (compileExp env) fields,
           recordTy = recordTy,
           loc = loc}
      | R.RCSELECT {indexExp, label, exp, expTy, resultTy, loc} =>
        R.RCSELECT
          {indexExp = compileExp env indexExp,
           label = label,
           exp = compileExp env exp,
           expTy = expTy,
           resultTy = resultTy,
           loc = loc}
      | R.RCMODIFY {indexExp, label, recordExp, recordTy, elementExp,
                    elementTy, loc} =>
        R.RCMODIFY
          {indexExp = compileExp env indexExp,
           label = label,
           recordExp = compileExp env recordExp,
           recordTy = recordTy,
           elementExp = compileExp env elementExp,
           elementTy = elementTy,
           loc = loc}
      | R.RCRAISE {exp, ty, loc} =>
        R.RCRAISE {exp = compileExp env exp, ty = ty, loc = loc}
      | R.RCHANDLE {exp, exnVar, handler, resultTy, loc} =>
        R.RCHANDLE
          {exp = compileExp env exp,
           exnVar = exnVar,
           handler = compileExp env handler,
           resultTy = resultTy,
           loc = loc}
      | R.RCCASE {exp, expTy, ruleList, defaultExp, resultTy, loc} =>
        R.RCCASE
          {exp = compileExp env exp,
           expTy = expTy,
           ruleList = map (fn (c,v,e) => (c, v, compileExp env e)) ruleList,
           defaultExp = compileExp env defaultExp,
           resultTy = resultTy,
           loc = loc}
      | R.RCEXNCASE {exp, expTy, ruleList, defaultExp, resultTy, loc} =>
        R.RCEXNCASE
          {exp = compileExp env exp,
           expTy = expTy,
           ruleList = map (fn (c,v,e) => (c, v, compileExp env e)) ruleList,
           defaultExp = compileExp env defaultExp,
           resultTy = resultTy,
           loc = loc}
      | R.RCSWITCH {switchExp, expTy, branches, defaultExp, resultTy, loc} =>
        R.RCSWITCH
          {switchExp = compileExp env switchExp,
           expTy = expTy,
           branches = map (fn (c,e) => (c, compileExp env e)) branches,
           defaultExp = compileExp env defaultExp,
           resultTy = resultTy,
           loc = loc}
      | R.RCFNM {argVarList, bodyTy, bodyExp, loc} =>
        R.RCFNM
          {argVarList = argVarList,
           bodyTy = bodyTy,
           bodyExp = compileExp env bodyExp,
           loc = loc}
      | R.RCPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} =>
        R.RCPOLYFNM
          {btvEnv = btvEnv,
           argVarList = argVarList,
           bodyTy = bodyTy,
           bodyExp = compileExp (addBoundTyvars env btvEnv) bodyExp,
           loc = loc}
      | R.RCPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        R.RCPOLY
          {btvEnv = btvEnv,
           expTyWithoutTAbs = expTyWithoutTAbs,
           exp = compileExp (addBoundTyvars env btvEnv) exp,
           loc = loc}
      | R.RCTAPP {exp, expTy, instTyList, loc} =>
        R.RCTAPP
          {exp = compileExp env exp,
           expTy = expTy,
           instTyList = instTyList,
           loc = loc}
      | R.RCSEQ {expList, expTyList, loc} =>
        R.RCSEQ
          {expList = map (compileExp env) expList,
           expTyList = expTyList,
           loc = loc}
      | R.RCCAST ((rcexp, expTy), ty, loc) =>
        R.RCCAST ((compileExp env rcexp, expTy), ty, loc)
      | R.RCFFI (exp, ty, loc) =>
        compileFFIexp env (exp, ty, loc)

  and compileDecl rcdecl =
      case rcdecl of
        R.RCVAL (bindList, loc) =>
        R.RCVAL (map (fn (v,e) => (v, compileExp emptyEnv e)) bindList, loc)
      | R.RCVALREC (bindList, loc) =>
        R.RCVALREC (map (fn {var, expTy, exp} =>
                            {var=var, expTy=expTy, exp=compileExp emptyEnv exp})
                        bindList,
                    loc)
      | R.RCVALPOLYREC (btvEnv, bindList, loc) =>
        R.RCVALPOLYREC (btvEnv,
                        map (fn {var, expTy, exp} =>
                                {var=var,
                                 expTy=expTy,
                                 exp=compileExp btvEnv exp})
                            bindList,
                        loc)
      | R.RCEXD (binds, loc) =>
        R.RCEXD (binds, loc)
      | R.RCEXNTAGD (bind, loc) => (* FIXME check this *)
        R.RCEXNTAGD (bind, loc)
      | R.RCEXPORTVAR varInfo =>
        R.RCEXPORTVAR varInfo 
      | R.RCEXPORTEXN exnInfo =>
        R.RCEXPORTEXN exnInfo
      | R.RCEXTERNVAR exVarInfo =>
        R.RCEXTERNVAR exVarInfo
      | R.RCEXTERNEXN exExnInfo =>
        R.RCEXTERNEXN exExnInfo
      | R.RCBUILTINEXN exExnInfo =>
        R.RCBUILTINEXN exExnInfo

  fun compile decls =
      map compileDecl decls

end
