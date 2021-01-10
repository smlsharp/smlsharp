structure TCEvalTy =
struct
local
  structure TC = TypedCalc
  structure T = Types
  fun bug s = Bug.Bug ("TCEvalTy: " ^ s)

  type ty = T.ty
  type btvMap = ty BoundTypeVarID.Map.map

  fun evalExVarInfo (btvMap:btvMap) (exVarInfo : T.exVarInfo) : T.exVarInfo =
      TyReduce.evalExVarInfo btvMap exVarInfo
  fun evalPrimInfo (btvMap:btvMap) (primInfo:T.primInfo) : T.primInfo =
      TyReduce.evalPrimInfo btvMap primInfo
  fun evalOprimInfo (btvMap:btvMap) (oprimInfo:T.oprimInfo) : T.oprimInfo =
      TyReduce.evalOprimInfo btvMap oprimInfo
  fun evalConInfo (btvMap:btvMap) (conInfo:T.conInfo) : T.conInfo =
      TyReduce.evalConInfo btvMap conInfo
  fun evalExnInfo (btvMap:btvMap) (exnInfo:T.exnInfo) : T.exnInfo =
      TyReduce.evalExnInfo btvMap exnInfo
  fun evalExExnInfo (btvMap:btvMap) (exExnInfo:T.exExnInfo) : T.exExnInfo =
      TyReduce.evalExExnInfo btvMap exExnInfo
  fun evalBtvEnv (btvMap:btvMap) (btvEnv:T.btvEnv) =
      TyReduce.evalBtvEnv btvMap btvEnv
  fun evalTyVar (btvMap:btvMap) (var:T.varInfo) =
      TyReduce.evalTyVar btvMap var
  fun evalExnCon (btvMap:btvMap) (exnCon:TC.exnCon) : TC.exnCon =
      case exnCon of
        TC.EXEXN exExnInfo => TC.EXEXN (evalExExnInfo btvMap exExnInfo)
      | TC.EXN exnInfo => TC.EXN (evalExnInfo btvMap exnInfo)
  fun evalFfiTy (btvMap:btvMap) ffiTy =
      case ffiTy of
        TC.FFIBASETY (ty, loc) =>
        TC.FFIBASETY (TyReduce.evalTy btvMap ty, loc)
      | TC.FFIFUNTY (attribOpt (* Absyn.ffiAttributes option *),
                     ffiTyList1,
                     ffiTyList2,
                     ffiTyList3,loc) =>
        TC.FFIFUNTY (attribOpt,
                     map (evalFfiTy btvMap) ffiTyList1,
                     Option.map (map (evalFfiTy btvMap)) ffiTyList2,
                     map (evalFfiTy btvMap) ffiTyList3,
                     loc)
      | TC.FFIRECORDTY (fields:(RecordLabel.label * TC.ffiTy) list,loc) =>
        TC.FFIRECORDTY
          (map (fn (l,ty)=>(l, evalFfiTy btvMap ty)) fields,loc)

