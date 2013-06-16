structure TCRevealTy =
struct
local
  structure TC = TypedCalc
  structure T = Types
  structure TIU = TypeInferenceUtils
  structure P = Printers
  fun bug s = Control.Bug ("RevealTy: " ^ s)

  val revealTy = TyRevealTy.revealTy
  val revealConInfo = TyRevealTy.revealConInfo
  val revealExnInfo = TyRevealTy.revealExnInfo
  val revealExExnInfo = TyRevealTy.revealExExnInfo
  val revealOprimInfo = TyRevealTy.revealOprimInfo
  val revealPrimInfo  = TyRevealTy.revealPrimInfo
  val revealBtvEnv = TyRevealTy.revealBtvEnv

  (* declaration for type constraints *)
  type ty = T.ty
  type path = T.path
  type varInfo = {path:path, id:VarID.id, ty:ty}
  type rule = {args:TC.tppat list, body:TC.tpexp}
  type btv = BoundTypeVarID.id
  type varId = VarID.id
  fun evalFfiTy ffiTy =
      case ffiTy of
        TC.FFIBASETY (ty, loc) =>
        TC.FFIBASETY (revealTy ty, loc)
      | TC.FFIFUNTY (attribOpt (* Absyn.ffiAttributes option *),
                     ffiTyList1,
                     ffiTyList2,loc) =>
        TC.FFIFUNTY (attribOpt,
                     map evalFfiTy ffiTyList1,
                     map evalFfiTy ffiTyList2,
                     loc)
      | TC.FFIRECORDTY (fields:(string * TC.ffiTy) list,loc) =>
        TC.FFIRECORDTY
          (map (fn (l,ty)=>(l, evalFfiTy ty)) fields,loc)

  fun evalExnCon (exnCon:TC.exnCon) : TC.exnCon =
      case exnCon of
        TC.EXEXN exExnInfo => TC.EXEXN (revealExExnInfo exExnInfo)
      | TC.EXN exnInfo => TC.EXN (revealExnInfo exnInfo)
  fun evalVar ({id, ty, path}:varInfo) =
      {id=id, path=path, ty=revealTy ty}
  fun evalExp (exp:TC.tpexp) : TC.tpexp =
      case exp of
        TC.TPAPPM {argExpList, funExp, funTy, loc} =>
        TC.TPAPPM {argExpList = map evalExp argExpList,
                   funExp = evalExp funExp,
                   funTy = revealTy funTy,
                   loc = loc}
        | TC.TPCASEM {caseKind, expList, expTyList, loc, ruleBodyTy, ruleList} =>
          TC.TPCASEM
            {caseKind = caseKind,
             expList = map evalExp expList,
             expTyList = map revealTy expTyList,
             loc = loc,
             ruleBodyTy = revealTy ruleBodyTy,
             ruleList = map evalRule ruleList
            }
        | TC.TPCAST (tpexp, ty, loc) =>
          TC.TPCAST (evalExp tpexp, revealTy ty, loc)
        | TC.TPCONSTANT {const, loc, ty} =>
          TC.TPCONSTANT {const=const, loc = loc, ty=revealTy ty}
        | TC.TPDATACONSTRUCT {argExpOpt, argTyOpt, con:T.conInfo, instTyList, loc} =>
          TC.TPDATACONSTRUCT
            {argExpOpt = Option.map evalExp argExpOpt,
             argTyOpt =  Option.map revealTy argTyOpt,
             con = revealConInfo con,
             instTyList = map revealTy instTyList,
             loc = loc
            }
        | TC.TPERROR => exp
        | TC.TPEXNCONSTRUCT {argExpOpt, argTyOpt, exn:TC.exnCon, instTyList, loc} =>
          TC.TPEXNCONSTRUCT
            {argExpOpt = Option.map evalExp argExpOpt,
             argTyOpt =  Option.map revealTy argTyOpt,
             exn = evalExnCon exn,
             instTyList = map revealTy instTyList,
             loc = loc
            }
        | TC.TPEXN_CONSTRUCTOR {exnInfo, loc} =>
          TC.TPEXN_CONSTRUCTOR {exnInfo=revealExnInfo exnInfo, loc=loc}
        | TC.TPEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
          TC.TPEXEXN_CONSTRUCTOR {exExnInfo=revealExExnInfo exExnInfo, loc= loc}
        | TC.TPEXVAR ({path, ty}, loc) =>
          TC.TPEXVAR ({path=path, ty=revealTy ty}, loc)
        | TC.TPFFIIMPORT {ffiTy, loc, ptrExp, stubTy} =>
          TC.TPFFIIMPORT
            {ffiTy = evalFfiTy ffiTy,
             loc = loc,
             ptrExp = evalExp ptrExp,
             stubTy = revealTy stubTy
            }
        | TC.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
          TC.TPFNM
            {argVarList = map evalVar argVarList,
             bodyExp = evalExp bodyExp,
             bodyTy = revealTy bodyTy,
             loc = loc
            }
        | TC.TPGLOBALSYMBOL {kind, loc, name, ty} =>
          TC.TPGLOBALSYMBOL {kind=kind, loc=loc, name=name, ty=revealTy ty}
        | TC.TPHANDLE {exnVar, exp, handler, loc} =>
          TC.TPHANDLE {exnVar=evalVar exnVar,
                       exp=evalExp exp,
                       handler= evalExp handler,
                       loc=loc}
        | TC.TPLET {body:TC.tpexp list, decls, loc, tys} =>
          TC.TPLET {body=map evalExp body,
                    decls=map evalDecl decls, 
                    loc=loc, 
                    tys=map revealTy tys}
        | TC.TPMODIFY {elementExp, elementTy, label, loc, recordExp, recordTy} =>
          TC.TPMODIFY
            {elementExp = evalExp elementExp,
             elementTy = revealTy elementTy,
             label = label,
             loc = loc,
             recordExp = evalExp recordExp,
             recordTy = revealTy recordTy}
        | TC.TPMONOLET {binds:(T.varInfo * TC.tpexp) list, bodyExp, loc} =>
          TC.TPMONOLET {binds=map evalBind binds, 
                        bodyExp=evalExp bodyExp, 
                        loc=loc}
        | TC.TPOPRIMAPPLY {argExp, argTy, instTyList, loc, oprimOp:T.oprimInfo} =>
          TC.TPOPRIMAPPLY
            {argExp = evalExp argExp,
             argTy =  revealTy argTy,
             instTyList = map revealTy instTyList,
             loc = loc,
             oprimOp = revealOprimInfo oprimOp
            }
        | TC.TPPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
          TC.TPPOLY
            {btvEnv=revealBtvEnv btvEnv,
             exp = evalExp exp,
             expTyWithoutTAbs = revealTy expTyWithoutTAbs,
             loc = loc
            }
        | TC.TPPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
          TC.TPPOLYFNM
            {argVarList=map evalVar argVarList,
             bodyExp=evalExp bodyExp,
             bodyTy=revealTy bodyTy,
             btvEnv=revealBtvEnv btvEnv,
             loc=loc
            }
        | TC.TPPRIMAPPLY {argExp, argTy, instTyList, loc, primOp:T.primInfo} =>
          TC.TPPRIMAPPLY
            {argExp=evalExp argExp,
             argTy = revealTy argTy,
             instTyList=map revealTy instTyList,
             loc=loc,
             primOp=revealPrimInfo primOp
            }
        | TC.TPRAISE {exp, loc, ty} =>
          TC.TPRAISE {exp=evalExp exp, loc=loc, ty = revealTy ty}
        | TC.TPRECORD {fields:TC.tpexp LabelEnv.map, loc, recordTy} =>
          TC.TPRECORD
            {fields=LabelEnv.map evalExp fields,
             loc=loc,
             recordTy=revealTy recordTy
            }
        | TC.TPSELECT {exp, expTy, label, loc, resultTy} =>
          TC.TPSELECT
            {exp=evalExp exp,
             expTy=revealTy expTy,
             label=label,
             loc=loc,
             resultTy=revealTy resultTy
            }
        | TC.TPSEQ {expList, expTyList, loc} =>
          TC.TPSEQ
            {expList = map evalExp expList,
             expTyList = map revealTy expTyList,
             loc = loc
            }
        | TC.TPSIZEOF (ty, loc) =>
          TC.TPSIZEOF (revealTy ty, loc)
        | TC.TPSQLSERVER
            {loc,
             resultTy,
             schema:Types.ty LabelEnv.map LabelEnv.map,
             server:string
            } =>
          let
            val resultTy = revealTy resultTy
            val schema = LabelEnv.map (LabelEnv.map revealTy) schema
          in
            TC.TPSQLSERVER
              {loc=loc,
               resultTy=resultTy,
               schema=schema,
               server=server
              }
          end
        | TC.TPTAPP {exp, expTy, instTyList, loc} =>
          TC.TPTAPP {exp = evalExp exp,
                     expTy = revealTy expTy,
                     instTyList = map revealTy instTyList,
                     loc = loc
                    }
        | TC.TPVAR (varInfo, loc) => TC.TPVAR (evalVar varInfo, loc)
          (* the following should have been eliminate *)
        | TC.TPRECFUNVAR {arity, loc, var} =>
          raise bug "TPRECFUNVAR in eval"
  and evalPat (pat:TC.tppat) =
      case pat of
        TC.TPPATCONSTANT (const, ty, loc) => TC.TPPATCONSTANT (const, revealTy ty, loc)
      | TC.TPPATDATACONSTRUCT {argPatOpt, conPat, instTyList, loc, patTy} =>
        TC.TPPATDATACONSTRUCT
        {argPatOpt = Option.map evalPat argPatOpt,
         conPat=revealConInfo conPat,
         instTyList=map revealTy instTyList,
         loc=loc,
         patTy=revealTy patTy
        }
      | TC.TPPATERROR (ty,loc) => TC.TPPATERROR (revealTy ty,loc)
      | TC.TPPATEXNCONSTRUCT {argPatOpt, exnPat, instTyList, loc, patTy} =>
        TC.TPPATEXNCONSTRUCT
          {argPatOpt = Option.map evalPat argPatOpt,
           exnPat=evalExnCon exnPat,
           instTyList=map revealTy instTyList,
           loc=loc,
           patTy=revealTy patTy
          }
      | TC.TPPATLAYERED {asPat, loc, varPat} =>
        TC.TPPATLAYERED
          {asPat=evalPat asPat,
           loc=loc,
           varPat=evalPat varPat
          }
      | TC.TPPATRECORD {fields, loc, recordTy} =>
        TC.TPPATRECORD
          {fields=LabelEnv.map evalPat fields,
           loc=loc,
           recordTy=revealTy recordTy
          }
      | TC.TPPATVAR (var,loc) =>
        TC.TPPATVAR (evalVar var,loc)
      | TC.TPPATWILD (ty,loc) => TC.TPPATWILD (revealTy ty,loc)

  and evalRule ({args, body}:rule) =
      {args=map evalPat args, body=evalExp body}

  and evalDecl (tpdecl:TC.tpdecl) =
      case tpdecl of
        TC.TPEXD (exbinds:{exnInfo:Types.exnInfo, loc:Loc.loc} list, loc) =>
        TC.TPEXD
          (map (fn {exnInfo, loc} =>
                   {exnInfo=revealExnInfo exnInfo, loc=loc})
               exbinds,
           loc)
      | TC.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
        TC.TPEXNTAGD ({exnInfo=revealExnInfo exnInfo,
                       varInfo=evalVar varInfo},
                      loc)
      | TC.TPEXPORTEXN (exnInfo, loc) =>
        TC.TPEXPORTEXN (revealExnInfo exnInfo, loc)
      | TC.TPEXPORTVAR {internalVar, externalVar, loc} =>
        TC.TPEXPORTVAR {internalVar=internalVar,
                        externalVar=externalVar,
                        loc=loc}
      | TC.TPEXPORTRECFUNVAR _ =>
        raise bug "TPEXPORTRECFUNVAR to optimize"
      | TC.TPEXTERNEXN ({path, ty}, loc) =>
        TC.TPEXTERNEXN ({path=path, ty=revealTy ty}, loc)
      | TC.TPEXTERNVAR ({path, ty}, loc) =>
        TC.TPEXTERNVAR ({path=path, ty=revealTy ty}, loc)
      | TC.TPVAL (binds:(T.varInfo * TC.tpexp) list, loc) =>
        TC.TPVAL (map evalBind binds, loc)
      | TC.TPVALPOLYREC
          (btvEnv,
           recbinds:{exp:TC.tpexp, expTy:ty, var:T.varInfo} list,
           loc) =>
        TC.TPVALPOLYREC 
          (revealBtvEnv btvEnv, 
           map
             (fn {exp, expTy, var} =>
                 {var=evalVar var,
                  expTy=revealTy expTy,
                  exp=evalExp exp}
             )
             recbinds,
           loc)

      | TC.TPVALREC (recbinds:{exp:TC.tpexp, expTy:ty, var:T.varInfo} list,loc) =>
        TC.TPVALREC 
          (
           map
             (fn {exp, expTy, var} =>
                 {var=evalVar var,
                  expTy=revealTy expTy,
                  exp=evalExp exp}
             )
             recbinds,
           loc)
      (* the following should have been eliminate *)
      | TC.TPFUNDECL _ => raise bug "TPFUNDECL not eliminated"
      | TC.TPPOLYFUNDECL _  => raise bug "TPPOLYFUNDECL not eliminated"
  and evalBind (var, exp)  = (evalVar var, evalExp exp)
in
  fun revealTyTpdeclList declList = map evalDecl declList
  val revealFfiTy = evalFfiTy
  val revealExnCon = evalExnCon
end
end
