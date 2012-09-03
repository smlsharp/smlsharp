(**
 * Utility functions to manipulate the typed pattern calculus.
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @version $Id: TypedCalcUtils.sml,v 1.20 2008/06/08 07:57:33 ohori Exp $
 *)
structure TypedCalcUtils : TYPEDCALCUTILS = struct
local 
    open Types TypedCalc TypesUtils
in

  fun getLocOfExp exp =
      case exp of
        TPFOREIGNAPPLY {loc,...} => loc
      | TPEXPORTCALLBACK {loc,...} => loc
      | TPSIZEOF (_, loc) => loc
      | TPERROR => Loc.noloc
      | TPCONSTANT (_, _, loc) => loc
      | TPGLOBALSYMBOL (_, _, _, loc) => loc
      | TPVAR (_, loc) => loc
      | TPRECFUNVAR {loc,...} => loc
      | TPPRIMAPPLY {loc,...} => loc
      | TPOPRIMAPPLY {loc,...} => loc
      | TPDATACONSTRUCT {loc,...} => loc
      | TPEXNCONSTRUCT {loc,...} => loc
      | TPAPPM {loc,...} => loc
      | TPMONOLET {loc,...} => loc
      | TPLET(tpdecs,tpexps,tys, loc) => loc
      | TPRECORD {loc,...} => loc
      | TPSELECT {loc,...} => loc
      | TPMODIFY {loc,...} => loc
      | TPRAISE (tpexp,ty,loc) => loc
      | TPHANDLE {loc,...} => loc
      | TPCASEM {loc,...} => loc
      | TPFNM  {loc,...} => loc
      | TPPOLYFNM {loc,...} => loc
      | TPPOLY {loc,...} => loc
      | TPTAPP {loc,...} => loc
      | TPSEQ {loc,...} => loc
      | TPLIST {loc,...} => loc
      | TPCAST (toexo, ty, loc) => loc

  (**
   * Make a fresh instance of a polytype and a term of that type.
   *)
  fun freshInst (ty,ex) =
    if monoTy ty then (ty,ex)
    else
      let
        val exLoc = getLocOfExp ex
      in
        case ty 
          of (POLYty{boundtvars,body,...}) =>
             let 
               val subst = freshSubst boundtvars
               val bty = substBTvar subst body
               val newEx = 
                 case ex of
                   TPDATACONSTRUCT {con, instTyList=nil, argExpOpt=NONE, loc}
                   => TPDATACONSTRUCT {con=con, 
                                       instTyList=IEnv.listItems subst,
                                       argExpOpt=NONE, 
                                       loc=loc}
                 | _ => TPTAPP{exp=ex,
                               expTy=ty,
                               instTyList=IEnv.listItems subst,
                               loc=exLoc}
             in  
               freshInst (bty,newEx)
             end
           | FUNMty (tyList, bodyTy) =>
             (* 
              OLD: (fn f:ty => fn x :ty1 => inst(f x)) ex 
              NEW   fn {x1:ty1,...,xn:tyn} => inst(ex {x1,...,xn})
              *)
             let
               val varname = VarName.generate ()
               val xList = map (fn ty => {namePath=(varname, Path.NilPath), ty=ty}) tyList
               val xexList = map (fn x => TPVAR (x, exLoc)) xList
               val (instBodyTy, instBody) = 
                 freshInst 
                 (bodyTy,TPAPPM {funExp=ex, funTy=ty, argExpList=xexList, loc=exLoc})
             in 
               (
                (FUNMty(tyList, instBodyTy), 
                 TPFNM {argVarList = xList, bodyTy=instBodyTy, bodyExp=instBody, loc=exLoc})
                )
             end
           | RECORDty fl => 
             (* 
              OLD: (fn r => {...,l=inst(x.l,ty) ...}) ex 
              NEW: let val xex = ex in {...,l=inst(x.l,ty) ...}
              *)
             (case ex of 
                TPRECORD {fields=flex, recordTy=ty,loc=loc} =>
                  let val (newfl,newflex) =
                    SEnv.foldli
                    (fn (l,_,(newfl,newflex)) =>
                     (case (SEnv.find(fl,l),
                            SEnv.find(flex,l)) of
                        (SOME ty,SOME ex) => 
                          let 
                            val (ty',ex') = 
                              freshInst 
                              (ty,ex)
                          in (SEnv.insert(newfl,l,ty'),
                              SEnv.insert(newflex,l,ex'))
                          end
                      | _ => raise Control.Bug "freshInst"
                          ))
                    (SEnv.empty, SEnv.empty)
                    fl
                  in
                    (
                     RECORDty newfl,
                     TPRECORD {fields=newflex, recordTy = RECORDty newfl, loc=loc}
                     )
                  end
              | _ =>
                let 
                  fun isAtom exp =
                    case exp of
                      TPVAR v => true
                    | TPCONSTANT _ => true
                    | TPGLOBALSYMBOL _ => true
                    | _ => false
                in
                  if isAtom ex then
                    let 
                      val (flty,flex) =
                        SEnv.foldri 
                        (fn (label,fieldTy,(flty,flex)) =>
                         let
                           val (fieldTy,litem) = 
                             freshInst
                             (fieldTy,TPSELECT{label=label, exp=ex, expTy=ty, resultTy=fieldTy, loc=exLoc})
                         in (SEnv.insert(flty,label,fieldTy),
                             SEnv.insert(flex,label,litem)
                             )
                         end)
                        (SEnv.empty,SEnv.empty)
                        fl
                    in 
                      (
                       RECORDty flty, 
                       TPRECORD {fields=flex, recordTy = RECORDty flty, loc=exLoc}
                       )
                    end
                  else
                    let 
                      val varname = VarName.generate ()
                      val var = {namePath = (varname, Path.NilPath), ty = ty}
                      val varex = TPVAR (var, exLoc)
                      val (flty,flex) =
                        SEnv.foldri 
                        (fn (label,fieldTy,(flty,flex)) =>
                         let val (fieldTy,litem) =
                           freshInst 
                           (fieldTy, TPSELECT {label=label, exp=varex, expTy=ty, resultTy=fieldTy, loc=exLoc})
                         in (SEnv.insert(flty,label,fieldTy),
                             SEnv.insert(flex,label,litem)
                             )
                         end)
                        (SEnv.empty,SEnv.empty)
                        fl
                    in 
                      (
                       RECORDty flty, 
                       TPLET(
                             [TPVAL([(VALIDVAR ({namePath = (varname,Path.NilPath), ty = ty}),
                                      ex)], 
                                    exLoc)],
                             [TPRECORD {fields=flex, recordTy=RECORDty flty, loc=exLoc}],
                             [RECORDty flty],
                             exLoc
                             )
                       )
                    end
                end
              )
           | ty => (ty,ex)
      end

  fun tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue tpexp =
      case tpexp of
          TPFOREIGNAPPLY{funExp, funTy, instTyList, argExpList, argTyList, attributes, loc} =>
          let
              val (newFunExp, accum') =
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue funExp
              val (newArgExpList, accum'') =
                  tpExpListExnTagTransducer applyFunction accumMerge defaultAccumValue argExpList
          in
              (TPFOREIGNAPPLY{funExp = newFunExp,
                              funTy = funTy, 
                              instTyList = instTyList, 
                              argExpList = newArgExpList, 
                              argTyList = argTyList , 
                              attributes = attributes, 
                              loc = loc},
               accumMerge(accum', accum'')
              )
          end
        | TPEXPORTCALLBACK {funExp, argTyList, resultTy, attributes, loc} =>
          let
              val (newFunExp, accum') =
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue funExp
          in
              (TPEXPORTCALLBACK {funExp = newFunExp, 
                                 argTyList = argTyList, 
                                 resultTy = resultTy, 
                                 attributes = attributes,
                                 loc = loc},
               accum')
          end
        | TPSIZEOF _ => (tpexp, defaultAccumValue)
        | TPERROR  =>  (tpexp, defaultAccumValue)
        | TPCONSTANT _ => (tpexp, defaultAccumValue)
        | TPGLOBALSYMBOL _ => (tpexp, defaultAccumValue)
        | TPVAR _ => (tpexp, defaultAccumValue)
        | TPRECFUNVAR _ => (tpexp, defaultAccumValue)
        | TPPRIMAPPLY {primOp, instTyList, argExpOpt = NONE, loc} =>
          (tpexp, defaultAccumValue)
        | TPPRIMAPPLY {primOp, instTyList, argExpOpt = SOME exp, loc} =>
          let
              val (newArgExp, accum') =
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue exp
          in
              (TPPRIMAPPLY {primOp = primOp, 
                            instTyList = instTyList, 
                            argExpOpt = SOME newArgExp, 
                            loc = loc},
               accum')
          end
        | TPOPRIMAPPLY {oprimOp,instances,keyTyList,argExpOpt = NONE, loc} =>
          (tpexp, defaultAccumValue)
        | TPOPRIMAPPLY
            {oprimOp,instances,keyTyList,argExpOpt =SOME argExp,loc} =>
          let
            val (newArgExp, accum') =
                tpExpExnTagTransducer
                  applyFunction
                  accumMerge
                  defaultAccumValue
                  argExp
          in
              (TPOPRIMAPPLY {oprimOp = oprimOp,
                             keyTyList = keyTyList,
                             instances = instances,
                             argExpOpt = SOME newArgExp, 
                             loc = loc},
               accum')
          end
        | TPDATACONSTRUCT {con, instTyList, argExpOpt = NONE, loc} =>
          (tpexp, defaultAccumValue)
        | TPDATACONSTRUCT {con, instTyList, argExpOpt = SOME arg, loc} =>
          let
              val (newArgExp, accum') =
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue arg
          in
              (TPDATACONSTRUCT {con = con, 
                                instTyList = instTyList, 
                                argExpOpt = SOME newArgExp, 
                                loc = loc},
               accum')
          end
        | TPEXNCONSTRUCT {exn = {namePath, funtyCon, ty, tag, tyCon}, instTyList, argExpOpt, loc} =>
          let
              val (newArgExpOpt, accum) =
                  case argExpOpt of
                      NONE => (NONE, defaultAccumValue)
                    | SOME argExp =>
                      let
                          val (newArgExp, accum') =
                              tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue argExp
                      in
                          (SOME newArgExp, accum')
                      end
          in
              (TPEXNCONSTRUCT {exn = {namePath = namePath, 
                                      funtyCon = funtyCon, 
                                      ty = ty, 
                                      tag = applyFunction tag, 
                                      tyCon = tyCon}, 
                               instTyList = instTyList, 
                               argExpOpt = newArgExpOpt,
                               loc = loc},
               accum)
          end
        | TPAPPM {funExp, funTy, argExpList, loc} =>
          let
              val (newFunExp, accum') =
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue funExp
              val (newArgExpList, accum'') =
                  tpExpListExnTagTransducer applyFunction accumMerge defaultAccumValue argExpList
          in
              (TPAPPM {funExp = newFunExp, 
                       funTy = funTy, 
                       argExpList = newArgExpList, 
                       loc = loc},
               accumMerge(accum', accum''))
          end
        | TPMONOLET {binds, bodyExp, loc} =>
          let
              val  (newBinds, accum) =
                   foldl (fn ((varInfo, exp), (newBinds, accum)) =>
                             let
                                 val (newExp, accum') =
                                     tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue exp
                             in
                                 (newBinds @ [(varInfo, newExp)],
                                  accumMerge (accum', accum))
                             end)
                         (nil, defaultAccumValue)
                         binds
              val (newBodyExp, accum') =
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue bodyExp
          in
              (TPMONOLET {binds = newBinds, 
                          bodyExp = newBodyExp, 
                          loc = loc},
               accumMerge(accum, accum'))
          end
        | TPLET (decs, exps, tys, loc) =>
          let
              val (newDecs, accum) =
                  tpDecListExnTagTransducer applyFunction accumMerge defaultAccumValue decs
              val (newExps, accum') =
                  tpExpListExnTagTransducer applyFunction accumMerge defaultAccumValue exps
          in
              (TPLET (newDecs, newExps, tys, loc), accumMerge(accum, accum'))
          end
        | TPRECORD {fields, recordTy, loc} =>
          let
              val (newFields, accum) =
                  SEnv.foldli (fn (label, exp, (newFields, accum)) =>
                                  let
                                      val (newExp, accum') =
                                          tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue exp
                                  in
                                      (SEnv.insert(newFields, label, newExp),
                                       accumMerge(accum, accum'))
                                  end)
                              (SEnv.empty, defaultAccumValue)
                              fields
          in
              (TPRECORD {fields = newFields, 
                         recordTy = recordTy, 
                         loc = loc},
               accum)
          end
        | TPSELECT {label, exp, expTy, resultTy, loc} =>
          let
              val (newExp, accum') =
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue exp
          in
              (TPSELECT {label = label, 
                         exp = newExp, 
                         expTy = expTy, 
                         resultTy = resultTy, 
                         loc = loc} ,
               accum')
          end
        | TPRAISE (exp, ty, loc) =>
          let
              val (newExp, accum') =
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue exp
          in
              (TPRAISE (newExp, ty, loc), accum')
          end
        | TPMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
          let
              val (newRecordExp, accum') =
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue recordExp
              val (newElementExp, accum'') =
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue elementExp
          in              
              (TPMODIFY {label = label, 
                         recordExp = newRecordExp, 
                         recordTy = recordTy, 
                         elementExp = newElementExp, 
                         elementTy = elementTy, 
                         loc = loc},
               accumMerge(accum', accum''))
          end
        | TPHANDLE {exp, exnVar, handler, loc} =>
          let
              val (newExp, accum') =
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue exp
              val (newHandler, accum'') =
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue handler
          in
              (TPHANDLE {exp = newExp, 
                         exnVar = exnVar, 
                         handler = newHandler, 
                         loc = loc},
               accumMerge(accum', accum''))
          end
        | TPCASEM {expList, expTyList, ruleList, ruleBodyTy, caseKind, loc} =>
          let
              val (newExpList, accum) =
                  tpExpListExnTagTransducer applyFunction accumMerge defaultAccumValue expList
              val (newRuleList, accum') =
                  foldl (fn ((tppatList, tpexp), (newRuleList, accum')) =>
                            let
                                val newTppatList = 
                                    tpPatListExnTagTransducer applyFunction tppatList
                                val (newExp, accum'') =
                                    tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue tpexp
                            in
                                (newRuleList @ [(newTppatList, newExp)],
                                 accumMerge(accum'', accum'))
                            end)
                        (nil, defaultAccumValue)
                        ruleList
          in
              (TPCASEM {expList = newExpList, 
                        expTyList = expTyList, 
                        ruleList = newRuleList, 
                        ruleBodyTy = ruleBodyTy, 
                        caseKind = caseKind, 
                        loc = loc},
               accumMerge(accum, accum')
              )
          end
        | TPFNM {argVarList, bodyTy, bodyExp, loc} =>
          let
              val (newBodyExp, accum) = 
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue bodyExp
          in
              (TPFNM {argVarList = argVarList, 
                      bodyTy = bodyTy, 
                      bodyExp = newBodyExp, 
                      loc = loc},
               accum)
          end
        | TPPOLYFNM {btvEnv, argVarList, bodyTy, bodyExp, loc} =>
          let
              val (newBodyExp, accum) = 
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue bodyExp
          in
              (TPPOLYFNM {btvEnv = btvEnv, 
                          argVarList = argVarList, 
                          bodyTy = bodyTy, 
                          bodyExp = newBodyExp, 
                          loc = loc},
               accum)
          end
        | TPPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
          let
              val (newExp, accum) = 
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue exp
          in
              (TPPOLY {btvEnv = btvEnv, 
                       expTyWithoutTAbs = expTyWithoutTAbs, 
                       exp = newExp, 
                       loc = loc} ,
               accum)
          end
        | TPTAPP {exp, expTy, instTyList, loc} =>
          let
              val (newExp, accum) = 
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue exp
          in
              (TPTAPP {exp = newExp, 
                       expTy = expTy, 
                       instTyList = instTyList, 
                       loc = loc},
               accum)
          end
        | TPSEQ {expList, expTyList, loc} =>
          let
              val (newExpList, accum) =
                  tpExpListExnTagTransducer applyFunction accumMerge defaultAccumValue expList
          in
              (TPSEQ {expList = newExpList, 
                      expTyList = expTyList, 
                      loc = loc},
               accum)
          end
        | TPLIST {expList, listTy, loc} =>
          let
              val (newExpList, accum) =
                  tpExpListExnTagTransducer applyFunction accumMerge defaultAccumValue expList
          in
              (TPLIST {expList = newExpList, 
                       listTy = listTy, 
                       loc = loc},
               accum)
          end
        | TPCAST (tpexp, ty , loc) =>
          let
              val (newExp, accum) = 
                  tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue tpexp
          in
              (TPCAST (newExp, ty , loc) , accum)
          end
          
  and tpExpListExnTagTransducer applyFunction accumMerge defaultAccumValue tpexpList =
      foldl (fn (tpexp, (newTpExpList, accum)) =>
                let
                    val (newTpexp, accum') =
                        tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue tpexp
                in
                    (newTpExpList @ [newTpexp], accumMerge(accum', accum))
                end)
            (nil, defaultAccumValue)
            tpexpList
              
  and tpPatExnTagTransducer applyFunction tppat =
      case tppat of
          TPPATWILD _ => tppat
        | TPPATVAR _ => tppat
        | TPPATCONSTANT _ => tppat
        | TPPATDATACONSTRUCT _ => tppat
        | TPPATEXNCONSTRUCT {exnPat = {namePath, funtyCon, ty, tag, tyCon},
                             instTyList,
                             argPatOpt, 
                             patTy,
                             loc} =>
          TPPATEXNCONSTRUCT {exnPat = {namePath = namePath, 
                                       funtyCon = funtyCon, 
                                       ty = ty, 
                                       tag = applyFunction tag, 
                                       tyCon = tyCon},
                             instTyList = instTyList,
                             argPatOpt = argPatOpt, 
                             patTy = patTy,
                             loc = loc}
        | TPPATRECORD {fields, recordTy, loc} =>
          TPPATRECORD {fields = SEnv.map (tpPatExnTagTransducer applyFunction) fields, 
                       recordTy = recordTy, 
                       loc = loc} 
        | TPPATLAYERED {varPat, asPat, loc} =>
          TPPATLAYERED {varPat = tpPatExnTagTransducer applyFunction varPat, 
                        asPat =  tpPatExnTagTransducer applyFunction asPat, 
                        loc = loc}
        | TPPATORPAT (tppat1, tppat2, loc) =>
          TPPATORPAT (tpPatExnTagTransducer applyFunction tppat1, 
                      tpPatExnTagTransducer applyFunction tppat2, 
                      loc) 

  and tpPatListExnTagTransducer applyFunction tppatList =
      map (tpPatExnTagTransducer applyFunction) tppatList
      
  and tpDecExnTagTransducer applyFunction accumMerge defaultAccumValue (tpdec : tpdecl) =
      case tpdec of
          TPVAL (valIdTpexpList, loc) =>
          let
              val (newValIdTpexpList, accum) = 
                  foldl (fn ((valId, tpexp), (newValIdTpexpList, accum')) => 
                            let
                                val (newTpexp, accum) =
                                    tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue tpexp
                            in
                                (newValIdTpexpList @ [(valId, newTpexp)],
                                 accumMerge (accum, accum'))
                            end)
                        (nil, defaultAccumValue)
                        valIdTpexpList
          in
              (TPVAL (newValIdTpexpList, loc), accum)
          end
        | TPFUNDECL (funDecList, loc) =>
          let
              val (newFunDecList, accum) =
                  foldl (fn ({funVar, argTyList, bodyTy, ruleList}, (newFunDecList, accum)) =>
                            let
                                val (newRuleList, accum') = 
                                    foldl (fn ((tppatList, tpexp), (newRuleList, accum'')) =>
                                              let
                                                  val (newTpexp, accum''') =
                                                      tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue tpexp
                                              in
                                                  (newRuleList @ [(tpPatListExnTagTransducer applyFunction tppatList,
                                                                   newTpexp)],
                                                   accumMerge(accum'', accum'''))
                                              end)
                                          (nil, defaultAccumValue)
                                          ruleList
                            in
                                (
                                 newFunDecList @ [{funVar = funVar, 
                                                   argTyList = argTyList, 
                                                   bodyTy = bodyTy, 
                                                   ruleList = newRuleList}],
                                 accumMerge(accum', accum)
                                )
                            end)
                        (nil, defaultAccumValue)
                        funDecList
          in
              (TPFUNDECL (newFunDecList, loc), accum)
          end
        | TPVALREC (decs, loc) =>
          let
              val (newDecs, accum) = 
                  foldl (fn ({var, expTy, exp}, (newDecs, accum)) =>
                            let
                                val (newTpexp, accum') =
                                    tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue exp
                            in
                                (newDecs @ [{var = var,
                                             expTy = expTy,
                                             exp = newTpexp}],
                                 accumMerge(accum, accum'))
                            end)
                        (nil, defaultAccumValue)
                        decs
          in
              (TPVALREC (newDecs, loc), accum)
          end
        | TPVALRECGROUP (nameList, decs, loc) =>
          let
              val (newDecs, accum) = 
                  tpDecListExnTagTransducer applyFunction accumMerge defaultAccumValue decs
          in
              (TPVALRECGROUP (nameList, newDecs, loc), accum)
          end
        | TPPOLYFUNDECL (btvEnv, funDecs, loc) =>
          let
              val (newFunDecs, accum) = 
                  foldl (fn ({funVar, argTyList, bodyTy, ruleList}, (newFunDecs, accum')) =>
                            let
                                val (newRuleList, accum'') =
                                    foldl (fn ((tppatList, tpexp), (newRuleList, accum'')) =>
                                              let
                                                  val newTppatList =
                                                      tpPatListExnTagTransducer applyFunction tppatList
                                                  val (newTpexp, accum''') =
                                                      tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue tpexp
                                              in
                                                  (newRuleList @ [(newTppatList, newTpexp)],
                                                   accumMerge(accum'', accum'''))
                                              end)
                                          (nil, defaultAccumValue)
                                          ruleList
                            in
                                (newFunDecs @ [{funVar = funVar, 
                                                argTyList = argTyList, 
                                                bodyTy = bodyTy, 
                                                ruleList = newRuleList}],
                                 accumMerge(accum'', accum'))
                            end)
                        (nil, defaultAccumValue)
                        funDecs
          in
              (TPPOLYFUNDECL (btvEnv, newFunDecs, loc), accum)
          end
        | TPVALPOLYREC (btvEnv, fundecs, loc) =>
          let
              val (newFunDecs, accum) =
                  foldl (fn ({var, expTy, exp}, (newFunDecs, accum)) =>
                            let
                                val (newTpexp, accum') = 
                                    tpExpExnTagTransducer applyFunction accumMerge defaultAccumValue exp
                            in
                                (newFunDecs @ [{var = var, expTy = expTy, exp = newTpexp}],
                                 accumMerge(accum', accum))
                            end)
                        (nil, defaultAccumValue)
                        fundecs
          in
              (TPVALPOLYREC (btvEnv, newFunDecs, loc), accum)
          end
        | TPLOCALDEC ( tpdecs1, tpdecs2, loc) =>
          let
              val (newTpDecs1, accum1) =
                  tpDecListExnTagTransducer applyFunction accumMerge defaultAccumValue tpdecs1
              val (newTpDecs2, accum2) =
                  tpDecListExnTagTransducer applyFunction accumMerge defaultAccumValue tpdecs2
          in
              (TPLOCALDEC (newTpDecs1, newTpDecs2, loc),
               accumMerge(accum1, accum2))
          end
        | TPINTRO x => (TPINTRO x, defaultAccumValue)
        | TPTYPE x =>  (TPTYPE x, defaultAccumValue)
        | TPDATADEC x =>  (TPDATADEC x, defaultAccumValue)
        | TPABSDEC ({absDataTyInfos, rawDataTyInfos, decls}, loc) =>
          let
              val (newTpDecs1, accum) =
                  tpDecListExnTagTransducer applyFunction accumMerge defaultAccumValue decls
          in
              (TPABSDEC ({absDataTyInfos = absDataTyInfos, 
                          rawDataTyInfos = rawDataTyInfos, 
                          decls = newTpDecs1}, 
                         loc),
               accum)
          end
        | TPDATAREPDEC x => (TPDATAREPDEC x, defaultAccumValue)
        | TPEXNDEC (tpexnbinds, loc) =>
          let
              val (newTpexnbinds, accum) =
                  foldl (fn (tpexnbind, (newTpexnbinds, accum)) =>
                            case tpexnbind of
                                TPEXNBINDDEF {namePath, funtyCon, ty, tag, tyCon} =>
                                (newTpexnbinds @ [TPEXNBINDDEF {namePath = namePath, 
                                                                funtyCon = funtyCon, 
                                                                ty = ty, 
                                                                tag = applyFunction tag, 
                                                                tyCon = tyCon}
                                                 ],
                                 accumMerge (ExnTagID.Set.singleton tag, accum)
                                )
                              | _ => (newTpexnbinds @ [tpexnbind], accum))
                        (nil, defaultAccumValue)
                        tpexnbinds
          in
              (TPEXNDEC(newTpexnbinds, loc), accum)
          end
        | TPINFIXDEC x =>  (TPINFIXDEC x, defaultAccumValue)
        | TPINFIXRDEC x => (TPINFIXRDEC x, defaultAccumValue)
        | TPNONFIXDEC x => (TPNONFIXDEC x, defaultAccumValue)
        | TPREPLICATETYPE x => (TPREPLICATETYPE x, defaultAccumValue)

  and tpDecListExnTagTransducer applyFunction accumMerge defaultAccumValue decs =
      foldl (fn (dec, (newDecs, accum)) =>
                let
                    val (newDec, accum') =
                        tpDecExnTagTransducer applyFunction accumMerge defaultAccumValue dec
                in
                    (newDecs @ [newDec],
                     accumMerge(accum, accum'))
                end)
            (nil, defaultAccumValue)
            decs


  fun tpStrDecListExnTagTransducer applyFunction accumMerge defaultAccumValue strDecs =
      foldl (fn (strDec, (newStrDecs, accum)) =>
                let
                    val (newStrDec, accum') =
                        tpStrDecExnTagTransducer applyFunction accumMerge defaultAccumValue strDec
                in
                    (newStrDecs @ [newStrDec],
                     accumMerge(accum, accum'))
                end)
            (nil, defaultAccumValue)
            strDecs

  and tpStrDecExnTagTransducer applyFunction accumMerge defaultAccumValue strDec =
      case strDec of
          TPCOREDEC (tpdecs, loc) =>
          let
              val (newtpdecs,accum) =
                  foldl (fn (tpdec, (newtpdecs,accum)) =>
                            let
                                val (newtpdec, accum') =
                                    tpDecExnTagTransducer applyFunction accumMerge defaultAccumValue tpdec
                            in
                                (newtpdecs @ [newtpdec],
                                 accumMerge(accum', accum))
                            end)
                        (nil, defaultAccumValue)
                        tpdecs
          in (TPCOREDEC (newtpdecs, loc), accum) end
        | TPCONSTRAINT (tpstrdecs, nameEnv, loc) =>
          let
              val (newtpstrdecs, accum) = 
                  tpStrDecListExnTagTransducer applyFunction accumMerge defaultAccumValue tpstrdecs
          in
              (TPCONSTRAINT (newtpstrdecs, nameEnv, loc), accum)
          end
        | TPFUNCTORAPP {prefix, funBindInfo, argNameMapInfo,
                        exnTagResolutionTable,
                        refreshedExceptionTagTable,
                        typeResolutionTable,
                        loc} =>
          let
              val newExnTagResolutionTable =
                  ExnTagID.Map.map (fn actualTag => applyFunction actualTag) 
                                   exnTagResolutionTable
              val newRefreshedExceptionTagTable =
                  ExnTagID.Map.map (fn actualTag => applyFunction actualTag) 
                                   refreshedExceptionTagTable
              (* The generative exception tags are treatedly like exception declaration,
               * that is, these tags nees to be collected in the accumulation.
               *)
              val generativeExnTagSet = 
                  ExnTagID.Map.foldl (fn (exnTag, exnTagSet) =>
                                         ExnTagID.Set.add(exnTagSet,exnTag))
                                     ExnTagID.Set.empty
                                     refreshedExceptionTagTable
          in
              (TPFUNCTORAPP {prefix = prefix, 
                             funBindInfo = funBindInfo, 
                             argNameMapInfo = argNameMapInfo,
                             exnTagResolutionTable = newExnTagResolutionTable,
                             refreshedExceptionTagTable = newRefreshedExceptionTagTable,
                             typeResolutionTable = typeResolutionTable,
                             loc = loc},
               generativeExnTagSet)
          end
        | TPANDFLATTENED (printSigInfoTpstrdecsList, loc) =>
          let
              val (newPrintSigInfoTpstrdecsList, accum) =
                  foldl (fn ((printsigInfo, tpstrdecs), (newPrintSigInfoTpstrdecsList, accum')) =>
                            let
                                val (newtpstrdecs, accum) = 
                                    tpStrDecListExnTagTransducer applyFunction accumMerge defaultAccumValue tpstrdecs
                            in
                                (newPrintSigInfoTpstrdecsList @ [(printsigInfo, newtpstrdecs)],
                                 accumMerge(accum, accum'))
                            end)
                        (nil, defaultAccumValue)
                        printSigInfoTpstrdecsList
          in
              (TPANDFLATTENED (newPrintSigInfoTpstrdecsList, loc), accum)
          end
        | TPSTRLOCAL (tpstrdecs1, tpstrdecs2, loc) =>
          let
              val (newtpstrdecs1, accum1) = 
                  tpStrDecListExnTagTransducer applyFunction accumMerge defaultAccumValue tpstrdecs1
              val (newtpstrdecs2, accum2) = 
                  tpStrDecListExnTagTransducer applyFunction accumMerge defaultAccumValue tpstrdecs2
          in
              (TPSTRLOCAL (newtpstrdecs1, newtpstrdecs2, loc),
               accumMerge(accum1, accum2))
          end

  fun tpTopDecExnTagTransducer applyFunction accumMerge defaultAccumValue topDec =
      case topDec of
          TPDECSTR (tpstrdecs, loc) =>
          let
              val (newtpstrdecs,accum) =
                  foldl (fn (tpstrdec, (newtpstrdecs,accum)) =>
                            let
                                val (newTpstrdec, accum') =
                                    tpStrDecExnTagTransducer applyFunction accumMerge defaultAccumValue tpstrdec
                            in
                                (newtpstrdecs @ [newTpstrdec],
                                 accumMerge(accum', accum))
                            end)
                        (nil, defaultAccumValue)
                        tpstrdecs
          in (TPDECSTR (newtpstrdecs, loc), accum) end
        | TPDECSIG _ => (topDec, defaultAccumValue)
        | TPDECFUN _ => (topDec, defaultAccumValue)

  fun tpTopDecListExnTagTransducer applyFunction accumMerge defaultAccumValue topDecs =
      foldl (fn (topDec, (newTopDecs, accum)) =>
                let
                    val (newTopDec, accum') =
                        tpTopDecExnTagTransducer applyFunction accumMerge defaultAccumValue topDec
                in
                    (newTopDecs @ [topDec],
                     accumMerge (accum', accum))
                end)
            (nil, defaultAccumValue)
            topDecs
            
  fun collectExnTagSetStrDecList strDecs =
      let
          val applyFunction = fn x => x
          val accumMerge = fn setPair => ExnTagID.Set.union setPair
          val defaultAccumValue = ExnTagID.Set.empty
          val (strdecs, exnTagIDSet) =
              tpStrDecListExnTagTransducer applyFunction  accumMerge defaultAccumValue strDecs
      in
          exnTagIDSet
      end

  fun substExnTagTopDecList exnTagSubst topDecs =
      let
          val applyFunction = 
           fn oldTagID => case ExnTagID.Map.find(exnTagSubst, oldTagID) of
                              NONE => oldTagID
                            | SOME newTagID => newTagID
          val defaultAccumValue = ExnTagID.Set.empty
          val accumMerge = fn (x, y) => defaultAccumValue
          val (topDecs, exnTagIDSet) = 
              tpTopDecListExnTagTransducer applyFunction accumMerge defaultAccumValue topDecs
      in
          topDecs
      end
end
end