in
  fun evalExp (btvMap:btvMap) (exp:TC.tpexp) =
      let
        fun evalT ty = TyReduce.evalTy btvMap ty
        fun evalPat pat =
            case pat of
              TC.TPPATCONSTANT (constant, ty, loc) =>
              TC.TPPATCONSTANT (constant, evalT ty, loc)
            | TC.TPPATDATACONSTRUCT
                {argPatOpt,
                 conPat:T.conInfo,
                 instTyList,
                 loc,
                 patTy} =>
              TC.TPPATDATACONSTRUCT
                {argPatOpt = Option.map evalPat argPatOpt,
                 conPat = evalConInfo btvMap conPat,
                 instTyList = Option.map (map evalT) instTyList,
                 loc = loc,
                 patTy = evalT patTy
                }
            | TC.TPPATERROR (ty, loc) =>  TC.TPPATERROR (evalT ty, loc)
            | TC.TPPATEXNCONSTRUCT
                {argPatOpt, exnPat:TC.exnCon, loc, patTy} =>
              TC.TPPATEXNCONSTRUCT
                {argPatOpt = Option.map evalPat argPatOpt,
                 exnPat = evalExnCon btvMap exnPat,
                 loc = loc,
                 patTy = evalT patTy
                }
            | TC.TPPATLAYERED {asPat, loc, varPat} =>
              TC.TPPATLAYERED {asPat=evalPat asPat, loc=loc, varPat=evalPat varPat}
            | TC.TPPATRECORD {fields:TC.tppat RecordLabel.Map.map, loc, recordTy} =>
              TC.TPPATRECORD {fields=RecordLabel.Map.map evalPat fields, loc=loc, recordTy=evalT recordTy}
            | TC.TPPATVAR varInfo => TC.TPPATVAR (evalTyVar btvMap varInfo)
            | TC.TPPATWILD (ty, loc) => TC.TPPATWILD (evalT ty, loc)

        fun eval exp =
            case exp of
              TC.TPAPPM {argExpList, funExp, funTy, loc} =>
              TC.TPAPPM {argExpList = map eval argExpList,
                         funExp = eval funExp,
                         funTy = evalT funTy,
                         loc = loc}
            | TC.TPCASEM {caseKind, expList, expTyList, loc, ruleBodyTy, ruleList} =>
              TC.TPCASEM
                {caseKind = caseKind,
                 expList = map eval expList,
                 expTyList = map evalT expTyList,
                 loc = loc,
                 ruleBodyTy = evalT ruleBodyTy,
                 ruleList = map evalRule ruleList
                }
            | TC.TPSWITCH {exp, expTy, ruleList, defaultExp, ruleBodyTy, loc} =>
              let
                fun evalConst {const, ty, body} =
                    {const = const,
                     ty = evalT ty,
                     body = eval body}
                fun evalCon {con, instTyList, argVarOpt, body} =
                    {con = evalConInfo btvMap con,
                     instTyList = Option.map (map evalT) instTyList,
                     argVarOpt = Option.map (evalTyVar btvMap) argVarOpt,
                     body = eval body}
                fun evalExn {exn, argVarOpt, body} =
                    {exn = evalExnCon btvMap exn,
                     argVarOpt = Option.map (evalTyVar btvMap) argVarOpt,
                     body = eval body}
                fun evalRules (TC.CONSTCASE rules) =
                    TC.CONSTCASE (map evalConst rules)
                  | evalRules (TC.CONCASE rules) =
                    TC.CONCASE (map evalCon rules)
                  | evalRules (TC.EXNCASE rules) =
                    TC.EXNCASE (map evalExn rules)
              in
                TC.TPSWITCH
                  {exp = eval exp,
                   expTy = evalT expTy,
                   ruleList = evalRules ruleList,
                   defaultExp = eval defaultExp,
                   ruleBodyTy = evalT ruleBodyTy,
                   loc = loc}
              end
            | TC.TPCATCH {catchLabel, tryExp, argVarList, catchExp, resultTy, loc} =>
              TC.TPCATCH
                {catchLabel = catchLabel,
                 tryExp = eval tryExp,
                 argVarList = map (evalTyVar btvMap) argVarList,
                 catchExp = eval catchExp,
                 resultTy = evalT resultTy,
                 loc = loc}
            | TC.TPTHROW {catchLabel, argExpList, resultTy, loc} =>
              TC.TPTHROW
                {catchLabel = catchLabel,
                 argExpList = map eval argExpList,
                 resultTy = evalT resultTy,
                 loc = loc}
            | TC.TPCAST ((tpexp, expTy), ty, loc) =>
              TC.TPCAST ((eval tpexp, evalT expTy), evalT ty, loc)
            | TC.TPCONSTANT {const, loc, ty} =>
              TC.TPCONSTANT {const=const, loc = loc, ty=evalT ty}
            | TC.TPDATACONSTRUCT {argExpOpt, con:T.conInfo, instTyList, loc} =>
              TC.TPDATACONSTRUCT
                {argExpOpt = Option.map eval argExpOpt,
                 con = evalConInfo btvMap con,
                 instTyList = Option.map (map evalT) instTyList,
                 loc = loc
                }
            | TC.TPDYNAMICCASE {groupListTerm, groupListTy, dynamicTerm, dynamicTy, elemTy, ruleBodyTy, loc} => 
              TC.TPDYNAMICCASE {groupListTerm = eval groupListTerm,
                                groupListTy = evalT groupListTy,
                                dynamicTerm = eval dynamicTerm,
                                dynamicTy = evalT dynamicTy,
                                elemTy = evalT elemTy,
                                ruleBodyTy = evalT ruleBodyTy,
                                loc = loc}
            | TC.TPDYNAMICEXISTTAPP {existInstMap, exp, expTy, instTyList, loc} =>
              TC.TPDYNAMICEXISTTAPP
                {existInstMap = existInstMap,
                 exp = eval exp,
                 expTy = evalT expTy,
                 instTyList = map evalT instTyList,
                 loc = loc}
            | TC.TPERROR => exp
            | TC.TPEXNCONSTRUCT {argExpOpt, exn:TC.exnCon, loc} =>
              TC.TPEXNCONSTRUCT
                {argExpOpt = Option.map eval argExpOpt,
                 exn = evalExnCon btvMap exn,
                 loc = loc
                }
            | TC.TPEXNTAG {exnInfo, loc} =>
              TC.TPEXNTAG {exnInfo=evalExnInfo btvMap exnInfo , loc=loc}
            | TC.TPEXEXNTAG {exExnInfo, loc} =>
              TC.TPEXEXNTAG
                {exExnInfo=evalExExnInfo btvMap exExnInfo,
                 loc= loc}
            | TC.TPEXVAR ({path, ty}, loc) =>
              TC.TPEXVAR ({path=path, ty=evalT ty}, loc)
            | TC.TPFFIIMPORT {ffiTy, loc, funExp=TC.TPFFIFUN (ptrExp, ty), stubTy} =>
              TC.TPFFIIMPORT
                {ffiTy = evalFfiTy btvMap ffiTy,
                 loc = loc,
                 funExp = TC.TPFFIFUN (eval ptrExp, evalT ty),
                 stubTy = evalT stubTy
                }
            | TC.TPFFIIMPORT {ffiTy, loc, funExp as TC.TPFFIEXTERN _, stubTy} =>
              TC.TPFFIIMPORT
                {ffiTy = evalFfiTy btvMap ffiTy,
                 loc = loc,
                 funExp = funExp,
                 stubTy = evalT stubTy
                }
            | TC.TPFOREIGNSYMBOL {name, ty, loc} =>
              TC.TPFOREIGNSYMBOL {name = name, ty = evalT ty, loc = loc}
            | TC.TPFOREIGNAPPLY {funExp, argExpList, attributes, resultTy,
                                 loc} =>
              TC.TPFOREIGNAPPLY
                {funExp = eval funExp,
                 argExpList = map eval argExpList,
                 attributes = attributes,
                 resultTy = Option.map evalT resultTy,
                 loc = loc}
            | TC.TPCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
              TC.TPCALLBACKFN
                {attributes = attributes,
                 argVarList = map (evalTyVar btvMap) argVarList,
                 bodyExp = eval bodyExp,
                 resultTy = Option.map evalT resultTy,
                 loc = loc}
            | TC.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
              TC.TPFNM
                {argVarList = map (evalTyVar btvMap) argVarList,
                 bodyExp = eval bodyExp,
                 bodyTy = evalT bodyTy,
                 loc = loc
                }
            | TC.TPHANDLE {exnVar, exp, handler, resultTy, loc} =>
              TC.TPHANDLE
                {exnVar=evalTyVar btvMap exnVar,
                 exp=eval exp,
                 handler=eval handler, 
                 resultTy = evalT resultTy,
                 loc=loc}
            | TC.TPLET {body, decls, loc} =>
              TC.TPLET {body=eval body,
                        decls=map evalDecl decls,
                        loc=loc}
            | TC.TPMODIFY {elementExp, elementTy, label, loc, recordExp, recordTy} =>
              TC.TPMODIFY
                {elementExp = eval elementExp,
                 elementTy = evalT elementTy,
                 label = label,
                 loc = loc,
                 recordExp = eval recordExp,
                 recordTy = evalT recordTy}
            | TC.TPMONOLET {binds:(T.varInfo * TC.tpexp) list, bodyExp, loc} =>
              TC.TPMONOLET {binds=map evalBind binds, bodyExp=eval bodyExp, loc=loc}
            | TC.TPOPRIMAPPLY {argExp, instTyList, loc, oprimOp:T.oprimInfo} =>
              TC.TPOPRIMAPPLY
                {argExp = eval argExp,
                 instTyList = map evalT instTyList,
                 loc = loc,
                 oprimOp = evalOprimInfo btvMap oprimOp
                }
            | TC.TPPOLY {btvEnv, constraints, exp, expTyWithoutTAbs, loc} =>
              TC.TPPOLY
                {btvEnv=evalBtvEnv btvMap btvEnv,
                 constraints=map (TyReduce.evalConstraint btvMap) constraints,
                 exp = eval exp,
                 expTyWithoutTAbs = evalT expTyWithoutTAbs,
                 loc = loc
                }
            | TC.TPPRIMAPPLY {argExp, instTyList, loc, primOp:T.primInfo} =>
              TC.TPPRIMAPPLY
                {argExp = eval argExp,
                 instTyList = Option.map (map evalT) instTyList,
                 loc = loc,
                 primOp = evalPrimInfo btvMap primOp
                }
            | TC.TPRAISE {exp, loc, ty} =>
              TC.TPRAISE {exp= eval exp, loc=loc, ty = evalT ty}
            | TC.TPRECORD {fields:TC.tpexp RecordLabel.Map.map, loc, recordTy} =>
              TC.TPRECORD
                {fields=RecordLabel.Map.map eval fields,
                 loc=loc,
                 recordTy=RecordLabel.Map.map evalT recordTy}
            | TC.TPSELECT {exp, expTy, label, loc, resultTy} =>
              TC.TPSELECT
                {exp=eval exp,
                 expTy=evalT expTy,
                 label=label,
                 loc=loc,
                 resultTy=evalT resultTy
                }
            | TC.TPSIZEOF (ty, loc) =>
              TC.TPSIZEOF (evalT ty, loc)
            | TC.TPTAPP {exp, expTy, instTyList, loc} =>
              TC.TPTAPP {exp=eval exp,
                         expTy = evalT expTy,
                         instTyList=map evalT instTyList,
                         loc = loc
                        }
            | TC.TPVAR varInfo =>
              TC.TPVAR (evalTyVar btvMap varInfo)
            | TC.TPJOIN {isJoin, ty, args = (arg1, arg2), argtys = (argty1, argty2), loc} =>
              TC.TPJOIN {ty = evalT ty,
                         args = (eval arg1, eval arg2),
                         argtys = (evalT argty1, evalT argty2),
                         isJoin = isJoin,
                         loc = loc}
            (* the following should have been eliminate *)
            | TC.TPRECFUNVAR {arity, var} =>
              raise bug "TPRECFUNVAR in eval"
            | TC.TPDYNAMIC {exp,ty,elemTy, coerceTy,loc} =>
              TC.TPDYNAMIC {exp=eval exp,
                            ty=evalT ty,
                            elemTy = evalT elemTy,
                            coerceTy=evalT coerceTy,
                            loc=loc}
            | TC.TPDYNAMICIS {exp,ty,elemTy, coerceTy,loc} =>
              TC.TPDYNAMICIS {exp=eval exp,
                              ty=evalT ty,
                              elemTy = evalT elemTy,
                              coerceTy=evalT coerceTy,
                              loc=loc}
            | TC.TPDYNAMICNULL {ty, coerceTy,loc} =>
              TC.TPDYNAMICNULL {ty=evalT ty,
                                coerceTy=evalT coerceTy,
                                loc=loc}
            | TC.TPDYNAMICTOP {ty, coerceTy,loc} =>
              TC.TPDYNAMICTOP {ty=evalT ty,
                               coerceTy=evalT coerceTy,
                               loc=loc}
            | TC.TPDYNAMICVIEW {exp,ty,elemTy, coerceTy,loc} =>
              TC.TPDYNAMICVIEW {exp=eval exp,
                                ty=evalT ty,
                                elemTy = evalT elemTy,
                                coerceTy=evalT coerceTy,
                                loc=loc}
            | TC.TPREIFYTY (ty, loc) =>
              TC.TPREIFYTY (evalT ty, loc)
        and evalRule {args, body} =
            {args=map evalPat args, body=eval body}
        and evalDecl tpdecl =
            case tpdecl of
              TC.TPEXD (exnInfo, loc) =>
              TC.TPEXD
                (evalExnInfo btvMap exnInfo,
                 loc)
            | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
              TC.TPEXNTAGD ({exnInfo=evalExnInfo btvMap exnInfo,
                             varInfo=evalTyVar btvMap varInfo},
                            loc)
            | TC.TPEXPORTEXN exnInfo =>
              TC.TPEXPORTEXN (evalExnInfo btvMap exnInfo)
            | TC.TPEXPORTVAR {var={path,ty}, exp} =>
              TC.TPEXPORTVAR {var = {path = path, ty = evalT ty},
                              exp = eval exp}
            | TC.TPEXTERNEXN ({path, ty}, provider) =>
              TC.TPEXTERNEXN ({path=path, ty=evalT ty}, provider)
            | TC.TPBUILTINEXN {path, ty} =>
              TC.TPBUILTINEXN {path=path, ty=evalT ty}
            | TC.TPEXTERNVAR ({path, ty}, provider) =>
              TC.TPEXTERNVAR ({path=path, ty=evalT ty}, provider)
            | TC.TPVAL (bind:(T.varInfo * TC.tpexp), loc) =>
              TC.TPVAL (evalBind bind, loc)
            | TC.TPVALPOLYREC
                {btvEnv,
                 constraints,
                 recbinds:{exp:TC.tpexp, var:T.varInfo} list,
                 loc} =>
              TC.TPVALPOLYREC 
                {btvEnv = evalBtvEnv btvMap btvEnv, 
                 constraints = map (TyReduce.evalConstraint btvMap) constraints,
                 recbinds =
                 map
                   (fn {exp,var} =>
                       {exp=eval exp, var=evalTyVar btvMap var})
                   recbinds,
                 loc = loc}
            | TC.TPVALREC (recbinds:{exp:TC.tpexp, var:T.varInfo} list,loc) =>
              TC.TPVALREC
                (map
                   (fn {exp,var} =>
                       {exp=eval exp, var=evalTyVar btvMap var})
                   recbinds, 
                 loc)
            (* the following should have been eliminate *)
            | TC.TPFUNDECL _ => raise bug "TPFUNDECL not eliminated"
            | TC.TPPOLYFUNDECL _  => raise bug "TPPOLYFUNDECL not eliminated"
        and evalBind (var, exp) = (evalTyVar btvMap var, eval exp)
      in
        eval exp
      end
end
end
