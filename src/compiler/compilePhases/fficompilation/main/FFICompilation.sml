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

  structure R = RecordCalc
  structure TC = TypedCalc
  structure A = AbsynConst
  structure T = Types
  structure TB = TypesBasics
  structure BT = BuiltinTypes
  structure BP = BuiltinPrimitive
  structure U = UserLevelPrimitive
  structure RyU = ReifyUtils

  fun isSimpleExp rcexp =
      case rcexp of
        R.RCFOREIGNAPPLY _ => false
      | R.RCCALLBACKFN _ => false
      | R.RCTAGOF _ => true
      | R.RCSIZEOF _ => true
      | R.RCTYPEOF _ => true
      | R.RCREIFYTY _ => true
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
      | R.RCFOREACH _ => false
      | R.RCFOREACHDATA _ => false
      | R.RCCAST ((exp,_),_,_) => isSimpleExp exp
      | R.RCFFI _ => false
      | R.RCJOIN _ => false
      | R.RCJSON _ => false

  val emptyEnv = BoundTypeVarID.Map.empty : T.btvEnv

  fun addBoundTyvars env1 env2 : T.btvEnv =
      BoundTypeVarID.Map.unionWith #2 (env1, env2)

  fun toSimpleExp loc {ty, exp} =
      if isSimpleExp exp
      then (fn x => x, {ty=ty, exp=exp})
      else
        let
          val var = RyU.newVar ty
        in
          (fn body => R.RCMONOLET {binds=[(var,exp)], bodyExp=body, loc=loc},
           {ty = ty, exp = R.RCVAR var})
        end

  val --> = RyU.-->
  val **  = RyU.**
  infixr 4 -->
  infix 5 **

  fun BitCast loc ({ty, exp}, ty2) =
      {ty = ty2,
       exp = R.RCPRIMAPPLY
               {primOp = {primitive = BP.Cast BP.BitCast,
                          ty = ty --> ty2},
                instTyList = nil,
                argExp = exp,
                loc = loc}}

  fun explodeRecord loc {ty as T.RECORDty tys, exp} =
      map (fn (label, fieldTy) =>
              {ty = fieldTy,
               exp = R.RCSELECT {indexExp = R.RCINDEXOF (label, ty, loc),
                                 label = label,
                                 exp = exp,
                                 expTy = ty,
                                 resultTy = fieldTy,
                                 loc = loc}})
          (RecordLabel.Map.listItemsi tys)
    | explodeRecord _ _ = raise Bug.Bug "explodeRecord"

  fun labelEnvFromList list =
      List.foldl (fn ((key, item), m) => RecordLabel.Map.insert (m, key, item)) RecordLabel.Map.empty list

  fun implodeRecord loc fields =
      let
        val tys = labelEnvFromList (map (fn (l,{ty,exp}) => (l,ty)) fields)
        val exps =labelEnvFromList (map (fn (l,{ty,exp}) => (l,exp)) fields)
        val ty = T.RECORDty tys
      in
        {ty = ty,
         exp = R.RCRECORD {fields = exps, recordTy = ty, loc = loc}}
      end

  fun composeArg loc nil =
      {ty = BT.unitTy,
       exp = R.RCCONSTANT {const=A.UNITCONST loc, ty=BT.unitTy, loc=loc}}
    | composeArg loc [exp] = exp
    | composeArg loc exps = implodeRecord loc (RecordLabel.tupleList exps)

  fun decomposeArg loc nil = (RyU.newVar BT.unitTy, nil)
    | decomposeArg loc [ty] =
      let val var = RyU.newVar ty
      in (var, [RyU.Var var])
      end
    | decomposeArg loc tys =
      let val var = RyU.newVar (T.RECORDty (RecordLabel.tupleMap tys))
      in (var, explodeRecord loc (RyU.Var var))
      end

  fun hasFunTy ffity =
      case ffity of
        TC.FFIBASETY _ => false
      | TC.FFIFUNTY _ => true
      | TC.FFIRECORDTY (fields, loc) =>
        List.exists (fn (k,v) => hasFunTy v) fields

  fun hasSortedField nil = true
    | hasSortedField [_] = true
    | hasSortedField ((l1,_)::(t as (l2,_)::_)) =
      RecordLabel.compare (l1, l2) = LESS andalso hasSortedField t

  fun zipApp nil nil = nil
    | zipApp (f::ft) (h::t) = f h :: zipApp ft t
    | zipApp _ _ = raise Bug.Bug "zipApp"

  fun stubImport multiArg env ffity =
      case ffity of
        TC.FFIBASETY (ty, loc) => (ty, fn x => x)
      | TC.FFIRECORDTY (fields, loc) =>
        raise Bug.Bug "stubImport: FFIRECORDTY"
      | TC.FFIFUNTY (attributes, argTys, varTys, retTys, loc) =>
        let
          val attributes =
              getOpt (attributes, FFIAttributes.defaultFFIAttributes)
          val (argTys1, exportFns1) =
              ListPair.unzip (map (stubExport env) argTys)
          val (argTys2, exportFns2) =
              case varTys of
                NONE => (nil, nil)
              | SOME varTys => ListPair.unzip (map (stubExport env) varTys)
          val stubArgTys = argTys1 @ argTys2

          (* ToDo: dirty trick *)
          val (argVars, argExps) =
              if multiArg
              then let val vars = map RyU.newVar stubArgTys
                   in (vars, map RyU.Var vars)
                   end
              else let val (argVar, argExps) = decomposeArg loc stubArgTys
                   in ([argVar], argExps)
                   end

          val ffiArgExps = zipApp (exportFns1 @ exportFns2) argExps
          val (ffiArgTyList, ffiVarArgTyList) =
              case varTys of
                NONE => (map #ty ffiArgExps, NONE)
              | SOME _ => ListUtils.split (map #ty ffiArgExps) (length exportFns1)
          val (ffiRetTys, importFns) =
              ListPair.unzip (map (stubImport false env) retTys)
          val ffiRetTy =
              case ffiRetTys of
                nil => NONE
              | [ty] => SOME ty
              | _ => raise Bug.Bug "stubImport: FFIFUNTY"
          val (ffiRetVar, ffiRetExps) = decomposeArg loc ffiRetTys
          val retExps = zipApp importFns ffiRetExps
          val retExp = composeArg loc retExps
        in
          (T.BACKENDty (T.FOREIGNFUNPTRty {tyvars = env,
                                           argTyList = ffiArgTyList,
                                           varArgTyList = ffiVarArgTyList,
                                           resultTy = ffiRetTy,
                                           attributes = attributes}),
           fn funExp =>
              {ty = T.FUNMty (map #ty argVars, #ty retExp),
               exp = R.RCFNM
                       {loc = loc,
                        argVarList = argVars,
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
              RecordLabel.tupleList
                (zipApp (map (fn (_,(_,f)) => f) stubs) exps)
        in
          (T.RECORDty (labelEnvFromList retTys),
           if hasSortedField fields andalso not (hasFunTy ffity)
           then fn x => x
           else fn exp => 
                   implodeRecord loc (stubFields (explodeRecord loc exp))
          )
        end
      | TC.FFIFUNTY (attributes, argTys, NONE, retTys, loc) =>
        let
          val attributes = getOpt (attributes, FFIAttributes.defaultFFIAttributes)
          val (argTys, importFns) =
              ListPair.unzip (map (stubImport false env) argTys)
          val ffiArgVars = map RyU.newVar argTys
          val argExps = zipApp importFns (map RyU.Var ffiArgVars)
          val argExp = composeArg loc argExps
          val ffiArgTyList = map #ty ffiArgVars
          val (retTys, exportFns) = ListPair.unzip (map (stubExport env) retTys)
          val (retVar, retExps) = decomposeArg loc retTys
          val ffiRetExps = zipApp exportFns retExps
          val ffiRetExp = composeArg loc ffiRetExps
          val ffiRetTy =
              case ffiRetExps of
                nil => NONE
              | [{ty,...}] => SOME ty
              | _ => raise Bug.Bug "stubExport: FFIFUNTY"
        in
          (#ty argExp -->  #ty retVar,
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

  fun HandleAndReRaise loc exnCon {exp, ty} =
      let
        val exnVar = RyU.newVar (BT.exnTy)
        val exnExp = R.RCEXNCONSTRUCT 
                       {exn = exnCon,
                        instTyList = nil,
                        argExpOpt = NONE,
                        loc = loc}
        val raiseExp = R.RCRAISE {exp = exnExp, ty = ty, loc=loc}
        val exnCaseExp =
            R.RCEXNCASE
              {exp = R.RCVAR exnVar,
               defaultExp = R.RCRAISE {exp = R.RCVAR exnVar, ty = ty, loc=loc},
               expTy = BT.exnTy, 
               loc = loc,
               ruleList = [(exnCon, NONE, raiseExp)],
               resultTy = ty}
      in
        R.RCHANDLE
          {exp = exp,
           exnVar = exnVar,
           handler = exnCaseExp,
           resultTy = ty,
           loc = loc}
      end

  (* datatype json  *)
  fun JsonTy () = T.CONSTRUCTty {tyCon = U.JSON_json_tyCon (), args = []}

  (* datatype jsonTy  *)
  fun JsonTyTy () = T.CONSTRUCTty {tyCon = U.JSON_jsonTy_tyCon (), args = []}

  fun TypeOf loc ty = 
      {exp = R.RCTYPEOF (ty, loc),
       ty = JsonTyTy()}

  fun JsonToML loc Exp argTy =
      RyU.Apply
        loc
        (RyU.InstVar {exVarInfo = U.JSON_coerceJson_exVarInfo (), instTy = argTy})
        (RyU.Pair loc Exp (TypeOf loc argTy))

  fun infectPoly (ty, exp) =
      case TB.derefTy ty of
        T.POLYty {boundtvars, constraints, body} =>
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
                      loc = R.getLocExp exp}
        )
      | _ => exp

  fun compileFFIexp multiArg loc env (rcffiexp, resultTy) =
      case rcffiexp of
        R.RCFFIIMPORT {funExp = R.RCFFIFUN ptrExp, ffiTy} =>
        let
          val ptrExp = {ty = BT.codeptrTy, exp = compileExp env ptrExp}
          val (letFn, ptrExp) = toSimpleExp loc ptrExp
          val (funptrTy, importExpFn) = stubImport multiArg env ffiTy
          val ptrExp = BitCast loc (ptrExp, funptrTy)
        in
          letFn (infectPoly (resultTy, #exp (importExpFn ptrExp)))
        end
      | R.RCFFIIMPORT {funExp = R.RCFFIEXTERN name, ffiTy} =>
        let
          val (funptrTy, importExpFn) = stubImport multiArg env ffiTy
          val symbolExp =
              {ty = funptrTy,
               exp = R.RCFOREIGNSYMBOL {name=name, ty=funptrTy, loc=loc}}
        in
          infectPoly (resultTy, #exp (importExpFn symbolExp))
        end

  (* _json rcexp as coerceTy *)
  and compileJson loc env (Exp, coerceTy) =
      let
        val instTy = case TB.derefTy (#ty Exp) of 
                       T.CONSTRUCTty {tyCon = {dtyKind = T.DTY, id, ...}, args=[argTy]} =>
                       if id = #id (U.JSON_dyn_tyCon ()) then argTy
                       else raise Bug.Bug "FFICompilation : compileJson"
                     | _ => raise Bug.Bug "FFICompilation : compileJson"
        val JsonExp = 
            RyU.Apply 
              loc
              (RyU.InstVar {exVarInfo = U.JSON_getJson_exVarInfo (), instTy = instTy})
              Exp
       val CheckExp = 
            RyU.ApplyList
              loc
              (RyU.MonoVar (U.JSON_checkTy_exVarInfo ()))
              [JsonExp, TypeOf loc coerceTy]
      in
        case TB.derefTy coerceTy of
          T.CONSTRUCTty {tyCon = {dtyKind = T.DTY, id, ...}, args} =>
          if id = #id (U.JSON_dyn_tyCon ()) then
            let 
              val argTy = case args of [argTy] => argTy 
                                     | _ => raise Bug.Bug "FFICompilation : compileJson"
              val ViewExp = RyU.FunExp loc (fn Exp => JsonToML loc Exp argTy) (JsonTy())
              val MakeCoerceExp = RyU.InstVar {exVarInfo = U.JSON_makeCoerce_exVarInfo (),
                                               instTy = argTy}
            in
              RyU.Seq 
                loc
                [CheckExp,       
                 RyU.ApplyList
                   loc
                   MakeCoerceExp
                   [JsonExp, TypeOf loc argTy, ViewExp]
                ]
            end
          else RyU.Seq loc [CheckExp, JsonToML loc JsonExp coerceTy]
        | _ => RyU.Seq loc [CheckExp, JsonToML loc JsonExp coerceTy]
      end
      handle U.IDNotFound name =>
             raise UserError.UserErrors 
                     [(loc,
                       UserError.Error,
                       FFICompilationError.UserLevelPrimForJsonNotFound name)]
(*
           | JsonTy => 
             raise UserError.UserErrors 
                     [(loc, 
                       UserError.Error, 
                       FFICompilationError.InvalidJSONTy coerceTy)]

*)

  and compileJoinExp loc env {resultTy, args = (arg1, arg2), argTys = (argTy1, argTy2)} =
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
        val NaturalJoin = RyU.MonoVar (U.REIFY_naturalJoin_exInfo ())
        fun ToReifiedTerm instTy = 
            RyU.InstVar {exVarInfo = U.REIFY_toReifiedTerm_exInfo (),
                         instTy = instTy}
        val Arg1 = {exp = compileExp env arg1, ty= argTy1}
        val Arg2 = {exp = compileExp env arg2, ty= argTy2}
        val Term1 = RyU.Apply loc (ToReifiedTerm argTy1) Arg1
        val Term2 = RyU.Apply loc (ToReifiedTerm argTy2) Arg2
        val JoinedTerm = RyU.Apply loc NaturalJoin (RyU.Pair loc Term1 Term2)
        val ReifiedTermToML = 
            RyU.InstVar {exVarInfo = U.REIFY_reifiedTermToML_exInfo (), 
                         instTy = resultTy}
      in
        #exp (RyU.Apply loc ReifiedTermToML JoinedTerm)
      end

  and compileForeach loc env {Data = Data as {ty,...}, Pred, Iterator} =
    let
      val ForeachArray = 
          RyU.InstVar {exVarInfo = U.FOREACH_ForeachArray_exInfo (),
                       instTy = RyU.ArrayElemTy ty}
      in
        #exp (RyU.ApplyList loc ForeachArray [Data, Iterator, Pred])
      end

  and compileForeachData 
        loc env
        {Data = Data as {ty=DataTy,...}, 
         WhereParam = WhereParam as {ty=WhereParamTy, ...},
         Pred, Iterator} =
    let
      val paramFields = RyU.RecordTyFields WhereParamTy
(*
      val paraTy = 
          case List.find (fn (s,ty) => s = "default") paramFields of
            SOME (l,ty) => ty
          | NONE => raise Bug.Bug "compileForeachData: default field not found"
      val sizeTy =
          case List.find (fn (s,ty) => s = "size") paramFields of
            SOME (s, ty) => ty
          | NONE => raise Bug.Bug "compileForeachData: default field not found"
      val {argTy = seqTy, bodyTy=_} = RyU.FunArgBodyTy sizeTy
*)
      val {argTy=seqTy, bodyTy=paraTy} =
          case List.find (fn (s,ty) => s = "initialize") paramFields of
            SOME (s, ty) => RyU.FunArgBodyTy (#bodyTy (RyU.FunArgBodyTy ty))
          | NONE => raise Bug.Bug "compileForeachData: initialize field not found"
      val ForeachData = 
          RyU.InstListVar {exVarInfo = U.FOREACH_ForeachData_exInfo (),
                           instTyList = [seqTy, paraTy]}
      in
        #exp (RyU.ApplyList loc ForeachData [WhereParam, Data, Iterator, Pred])
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
      | R.RCTYPEOF (ty, loc) =>
        R.RCTYPEOF (ty, loc)
      | R.RCREIFYTY (ty, loc) =>
        R.RCREIFYTY (ty, loc)
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
      | R.RCAPPM {funExp = R.RCFFI (exp, ty, loc2), funTy, argExpList, loc} =>
        (* FIXME: dirty trick *)
        let
          exception Fallback
          fun monolet {binds=nil, bodyExp, loc} = bodyExp
            | monolet x = R.RCMONOLET x
          fun explodeTuple (R.RCCONSTANT {const=A.UNITCONST _,...}) = []
            | explodeTuple (x as R.RCRECORD {fields, ...}) =
              if RecordLabel.isTupleMap fields
              then RecordLabel.Map.listItems fields
              else [x]
            | explodeTuple x = [x]
          val argExpList = map (compileExp env) argExpList
        in
          (case (compileFFIexp true loc2 env (exp, ty), argExpList) of
             (R.RCFNM {argVarList, bodyTy, bodyExp, loc=_}, [argExp]) =>
             monolet
               {binds = ListPair.zipEq (argVarList, explodeTuple argExp)
                        handle ListPair.UnequalLengths =>
                               ListPair.zipEq (argVarList, [argExp])
                               handle ListPair.UnequalLengths => raise Fallback,
                bodyExp = bodyExp,
                loc = loc}
           | _ => raise Fallback)
          handle Fallback =>
            case (compileFFIexp false loc2 env (exp, ty), argExpList) of
              (R.RCFNM {argVarList=[argVar], bodyTy, bodyExp, loc=_},
               [argExp]) =>
              R.RCMONOLET {binds = [(argVar, argExp)],
                           bodyExp = bodyExp, loc = loc}
            | (funExp, argExpList) =>
              R.RCAPPM {funExp = funExp, funTy = funTy,
                        argExpList = argExpList, loc = loc}
        end
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
          {fields = RecordLabel.Map.map (compileExp env) fields,
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
      | R.RCFOREACH {data, dataTy, pred, predTy, iterator, iteratorTy, loc} =>
        compileForeach 
          loc env 
          {Data = {exp = compileExp env data, ty= dataTy},
           Iterator = {exp = compileExp env iterator, ty=iteratorTy},
           Pred = {exp = compileExp env pred, ty=predTy}}
      | R.RCFOREACHDATA {data, dataTy, whereParam, whereParamTy, pred, predTy, iterator, iteratorTy, loc} =>
        compileForeachData
          loc env 
          {Data = {exp = compileExp env data, ty= dataTy},
           WhereParam = {exp = compileExp env whereParam, ty = whereParamTy},
           Iterator = {exp = compileExp env iterator, ty=iteratorTy},
           Pred = {exp = compileExp env pred, ty=predTy}}
      | R.RCCAST ((rcexp, expTy), ty, loc) =>
        R.RCCAST ((compileExp env rcexp, expTy), ty, loc)
      | R.RCFFI (exp, ty, loc) =>
        compileFFIexp false loc env (exp, ty)
      | R.RCJOIN {ty, args, argTys, loc} =>
        let
          val Body = {exp = compileJoinExp 
                              loc env
                              {resultTy=ty, args=args, argTys=argTys}, 
                      ty = ty}
          val exnCon = TC.EXEXN (U.REIFY_NaturalJoin_exExnInfo ())
        in
          HandleAndReRaise loc exnCon Body
        end
      | R.RCJSON {exp,ty,coerceTy,loc} =>
        let
          val Body = compileJson loc env ({exp = exp, ty=ty}, coerceTy)
          val exnCon = TC.EXEXN (U.JSON_RuntimeTypeError_exExnInfo ())
        in
          HandleAndReRaise loc exnCon Body
        end

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

  fun compile  topEnv decls =
      map compileDecl decls

end
