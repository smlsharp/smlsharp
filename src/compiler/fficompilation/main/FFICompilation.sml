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
  structure BV = BuiltinEnv

  fun getLocExp rcexp =
      case rcexp of
        R.RCFOREIGNAPPLY {loc,...} => loc
      | R.RCEXPORTCALLBACK {loc,...} => loc
      | R.RCTAGOF (_,loc) => loc
      | R.RCSIZEOF (_,loc) => loc
      | R.RCINDEXOF (_,_,loc) => loc
      | R.RCCONSTANT {loc,...} => loc
      | R.RCGLOBALSYMBOL {loc,...} => loc
      | R.RCVAR (_,loc) => loc
      | R.RCEXVAR (_, loc) => loc
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
      | R.RCSQL (_,_,loc) => loc
      | R.RCFFI (_,_,loc) => loc

  fun isSimpleExp rcexp =
      case rcexp of
        R.RCFOREIGNAPPLY _ => false
      | R.RCEXPORTCALLBACK _ => false
      | R.RCTAGOF _ => true
      | R.RCSIZEOF _ => true
      | R.RCINDEXOF _ => true
      | R.RCCONSTANT _ => true
      | R.RCGLOBALSYMBOL _ => true
      | R.RCVAR (_,loc) => true
      | R.RCEXVAR (_, loc) => true
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
      | R.RCCAST (exp,_,_) => isSimpleExp exp
      | R.RCSQL _ => false
      | R.RCFFI _ => false

  fun newVar ty =
      let
        val id = VarID.generate ()
      in
        {path = ["$" ^ VarID.toString id], ty = ty, id = id} : R.varInfo
      end

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
    | explodeRecord _ = raise Control.Bug "explodeRecord"

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
      {ty = ty, exp = R.RCVAR (var, loc)}

  fun composeArg (nil, loc) =
      {ty = BV.UNITty,
       exp = R.RCCONSTANT {const=A.UNITCONST loc, ty=BV.UNITty,
                           loc=loc}}
    | composeArg ([exp], loc) = exp
    | composeArg (exps, loc) = implodeRecord (tupleLabels exps, loc)

  fun decomposeArg (nil, loc) = (newVar BV.UNITty, nil)
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
      map #1 fields = SEnv.listKeys (SEnv.fromList fields)

  fun zipApp nil nil = nil
    | zipApp (f::ft) (h::t) = f h :: zipApp ft t
    | zipApp _ _ = raise Control.Bug "zipApp"

  fun stubImport ffity =
      case ffity of
        TC.FFIBASETY (ty, loc) => (ty, fn x => x)
      | TC.FFIRECORDTY (fields, loc) =>
        raise Control.Bug "stubImport: FFIRECORDTY"
      | TC.FFIFUNTY (attributes, argTys, retTys, loc) =>
        let
          val attributes = getOpt (attributes, Absyn.defaultFFIAttributes)
          val (argTys, exportFns) = ListPair.unzip (map stubExport argTys)
          val (ffiRetTys, importFns) = ListPair.unzip (map stubImport retTys)
          val (argVar, argExps) = decomposeArg (argTys, loc)
          val ffiArgExps = zipApp exportFns argExps
                        handle e => (print "hoge4\n"; raise e)
          val (ffiRetVar, ffiRetExps) = decomposeArg (ffiRetTys, loc)
          val retExps = zipApp importFns ffiRetExps
                        handle e => (print "hoge3\n"; raise e)
          val retExp = composeArg (retExps, loc)
        in
          (BV.PTRty,
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
                                    foreignFunTy =
                                      {argTyList = map #ty ffiArgExps,
                                       resultTy = #ty ffiRetVar,
                                       attributes = attributes}})],
                               bodyExp = #exp retExp}}})
        end

  and stubExport ffity =
      case ffity of
        TC.FFIBASETY (ty, loc) => (ty, fn x => x)
      | TC.FFIRECORDTY (fields, loc) =>
        let
          val stubs = map (fn (k,ty) => (k, stubExport ty)) fields
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
      | TC.FFIFUNTY (attributes, argTys, retTys, loc) =>
        let
          val attributes = getOpt (attributes, Absyn.defaultFFIAttributes)
          val (ffiArgTys, importFns) = ListPair.unzip (map stubImport argTys)
          val (retTys, exportFns) = ListPair.unzip (map stubExport retTys)
          val ffiArgVars = map newVar ffiArgTys
          val argExps = zipApp importFns (map (varExp loc) ffiArgVars)
                        handle e => (print "hoge1\n"; raise e)
          val argExp = composeArg (argExps, loc)
          val (retVar, retExps) = decomposeArg (retTys, loc)
          val ffiRetExps = zipApp exportFns retExps
              handle e => (print "hoge2\n"; raise e)
          val ffiRetExp = composeArg (ffiRetExps, loc)
        in
          (T.FUNMty ([#ty argExp], #ty retVar),
           fn funExp =>
              {ty = BV.PTRty,
               exp = R.RCEXPORTCALLBACK
                       {loc = loc,
                        foreignFunTy =
                          {argTyList = map #ty ffiArgVars,
                           resultTy = #ty ffiRetExp,
                           attributes = attributes},
                        funExp =
                          R.RCFNM
                            {loc = loc,
                             argVarList = ffiArgVars,
                             bodyTy = #ty ffiRetExp,
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
                                  bodyExp = #exp ffiRetExp}}}})
        end

  fun infectPoly (ty, exp) =
      case TypesUtils.derefTy ty of
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

  fun compileImport (ptrExp, ffiTy, resultTy, loc) =
      let
        val exp = compileExp ptrExp
        val var = newVar BV.PTRty
        val (_, importFn) = stubImport ffiTy
        fun stub exp = #exp (importFn {ty = BV.PTRty, exp = exp})
      in
        if isSimpleExp exp
        then infectPoly (resultTy, stub exp)
        else R.RCMONOLET
               {binds = [(var, exp)],
                bodyExp = infectPoly (resultTy, stub (R.RCVAR (var, loc))),
                loc = loc}
      end

  and compileFFIexp (rcffiexp, resultTy, loc) =
      case rcffiexp of
        R.RCFFIIMPORT {ptrExp, ffiTy} =>
        compileImport (ptrExp, ffiTy, resultTy, loc)

  and compileExp rcexp =
      case rcexp of
        R.RCFOREIGNAPPLY {funExp, foreignFunTy, argExpList, loc} =>
        R.RCFOREIGNAPPLY
          {funExp = compileExp funExp,
           foreignFunTy = foreignFunTy,
           argExpList = map compileExp argExpList,
           loc = loc}
      | R.RCEXPORTCALLBACK {funExp, foreignFunTy, loc} =>
        R.RCEXPORTCALLBACK
          {funExp = compileExp funExp,
           foreignFunTy = foreignFunTy,
           loc = loc}
      | R.RCTAGOF (ty, loc) =>
        R.RCTAGOF (ty, loc)
      | R.RCSIZEOF (ty, loc) =>
        R.RCSIZEOF (ty, loc)
      | R.RCINDEXOF (label, recordTy, loc) =>
        R.RCINDEXOF (label, recordTy, loc)
      | R.RCCONSTANT {const, ty, loc} =>
        R.RCCONSTANT {const=const, ty=ty, loc=loc}
      | R.RCGLOBALSYMBOL symbol =>
        R.RCGLOBALSYMBOL symbol
      | R.RCVAR (varInfo, loc) =>
        R.RCVAR (varInfo, loc)
      | R.RCEXVAR (exVarInfo, loc) =>
        R.RCEXVAR (exVarInfo, loc)
      | R.RCPRIMAPPLY {primOp, instTyList, argExp, loc} =>
        R.RCPRIMAPPLY
          {primOp = primOp,
           instTyList = instTyList,
           argExp = compileExp argExp,
           loc = loc}
      | R.RCOPRIMAPPLY {oprimOp, instTyList, argExp, loc} =>
        R.RCOPRIMAPPLY
          {oprimOp = oprimOp,
           instTyList = instTyList,
           argExp = compileExp argExp,
           loc = loc}
      | R.RCDATACONSTRUCT {con, instTyList, argExpOpt, loc} =>
        R.RCDATACONSTRUCT
          {con = con,
           instTyList = instTyList,
           argExpOpt = Option.map compileExp argExpOpt,
           loc = loc}
      | R.RCEXNCONSTRUCT {exn, instTyList, argExpOpt, loc} =>
        R.RCEXNCONSTRUCT
          {exn = exn,
           instTyList = instTyList,
           argExpOpt = Option.map compileExp argExpOpt,
           loc = loc}
      | R.RCEXN_CONSTRUCTOR {exnInfo, loc} => (* FIXME chck this *)
        R.RCEXN_CONSTRUCTOR {exnInfo=exnInfo, loc=loc} 
      | R.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} => (* FIXME chck this *)
        R.RCEXEXN_CONSTRUCTOR {exExnInfo=exExnInfo, loc=loc} 
      | R.RCAPPM {funExp, funTy, argExpList, loc} =>
        R.RCAPPM
          {funExp = compileExp funExp,
           funTy = funTy,
           argExpList = map compileExp argExpList,
           loc = loc}
      | R.RCMONOLET {binds, bodyExp, loc} =>
        R.RCMONOLET
          {binds = map (fn (v,e) => (v, compileExp e)) binds,
           bodyExp = compileExp bodyExp,
           loc = loc}
      | R.RCLET {decls, body, tys, loc} =>
        R.RCLET {decls = map compileDecl decls,
                 body = map compileExp body,
                 tys = tys,
                 loc = loc}
      | R.RCRECORD {fields, recordTy, loc} =>
        R.RCRECORD
          {fields = LabelEnv.map compileExp fields,
           recordTy = recordTy,
           loc = loc}
      | R.RCSELECT {indexExp, label, exp, expTy, resultTy, loc} =>
        R.RCSELECT
          {indexExp = compileExp indexExp,
           label = label,
           exp = compileExp exp,
           expTy = expTy,
           resultTy = resultTy,
           loc = loc}
      | R.RCMODIFY {indexExp, label, recordExp, recordTy, elementExp,
                    elementTy, loc} =>
        R.RCMODIFY
          {indexExp = compileExp indexExp,
           label = label,
           recordExp = compileExp recordExp,
           recordTy = recordTy,
           elementExp = compileExp elementExp,
           elementTy = elementTy,
           loc = loc}
      | R.RCRAISE {exp, ty, loc} =>
        R.RCRAISE {exp = compileExp exp, ty = ty, loc = loc}
      | R.RCHANDLE {exp, exnVar, handler, loc} =>
        R.RCHANDLE
          {exp = compileExp exp,
           exnVar = exnVar,
           handler = compileExp handler,
           loc = loc}
      | R.RCCASE {exp, expTy, ruleList, defaultExp, loc} =>
        R.RCCASE
          {exp = compileExp exp,
           expTy = expTy,
           ruleList = map (fn (c,v,e) => (c, v, compileExp e)) ruleList,
           defaultExp = compileExp defaultExp,
           loc = loc}
      | R.RCEXNCASE {exp, expTy, ruleList, defaultExp, loc} =>
        R.RCEXNCASE
          {exp = compileExp exp,
           expTy = expTy,
           ruleList = map (fn (c,v,e) => (c, v, compileExp e)) ruleList,
           defaultExp = compileExp defaultExp,
           loc = loc}
      | R.RCSWITCH {switchExp, expTy, branches, defaultExp, loc} =>
        R.RCSWITCH
          {switchExp = compileExp switchExp,
           expTy = expTy,
           branches = map (fn (c,e) => (c, compileExp e)) branches,
           defaultExp = compileExp defaultExp,
           loc = loc}
      | R.RCFNM {argVarList, bodyTy, bodyExp, loc} =>
        R.RCFNM
          {argVarList = argVarList,
           bodyTy = bodyTy,
           bodyExp = compileExp bodyExp,
           loc = loc}
      | R.RCPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} =>
        R.RCPOLYFNM
          {btvEnv = btvEnv,
           argVarList = argVarList,
           bodyTy = bodyTy,
           bodyExp = compileExp bodyExp,
           loc = loc}
      | R.RCPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        R.RCPOLY
          {btvEnv = btvEnv,
           expTyWithoutTAbs = expTyWithoutTAbs,
           exp = compileExp exp,
           loc = loc}
      | R.RCTAPP {exp, expTy, instTyList, loc} =>
        R.RCTAPP
          {exp = compileExp exp,
           expTy = expTy,
           instTyList = instTyList,
           loc = loc}
      | R.RCSEQ {expList, expTyList, loc} =>
        R.RCSEQ
          {expList = map compileExp expList,
           expTyList = expTyList,
           loc = loc}
      | R.RCCAST (rcexp, ty, loc) =>
        R.RCCAST (compileExp rcexp, ty, loc)
      | R.RCSQL exp =>
        raise Control.Bug "FFICompilation.compileExp: RCSQL"
      | R.RCFFI (exp, ty, loc) =>
        compileFFIexp (exp, ty, loc)

  and compileDecl rcdecl =
      case rcdecl of
        R.RCVAL (bindList, loc) =>
        R.RCVAL (map (fn (v,e) => (v, compileExp e)) bindList, loc)
      | R.RCVALREC (bindList, loc) =>
        R.RCVALREC (map (fn {var, expTy, exp} =>
                            {var=var, expTy=expTy, exp=compileExp exp})
                        bindList,
                    loc)
      | R.RCVALPOLYREC (btvEnv, bindList, loc) =>
        R.RCVALPOLYREC (btvEnv,
                        map (fn {var, expTy, exp} =>
                                {var=var, expTy=expTy, exp=compileExp exp})
                            bindList,
                        loc)
      | R.RCEXD (binds, loc) =>
        R.RCEXD (binds, loc)
      | R.RCEXNTAGD (bind, loc) => (* FIXME check this *)
        R.RCEXNTAGD (bind, loc)
      | R.RCEXPORTVAR (varInfo, loc) =>
        R.RCEXPORTVAR (varInfo, loc)
      | R.RCEXPORTEXN (exnInfo, loc) =>
        R.RCEXPORTEXN (exnInfo, loc)
      | R.RCEXTERNVAR (exVarInfo, loc) =>
        R.RCEXTERNVAR (exVarInfo, loc)
      | R.RCEXTERNEXN (exExnInfo, loc) =>
        R.RCEXTERNEXN (exExnInfo, loc)

  fun compile decls =
      map compileDecl decls

end
