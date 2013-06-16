structure RCRevealTy =
struct
local
  structure TC = TypedCalc
  structure RC = RecordCalc
  structure T = Types
  fun bug s = Control.Bug ("RevealTy: " ^ s)

  val revealTy = TyRevealTy.revealTy
  val revealVar = TyRevealTy.revealVar
  val revealConInfo = TyRevealTy.revealConInfo
  val revealExnInfo = TyRevealTy.revealExnInfo
  val revealExExnInfo = TyRevealTy.revealExExnInfo
  val revealOprimInfo = TyRevealTy.revealOprimInfo
  val revealPrimInfo  = TyRevealTy.revealPrimInfo
  val revealBtvEnv = TyRevealTy.revealBtvEnv
  val revealFfiTy = TCRevealTy.revealFfiTy
  val revealExnCon = TCRevealTy.revealExnCon

  (* declaration for type constraints *)
  type ty = T.ty
  type path = T.path
  type varInfo = {path:path, id:VarID.id, ty:ty}
  type rcexp = RC.rcexp

  fun evalExp (exp:rcexp) : rcexp =
      case exp of
        RC.RCAPPM {argExpList, funExp, funTy, loc} =>
        RC.RCAPPM {argExpList = map evalExp argExpList,
                   funExp = evalExp funExp,
                   funTy = revealTy funTy,
                   loc = loc}
        | RC.RCCASE  {defaultExp:rcexp, exp:rcexp, expTy:Types.ty, loc:Loc.loc,
                      ruleList:(T.conInfo * varInfo option * rcexp) list} =>
          RC.RCCASE
            {defaultExp=evalExp defaultExp, 
             exp = evalExp exp,
             expTy = revealTy expTy, 
             loc=loc,
             ruleList = 
             map (fn (con, varOpt, exp) => 
                     (con, Option.map revealVar varOpt, evalExp exp))
                 ruleList
            }
        | RC.RCCAST (rcexp, ty, loc) =>
          RC.RCCAST (evalExp rcexp, revealTy ty, loc)
        | RC.RCCONSTANT {const, loc, ty} =>
          RC.RCCONSTANT {const=const, loc = loc, ty=revealTy ty}
        | RC.RCDATACONSTRUCT {argExpOpt, argTyOpt, con:T.conInfo, instTyList, loc} =>
          RC.RCDATACONSTRUCT
            {argExpOpt = Option.map evalExp argExpOpt,
             argTyOpt = Option.map revealTy argTyOpt,
             con = revealConInfo con,
             instTyList = map revealTy instTyList,
             loc = loc
            }
        | RC.RCEXNCASE {defaultExp:rcexp, exp:rcexp, expTy:ty, loc:Loc.loc,
                        ruleList:(TC.exnCon * varInfo option * rcexp) list} =>
          RC.RCEXNCASE
            {defaultExp=evalExp defaultExp, 
             exp = evalExp exp,
             expTy = revealTy expTy, 
             loc=loc,
             ruleList = 
             map (fn (con, varOpt, exp) => (con, Option.map revealVar varOpt, evalExp exp))
                 ruleList
            }
        | RC.RCEXNCONSTRUCT {argExpOpt, exn:TC.exnCon, instTyList, loc} =>
          RC.RCEXNCONSTRUCT
            {argExpOpt = Option.map evalExp argExpOpt,
             exn = revealExnCon exn,
             instTyList = map revealTy instTyList,
             loc = loc
            }
        | RC.RCEXN_CONSTRUCTOR {exnInfo, loc} =>
          RC.RCEXN_CONSTRUCTOR {exnInfo=revealExnInfo exnInfo, loc=loc}
        | RC.RCEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
          RC.RCEXEXN_CONSTRUCTOR {exExnInfo=revealExExnInfo exExnInfo, loc= loc}
        | RC.RCEXVAR ({path, ty}, loc) =>
          RC.RCEXVAR ({path=path, ty=revealTy ty}, loc)
        | RC.RCFNM {argVarList, bodyExp, bodyTy, loc} =>
          RC.RCFNM
            {argVarList = map revealVar argVarList,
             bodyExp = evalExp bodyExp,
             bodyTy = revealTy bodyTy,
             loc = loc
            }
        | RC.RCGLOBALSYMBOL {kind, loc, name, ty} =>
          RC.RCGLOBALSYMBOL {kind=kind, loc=loc, name=name, ty=revealTy ty}
        | RC.RCHANDLE {exnVar, exp, handler, loc} =>
          RC.RCHANDLE {exnVar=revealVar exnVar,
                       exp=evalExp exp,
                       handler= evalExp handler,
                       loc=loc}
        | RC.RCLET {body:rcexp list, decls, loc, tys} =>
          RC.RCLET {body=map evalExp body,
                    decls=map evalDecl decls, 
                    loc=loc, 
                    tys=map revealTy tys}
        | RC.RCMODIFY {elementExp, elementTy, indexExp, label, loc, recordExp, recordTy} =>
          RC.RCMODIFY
            {elementExp = evalExp elementExp,
             elementTy = revealTy elementTy,
             indexExp = evalExp indexExp,
             label = label,
             loc = loc,
             recordExp = evalExp recordExp,
             recordTy = revealTy recordTy}
        | RC.RCMONOLET {binds:(T.varInfo * rcexp) list, bodyExp, loc} =>
          RC.RCMONOLET {binds=map evalBind binds, 
                        bodyExp=evalExp bodyExp, 
                        loc=loc}
        | RC.RCOPRIMAPPLY {argExp, instTyList, loc, oprimOp:T.oprimInfo} =>
          RC.RCOPRIMAPPLY
            {argExp = evalExp argExp,
             instTyList = map revealTy instTyList,
             loc = loc,
             oprimOp = revealOprimInfo oprimOp
            }
        | RC.RCPOLY {btvEnv, exp, expTyWithoutTAbs, loc} =>
          RC.RCPOLY
            {btvEnv=revealBtvEnv btvEnv,
             exp = evalExp exp,
             expTyWithoutTAbs = revealTy expTyWithoutTAbs,
             loc = loc
            }
        | RC.RCPOLYFNM {argVarList, bodyExp, bodyTy, btvEnv, loc} =>
          RC.RCPOLYFNM
            {argVarList=map revealVar argVarList,
             bodyExp=evalExp bodyExp,
             bodyTy=revealTy bodyTy,
             btvEnv=revealBtvEnv btvEnv,
             loc=loc
            }
        | RC.RCPRIMAPPLY {argExp, instTyList, loc, primOp:T.primInfo} =>
          RC.RCPRIMAPPLY
            {argExp=evalExp argExp,
             instTyList=map revealTy instTyList,
             loc=loc,
             primOp=revealPrimInfo primOp
            }
        | RC.RCRAISE {exp, loc, ty} =>
          RC.RCRAISE {exp=evalExp exp, loc=loc, ty = revealTy ty}
        | RC.RCRECORD {fields:rcexp LabelEnv.map, loc, recordTy} =>
          RC.RCRECORD
            {fields=LabelEnv.map evalExp fields,
             loc=loc,
             recordTy=revealTy recordTy
            }
        | RC.RCSELECT {exp, expTy, indexExp, label, loc, resultTy} =>
          RC.RCSELECT
            {exp=evalExp exp,
             expTy=revealTy expTy,
             indexExp = evalExp indexExp,
             label=label,
             loc=loc,
             resultTy=revealTy resultTy
            }
        | RC.RCSEQ {expList, expTyList, loc} =>
          RC.RCSEQ
            {expList = map evalExp expList,
             expTyList = map revealTy expTyList,
             loc = loc
            }
        | RC.RCSIZEOF (ty, loc) =>
          RC.RCSIZEOF (revealTy ty, loc)
        | RC.RCSQL (RC.RCSQLSERVER {schema:Types.ty LabelEnv.map LabelEnv.map,
                                    server:string}, ty, loc) =>
          RC.RCSQL (RC.RCSQLSERVER 
                      {schema=LabelEnv.map (LabelEnv.map revealTy) schema, 
                       server=server},
                    revealTy ty, 
                    loc)
        | RC.RCTAPP {exp, expTy, instTyList, loc} =>
          RC.RCTAPP {exp = evalExp exp,
                     expTy = revealTy expTy,
                     instTyList = map revealTy instTyList,
                     loc = loc
                    }
        | RC.RCVAR (varInfo, loc) =>
          RC.RCVAR (revealVar varInfo, loc)
        | RC.RCEXPORTCALLBACK {foreignFunTy:Types.foreignFunTy, funExp:rcexp,
                               loc:Loc.loc} =>
          RC.RCEXPORTCALLBACK 
            {foreignFunTy = evalForeignFunTy foreignFunTy,
             funExp = evalExp funExp,
             loc=loc}
        | RC.RCFOREIGNAPPLY {argExpList:rcexp list,
                             foreignFunTy:Types.foreignFunTy, funExp:rcexp,
                             loc:Loc.loc} =>
          RC.RCFOREIGNAPPLY {argExpList = map evalExp argExpList,
                             foreignFunTy=evalForeignFunTy foreignFunTy,
                             funExp = evalExp funExp,
                             loc=loc}
        | RC.RCFFI (RC.RCFFIIMPORT {ffiTy:TypedCalc.ffiTy, ptrExp:rcexp}, ty, loc) =>
          RC.RCFFI (RC.RCFFIIMPORT 
                      {ffiTy=revealFfiTy ffiTy,
                       ptrExp=evalExp ptrExp},
                    revealTy ty, 
                    loc)
        | RC.RCINDEXOF (string, ty, loc) =>
          RC.RCINDEXOF (string, revealTy ty, loc)
        | RC.RCSWITCH {branches:(Absyn.constant * rcexp) list, defaultExp:rcexp,
                       expTy:Types.ty, loc:Loc.loc, switchExp:rcexp} =>
          RC.RCSWITCH 
            {branches =
             map (fn (con, exp) => (con, evalExp exp)) branches,
             defaultExp = evalExp defaultExp,
             expTy=revealTy expTy, 
             loc=loc, 
             switchExp=evalExp switchExp
            }
        | RC.RCTAGOF (ty, loc) =>
          RC.RCTAGOF (revealTy ty, loc)
  and evalForeignFunTy 
         {
          argTyList : ty list,
          resultTy : ty,
          attributes : Absyn.ffiAttributes
         } =
         {
          argTyList = map revealTy argTyList,
          resultTy = revealTy resultTy,
          attributes = attributes
         }

  and evalDecl (rcdecl:RC.rcdecl) =
      case rcdecl of
        RC.RCEXD (exbinds:{exnInfo:Types.exnInfo, loc:Loc.loc} list, loc) =>
        RC.RCEXD
          (map (fn {exnInfo, loc} =>
                   {exnInfo=revealExnInfo exnInfo, loc=loc})
               exbinds,
           loc)
      | RC.RCEXNTAGD ({exnInfo, varInfo}, loc) =>
        RC.RCEXNTAGD ({exnInfo=revealExnInfo exnInfo,
                       varInfo=revealVar varInfo},
                      loc)
      | RC.RCEXPORTEXN (exnInfo, loc) =>
        RC.RCEXPORTEXN (revealExnInfo exnInfo, loc)
      | RC.RCEXPORTVAR {internalVar, externalVar, loc} =>
        RC.RCEXPORTVAR {internalVar=internalVar,
                        externalVar=externalVar,
                        loc=loc}
      | RC.RCEXTERNEXN ({path, ty}, loc) =>
        RC.RCEXTERNEXN ({path=path, ty=revealTy ty}, loc)
      | RC.RCEXTERNVAR ({path, ty}, loc) =>
        RC.RCEXTERNVAR ({path=path, ty=revealTy ty}, loc)
      | RC.RCVAL (binds:(T.varInfo * rcexp) list, loc) =>
        RC.RCVAL (map evalBind binds, loc)
      | RC.RCVALPOLYREC
          (btvEnv,
           recbinds:{exp:rcexp, expTy:ty, var:T.varInfo} list,
           loc) =>
        RC.RCVALPOLYREC 
          (revealBtvEnv btvEnv, 
           map
             (fn {exp, expTy, var} =>
                 {var=revealVar var,
                  expTy=revealTy expTy,
                  exp=evalExp exp}
             )
             recbinds,
           loc)
      | RC.RCVALREC (recbinds:{exp:rcexp, expTy:ty, var:T.varInfo} list,loc) =>
        RC.RCVALREC 
          (
           map
             (fn {exp, expTy, var} =>
                 {var=revealVar var,
                  expTy=revealTy expTy,
                  exp=evalExp exp}
             )
             recbinds,
           loc)
  and evalBind (var, exp) =
      (revealVar var, evalExp exp)
in
  fun revealTyRcdeclList declList = map evalDecl declList
end
end
