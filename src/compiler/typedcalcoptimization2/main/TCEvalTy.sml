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
      | TC.FFIRECORDTY (fields:(string * TC.ffiTy) list,loc) =>
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
                 instTyList = map evalT instTyList,
                 loc = loc,
                 patTy = evalT patTy
                }
            | TC.TPPATERROR (ty, loc) =>  TC.TPPATERROR (evalT ty, loc)
            | TC.TPPATEXNCONSTRUCT
                {argPatOpt, exnPat:TC.exnCon, instTyList, loc, patTy} =>
              TC.TPPATEXNCONSTRUCT
                {argPatOpt = Option.map evalPat argPatOpt,
                 exnPat = evalExnCon btvMap exnPat,
                 instTyList = map evalT instTyList,
                 loc = loc,
                 patTy = evalT patTy
                }
            | TC.TPPATLAYERED {asPat, loc, varPat} =>
              TC.TPPATLAYERED {asPat=evalPat asPat, loc=loc, varPat=evalPat varPat}
            | TC.TPPATRECORD {fields:TC.tppat LabelEnv.map, loc, recordTy} =>
              TC.TPPATRECORD {fields=LabelEnv.map evalPat fields, loc=loc, recordTy=evalT recordTy}
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
            | TC.TPCAST ((tpexp, expTy), ty, loc) =>
              TC.TPCAST ((eval tpexp, evalT expTy), evalT ty, loc)
            | TC.TPCONSTANT {const, loc, ty} =>
              TC.TPCONSTANT {const=const, loc = loc, ty=evalT ty}
            | TC.TPDATACONSTRUCT {argExpOpt, argTyOpt, con:T.conInfo, instTyList, loc} =>
              TC.TPDATACONSTRUCT
                {argExpOpt = Option.map eval argExpOpt,
                 argTyOpt = Option.map evalT argTyOpt,
                 con = evalConInfo btvMap con,
                 instTyList = map evalT instTyList,
                 loc = loc
                }
            | TC.TPERROR => exp
            | TC.TPEXNCONSTRUCT {argExpOpt, argTyOpt, exn:TC.exnCon, instTyList, loc} =>
              TC.TPEXNCONSTRUCT
                {argExpOpt = Option.map eval argExpOpt,
                 argTyOpt = Option.map evalT argTyOpt,
                 exn = evalExnCon btvMap exn,
                 instTyList = map evalT instTyList,
                 loc = loc
                }
            | TC.TPEXN_CONSTRUCTOR {exnInfo, loc} =>
              TC.TPEXN_CONSTRUCTOR {exnInfo=evalExnInfo btvMap exnInfo , loc=loc}
            | TC.TPEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
              TC.TPEXEXN_CONSTRUCTOR
                {exExnInfo=evalExExnInfo btvMap exExnInfo,
                 loc= loc}
            | TC.TPEXVAR {longsymbol, ty} =>
              TC.TPEXVAR {longsymbol=longsymbol, ty=evalT ty}
            | TC.TPFFIIMPORT {ffiTy, loc, funExp=TC.TPFFIFUN ptrExp, stubTy} =>
              TC.TPFFIIMPORT
                {ffiTy = evalFfiTy btvMap ffiTy,
                 loc = loc,
                 funExp = TC.TPFFIFUN (eval ptrExp),
                 stubTy = evalT stubTy
                }
            | TC.TPFFIIMPORT {ffiTy, loc, funExp as TC.TPFFIEXTERN _, stubTy} =>
              TC.TPFFIIMPORT
                {ffiTy = evalFfiTy btvMap ffiTy,
                 loc = loc,
                 funExp = funExp,
                 stubTy = evalT stubTy
                }
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
            | TC.TPLET {body:TC.tpexp list, decls, loc, tys} =>
              TC.TPLET {body=map eval body,
                        decls=map evalDecl decls,
                        loc=loc,
                        tys=map evalT tys}
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
            | TC.TPOPRIMAPPLY {argExp, argTy, instTyList, loc, oprimOp:T.oprimInfo} =>
              TC.TPOPRIMAPPLY
                {argExp = eval argExp,
                 argTy = evalT argTy,
                 instTyList = map evalT instTyList,
                 loc = loc,
                 oprimOp = evalOprimInfo btvMap oprimOp
                }
            | TC.TPPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
              TC.TPPOLY
                {btvEnv=evalBtvEnv btvMap btvEnv,
                 exp = eval exp,
                 expTyWithoutTAbs = evalT expTyWithoutTAbs,
                 loc = loc
                }
            | TC.TPPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
              TC.TPPOLYFNM
                {argVarList= map (evalTyVar btvMap) argVarList,
                 bodyExp= eval bodyExp,
                 bodyTy=evalT bodyTy,
                 btvEnv=evalBtvEnv btvMap btvEnv,
                 loc=loc
                }
            | TC.TPPRIMAPPLY {argExp, argTy, instTyList, loc, primOp:T.primInfo} =>
              TC.TPPRIMAPPLY
                {argExp = eval argExp,
                 argTy = evalT argTy,
                 instTyList = map evalT instTyList,
                 loc = loc,
                 primOp = evalPrimInfo btvMap primOp
                }
            | TC.TPRAISE {exp, loc, ty} =>
              TC.TPRAISE {exp= eval exp, loc=loc, ty = evalT ty}
            | TC.TPRECORD {fields:TC.tpexp LabelEnv.map, loc, recordTy} =>
              TC.TPRECORD
                {fields=LabelEnv.map eval fields,
                 loc=loc,
                 recordTy=evalT recordTy}
            | TC.TPSELECT {exp, expTy, label, loc, resultTy} =>
              TC.TPSELECT
                {exp=eval exp,
                 expTy=evalT expTy,
                 label=label,
                 loc=loc,
                 resultTy=evalT resultTy
                }
            | TC.TPSEQ {expList, expTyList, loc} =>
              TC.TPSEQ
                {expList = map eval expList,
                 expTyList = map evalT expTyList,
                 loc = loc
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
            (* the following should have been eliminate *)
            | TC.TPRECFUNVAR {arity, var} =>
              raise bug "TPRECFUNVAR in eval"
        and evalRule {args, body} =
            {args=map evalPat args, body=eval body}
        and evalDecl tpdecl =
            case tpdecl of
              TC.TPEXD (exbinds:{exnInfo:Types.exnInfo, loc:Loc.loc} list, loc) =>
              TC.TPEXD
                (map (fn {exnInfo, loc} =>
                         {exnInfo=evalExnInfo btvMap exnInfo, loc=loc})
                     exbinds,
                 loc)
            | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
              TC.TPEXNTAGD ({exnInfo=evalExnInfo btvMap exnInfo,
                             varInfo=evalTyVar btvMap varInfo},
                            loc)
            | TC.TPEXPORTEXN exnInfo =>
              TC.TPEXPORTEXN (evalExnInfo btvMap exnInfo)
            | TC.TPEXPORTVAR varInfo =>
              TC.TPEXPORTVAR (evalTyVar btvMap varInfo)
            | TC.TPEXPORTRECFUNVAR _ =>
              raise bug "TPEXPORTRECFUNVAR to AlphaRename"
            | TC.TPEXTERNEXN {longsymbol, ty} =>
              TC.TPEXTERNEXN {longsymbol=longsymbol, ty=evalT ty}
            | TC.TPEXTERNVAR {longsymbol, ty} =>
              TC.TPEXTERNVAR {longsymbol=longsymbol, ty=evalT ty}
            | TC.TPVAL (binds:(T.varInfo * TC.tpexp) list, loc) =>
              TC.TPVAL (map evalBind binds, loc)
            | TC.TPVALPOLYREC
                (btvEnv,
                 recbinds:{exp:TC.tpexp, expTy:ty, var:T.varInfo} list,
                 loc) =>
              TC.TPVALPOLYREC 
                (evalBtvEnv btvMap btvEnv, 
                 map
                   (fn {exp,expTy,var} =>
                       {exp=eval exp, expTy=evalT expTy, var=evalTyVar btvMap var}) 
                   recbinds,
                 loc)
            | TC.TPVALREC (recbinds:{exp:TC.tpexp, expTy:ty, var:T.varInfo} list,loc) =>
              TC.TPVALREC
                (map
                   (fn {exp,expTy,var} =>
                       {exp=eval exp, expTy=evalT expTy, var=evalTyVar btvMap var})
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
