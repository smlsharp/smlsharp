(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 *)
structure UncurryFundecl : UNCURRYFUNDECL = struct
local

 (* for debugging *)
  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")

  structure T = Types
  open Types
  open TypedCalc
  structure TIU = TypeInferenceUtils

  fun grabTy (ty, arity) =
    let
      fun grab 0 ty tyList = (tyList, ty)
        | grab n ty tyList = 
            (case TypesUtils.derefTy ty of
               (FUNMty([domty], ranty)) =>
                 grab (n - 1) ranty (tyList@[domty])
              | _ => 
                 (
                  printType ty;
                  raise Control.Bug "grabTy"
                  )
             )
    in
      grab arity ty nil
    end

  fun grabAndApply 
    (*
     * funbody should be a fun id whose type has already been 
     * converted to uncurried one.
     * spine : (A,a -> b -> c -> d)::(B,b -> c -> d)::(C,c -> d)
     * funBody this should be of type  (a -> b -> c -> d)
     *)
          (funbody, 
           argTyList, 
           bodyTy, 
           spine, 
           loc) = 
    let
      fun take 0 L = (nil, L)
        | take n (h::t) = 
          let
            val (L1, L2) = take (n - 1) t 
          in
            (h::L1, L2) 
          end
        | take n nil = raise Control.Bug "take from nil (typeinference/main/UncurryFundecl.sml)"
      fun makeVar ty = 
          let 
            val newName = Counters.newVarName ()
            val varPathInfo = {namePath = (newName,Path.NilPath), ty =  ty}
          in 
            varPathInfo
          end
      val existingArgNum = length spine
      val arity = length argTyList
    in
      if arity > existingArgNum then
        let
          val newVars = map makeVar (List.drop (argTyList, existingArgNum))
        in
          #2
          (foldr 
           (fn (var as {ty,...}, (bodyTy, bodyExp)) => 
            (FUNMty([ty], bodyTy),
             TPFNM {argVarList = [var],
                    bodyTy = bodyTy,
                    bodyExp = bodyExp,
                    loc = loc}
            )
            )
           (bodyTy,
            TPAPPM {funExp =funbody, 
                    funTy = FUNMty (argTyList, bodyTy),
                    argExpList = (map #1 spine @ (map (fn v => TPVAR(v,loc)) newVars)), 
                    loc = loc}
            )
           newVars
           )
        end
      else
        let
          val (argsToFun, remainingArgs) = take arity spine
        in
           foldl 
            (fn ((exp, funty), funbody) => 
                 TPAPPM{funExp = funbody, 
                        funTy = funty,
                        argExpList = [exp],
                        loc = loc}
            )
            (case argsToFun of
                 nil => funbody
               | _ => 
                   TPAPPM 
                   {funExp = funbody, 
                    funTy = FUNMty (argTyList, bodyTy),
                    argExpList = map #1 argsToFun,
                    loc=loc})
            remainingArgs
        end
    end

  fun makeApply  (funbody, spine, loc) = 
      foldl 
       (fn ((exp, funty), funbody) => 
        TPAPPM{funExp = funbody, 
               funTy = funty,
               argExpList = [exp],
               loc = loc}
        )
       funbody
       spine
in

  val dummyTy = TIU.nextDummyTy ()

  fun matchToFnCaseTerm  loc {ruleList = nil,...} =
      raise Control.Bug "empty rule in matchToFnCaseTerm  (typeinference/main/UncurryFundecl.sml)"
    | matchToFnCaseTerm  loc {
                             funVar as {namePath = funNamePath,...}, 
                             argTyList, 
                             bodyTy, 
                             ruleList = ruleList as (patList, exp)::_
                             }
    =
    let
      val (newVars, newPats) = 
        foldr 
        (fn (ty, (newVars, newPats)) => 
         let 
           val newName = Counters.newVarName ()
           val varPathInfo = {namePath = (newName, Path.NilPath),
                              ty = ty}
         in
           (
            varPathInfo::newVars,
            TPPATVAR (varPathInfo, loc)::newPats
            )
         end
         )
        (nil,nil)
        argTyList
        val newTy = FUNMty(argTyList, bodyTy)
    in
      ({namePath = funNamePath, ty =newTy},
       newTy,
       TPFNM {argVarList = newVars,
              bodyTy = bodyTy,
              loc = loc,
              bodyExp =
              TPCASEM {expList = map (fn v => TPVAR(v, loc)) newVars,
                       expTyList = argTyList,
                       ruleList = 
                         map 
                         (fn (patList, exp) => (patList, uncurryExp  nil exp))
                         ruleList,
                       ruleBodyTy = bodyTy,
                       caseKind = PatternCalc.MATCH,
                       loc = loc}
              }
       )
    end

  and uncurryExp spine tpexp = 
    case tpexp of
      TPFOREIGNAPPLY {loc,...} => makeApply (tpexp, spine, loc)
    | TPEXPORTCALLBACK {loc,...} => makeApply (tpexp, spine, loc)
    | TPSIZEOF (_,loc) => makeApply (tpexp, spine, loc)
    | TPERROR => tpexp
    | TPCONSTANT (_, _, loc) => makeApply(tpexp, spine, loc)
    | TPGLOBALSYMBOL (_, _, _, loc) => makeApply(tpexp, spine, loc)
    | TPVAR (_,loc) => makeApply (tpexp, spine, loc)
    | 
      (*
       * grab the arity amount of argument from the spine stack and make 
       * an uncurried application.
       * If the spine does not contain enough arguments, then we perfrom 
       * eta-expansion.
       * If the size of the spine is larger than arity then 
       * we re-construct applications, i.e. uncurrying is performed 
       * only for statically know function indicated by TPRECFUNVAR.
       *)
        TPRECFUNVAR {var={namePath, ty}, arity, loc} =>
          (
           case (TypesUtils.derefTy ty, spine) of
            (polyty as POLYty {boundtvars, body}, nil) =>
            (* this should be the case 
                 val f = f 
               where f is an uncurried polymorphic function.
               In this case we do 
                  typeinstantiation
                  make a nested fun
                  type generalization
            *)
            let
              val (subst, boundtvars) = 
                  TypesUtils.copyBoundEnv boundtvars
              val body = TypesUtils.substBTvar subst body
              val (argTyList, newBodyTy) = grabTy (body, arity)
              val newPoyTyBody = FUNMty(argTyList, newBodyTy)
              val newPolyTy =
                POLYty{boundtvars = boundtvars, body = newPoyTyBody}
              val newPolyTtermBody =
                grabAndApply 
                    (TPTAPP{exp = TPVAR ({namePath = namePath, ty=newPolyTy}, loc),
                            expTy = newPolyTy,
                            instTyList = map BOUNDVARty (IEnv.listKeys boundtvars),
                            loc = loc},
                     argTyList, 
                     newBodyTy,
                     spine, 
                     loc)
            in
              TPPOLY{btvEnv =boundtvars,
                     expTyWithoutTAbs = newPoyTyBody,
                     exp = newPolyTtermBody,
                     loc = loc
                     }
            end
          | (POLYty {boundtvars, body}, x::_) => raise Control.Bug "polymorphic uncurried function with non nil spine"
          | _ => 
            (
             let
               val (argTyList, bodyTy) = grabTy (ty, arity)
             in
               grabAndApply 
                            (TPVAR ({namePath = namePath, ty= FUNMty(argTyList, bodyTy)},
                                    loc), 
                             argTyList, 
                             bodyTy,
                             spine, 
                             loc)
             end
             handle x => raise x
               )
            )
     | TPTAPP {exp = TPRECFUNVAR {var={namePath, ty}, arity, loc=loc1}, expTy, instTyList, loc=loc2} =>
       (
          let
            val instTy = TypesUtils.tpappTy(expTy, instTyList)
            val (argTyList, bodyTy) = grabTy (instTy, arity)
            val newPolyTy =
              case TypesUtils.derefTy ty of 
                POLYty{boundtvars, body} =>
                  POLYty{boundtvars = boundtvars, body = FUNMty(grabTy(body, arity))}
              | _ => raise Control.Bug "non function type in TPRECFUNVAR"
          in
            grabAndApply 
                
                (TPTAPP {exp = TPVAR ({namePath = namePath, ty=newPolyTy},loc1), 
                         expTy=newPolyTy, 
                         instTyList=instTyList, 
                         loc=loc2},
                 argTyList, 
                 bodyTy,
                 spine, 
                 loc2)
          end
        handle x => raise x
        )
    | TPPRIMAPPLY {primOp, instTyList, argExpOpt = SOME exp, loc} => 
       let
         val newTpexp = TPPRIMAPPLY {primOp=primOp, 
                                     instTyList=instTyList, 
                                     argExpOpt = SOME (uncurryExp nil exp), 
                                     loc = loc}
       in
         makeApply (newTpexp, spine, loc)
       end
    | TPPRIMAPPLY {argExpOpt = NONE, loc,...} => 
       makeApply (tpexp, spine, loc)
    | TPOPRIMAPPLY {oprimOp, instances, argExpOpt = SOME exp, loc} => 
       let
         val newTpexp = TPOPRIMAPPLY {oprimOp=oprimOp, 
                                     instances=instances, 
                                     argExpOpt = SOME (uncurryExp nil exp), 
                                     loc = loc}
       in
         makeApply (newTpexp, spine, loc)
       end
    | TPOPRIMAPPLY {argExpOpt = NONE, loc,...} => 
       makeApply (tpexp, spine, loc)
    | TPDATACONSTRUCT {con, instTyList, argExpOpt = SOME exp, loc} =>
       let
         val newTpexp = TPDATACONSTRUCT {con=con, 
                                     instTyList=instTyList, 
                                     argExpOpt = SOME (uncurryExp nil exp), 
                                     loc = loc}
       in
         makeApply (newTpexp, spine, loc)
       end
    | TPDATACONSTRUCT {con, instTyList, argExpOpt = NONE, loc} =>
       makeApply (tpexp, spine, loc)
    | TPEXNCONSTRUCT {exn, instTyList, argExpOpt = SOME exp, loc} =>
       let
           val newTpexp = TPEXNCONSTRUCT {exn=exn, 
                                          instTyList=instTyList, 
                                          argExpOpt = SOME (uncurryExp nil exp), 
                                          loc = loc}
       in
         makeApply (newTpexp, spine, loc)
       end
    | TPEXNCONSTRUCT {exn, instTyList, argExpOpt = NONE, loc} =>
      makeApply (tpexp, spine, loc)
    | TPAPPM {funExp, funTy, argExpList = [argExp], loc} =>
        let
          val newArgExp = uncurryExp nil argExp
        in
          uncurryExp ((newArgExp, funTy)::spine) funExp
        end
    | 
     (*
      * We only uncurry single argument functions.
      * This case should not happen for the current system, 
      * but in future we may allow uncurried user functions.
      *)
      TPAPPM {funExp, funTy, argExpList, loc} =>
        let
          val newFunExp = uncurryExp nil funExp
          val newArgExpList = map (uncurryExp nil) argExpList
        in
          makeApply (TPAPPM{funExp = newFunExp, 
                            funTy = funTy, 
                            argExpList = newArgExpList, 
                            loc = loc},
                     spine,
                     loc)
        end
    | TPMONOLET {binds, bodyExp, loc} =>
        let
          val newBinds = map (fn (v,exp) => (v, uncurryExp  nil exp))binds
          val newBodyExp = uncurryExp  nil bodyExp
        in
          makeApply(TPMONOLET {binds=newBinds, bodyExp=newBodyExp, loc=loc},
                    spine,
                    loc)
        end
    | TPLET (tpdeclList, tpexpList, tyList,loc) =>
        let
          val newTpdeclList = uncurryDeclList  false tpdeclList
          val newTpexplist = map (uncurryExp  nil) tpexpList
        in
          makeApply(TPLET (newTpdeclList, newTpexplist, tyList, loc),
                    spine,
                    loc)
        end
    | TPRECORD {fields, recordTy, loc} =>
        let
          val newFields = SEnv.map (uncurryExp  nil) fields
        in
          makeApply(TPRECORD {fields = newFields, recordTy = recordTy, loc=loc},
                    spine,
                    loc)
        end
    | TPSELECT {label, exp, expTy, resultTy, loc} =>
        let
          val newExp = uncurryExp  nil exp
        in
          makeApply(TPSELECT {label = label, 
                              exp = newExp, 
                              expTy = expTy, 
                              resultTy = resultTy,
                              loc = loc},
                    spine,
                    loc)
        end
    | TPMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
        let
          val newRecordExp = uncurryExp  nil recordExp
          val newElementExp = uncurryExp  nil elementExp
        in
          makeApply(TPMODIFY {label = label, 
                              recordExp = newRecordExp, 
                              recordTy = recordTy, 
                              elementExp = newElementExp,
                              elementTy = elementTy,
                              loc = loc},
                    spine,
                    loc)
        end
    | TPRAISE (tpexp,ty,loc) =>
        makeApply(TPRAISE(uncurryExp  nil tpexp, ty,loc),
                  spine,
                  loc)
    | TPHANDLE {exp, exnVar, handler, loc} =>
        let
          val newExp = uncurryExp  nil exp
          val newHandler = uncurryExp  nil handler
        in
          makeApply(TPHANDLE {exp = newExp, 
                              exnVar = exnVar, 
                              handler = newHandler, 
                              loc = loc},
                    spine,
                    loc)
        end
    | TPCASEM {expList, expTyList, ruleList, ruleBodyTy, caseKind, loc} =>
        let
          val newExpList = map (uncurryExp  nil) expList
          val newRuleList = map (fn (patList, exp) => (patList, uncurryExp  nil exp)) ruleList
        in
          makeApply(TPCASEM {expList = newExpList, 
                             expTyList = expTyList, 
                             ruleList = newRuleList, 
                             ruleBodyTy = ruleBodyTy,
                             caseKind = caseKind,
                             loc = loc},
                    spine,
                    loc)
        end
    | TPFNM {argVarList, bodyTy, bodyExp, loc} =>
        let
          val newBodyExp = uncurryExp  nil bodyExp
        in
          makeApply(TPFNM {argVarList = argVarList, 
                           bodyTy = bodyTy, 
                           bodyExp = newBodyExp, 
                           loc = loc},
                    spine,
                    loc)
        end
    | TPPOLYFNM
       {
        btvEnv,
        argVarList,
        bodyTy,
        bodyExp,
        loc
        }
       =>
        let
          val newBodyExp = uncurryExp  nil bodyExp
        in
          makeApply(TPPOLYFNM {
                               btvEnv = btvEnv,
                               argVarList = argVarList,
                               bodyTy = bodyTy,
                               bodyExp = newBodyExp,
                               loc = loc},
                    spine,
                    loc)
        end
     | TPPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
        let
          val newExp = uncurryExp  nil exp
        in
          makeApply(TPPOLY {btvEnv=btvEnv, 
                            expTyWithoutTAbs = expTyWithoutTAbs, 
                            exp = newExp, 
                            loc = loc},
                    spine,
                    loc)
        end
     | TPTAPP {exp, expTy, instTyList, loc} =>
        let
          val newExp = uncurryExp  nil exp
        in
          makeApply(TPTAPP {exp=newExp, 
                            expTy = expTy, 
                            instTyList = instTyList, 
                            loc = loc},
                    spine,
                    loc)
        end
     | TPLIST {expList, listTy, loc} =>
        let
          val newExpList = map (uncurryExp  nil) expList
        in
          makeApply(TPLIST {expList=newExpList, 
                           listTy = listTy, 
                           loc = loc},
                    spine,
                    loc)
        end
     | TPSEQ {expList, expTyList, loc} =>
        let
          val newExpList = map (uncurryExp nil) expList
        in
          makeApply(TPSEQ {expList=newExpList, 
                           expTyList = expTyList, 
                           loc = loc},
                    spine,
                    loc)
        end
     | TPCAST (tpexp, ty, loc) =>
        makeApply(TPCAST(uncurryExp nil tpexp, ty, loc),
                  spine,
                  loc)

  and uncurryDecl isTop tpdecl = 
    case tpdecl of
      TPVAL (valIdTpexpList, loc) => 
        [TPVAL(map (fn (id,exp) => (id, uncurryExp  nil exp)) valIdTpexpList,
              loc)]
    | TPFUNDECL (fundecls, loc) =>
        if isTop then
          let
            val curriedFunBinds =
              foldr (fn ({funVar = {namePath, ty},
                          argTyList,
                          bodyTy,
                          ruleList
                          },
                         curriedFunBinds) =>
                     if length argTyList = 1 then
                       curriedFunBinds
                     else 
                       (
                        VALIDVAR {namePath = namePath, ty = ty},
                        grabAndApply 
                                     (TPVAR({namePath = namePath, 
                                             ty = FUNMty(argTyList, bodyTy)
                                            }, loc), 
                                      argTyList,
                                      bodyTy,
                                      nil,
                                      loc)
                        )
                       ::curriedFunBinds
                       )
              nil
              fundecls
          in
            case curriedFunBinds of
              nil => [TPVALREC (map (fn (var, ty, exp) => {var=var,exp=exp, expTy = ty})
                             (map (matchToFnCaseTerm   loc) fundecls),
                             loc)]
            | _ => [TPVALREC (map (fn (var, ty, exp) => {var=var,exp=exp, expTy = ty})
                           (map (matchToFnCaseTerm  loc) fundecls),
                           loc),
                    TPVAL (curriedFunBinds, loc)]
          end
        else [TPVALREC (map (fn (var, ty, exp) => {var=var,exp=exp, expTy = ty}) 
                     (map (matchToFnCaseTerm  loc) fundecls),
                     loc)]
(*
    | TPNONRECFUN ({
                    funVar = funVar as {name, ty,...}, 
                    argTyList, 
                    bodyTy, 
                    ruleList = ruleList as (patList, exp)::_
                    },
                   loc
                   ) =>
        let
          val newVars = 
            map (fn ty => 
                 {name = Vars.newTPVarName(),
                  strpath = NilPath,
                  ty = ty}
                 )
            argTyList
          val bodyTerm = 
            TPCASEM {expList = map (fn v => TPVAR(v,loc)) newVars,
                     expTyList = argTyList,
                     ruleList = 
                       map 
                       (fn (patList, exp) => (patList, uncurryExp  nil exp))
                       ruleList,
                     ruleBodyTy = bodyTy,
                     caseKind = MATCH,
                     loc = loc}
          val funTy  = foldr (fn (ty, bodyTy) => FUNMty ([ty], bodyTy)) argTyList,
          val (_, funTerm) = 
            foldr (fn (argVar as {ty,...}, (bodyTy, body)) => 
                   (
                    FUNMty([ty], bodyTy),
                    TPFNM {argVarList = [argVar],
                           bodyTy = bodyTy.
                           loc = loc,
                           bodyExp =body
                           }
                    )
                   )
            (bodyTy, bodyTerm)
            newVars
        in
          [
           TPVAL ([(VALIDVAR {name = name, ty = ty}, funTerm)], loc)
           ]
        end
*)
    | TPVALREC (bindList, loc) =>
        [TPVALREC (map (fn {var, expTy, exp} => {var=var, expTy=expTy, exp=uncurryExp  nil exp}) bindList, loc)]
    | TPVALRECGROUP (stringList, tpdeclList,loc) =>
        [TPVALRECGROUP (stringList, uncurryDeclList  isTop tpdeclList, loc)]
    | TPPOLYFUNDECL (btvEnv, fundecls, loc) =>
        if isTop then
          let
            val polydecls = [TPVALPOLYREC (btvEnv, 
                                           map (fn (v,ty,exp) => {exp=exp, expTy = ty, var = v})
                                            (map (matchToFnCaseTerm  loc) fundecls), 
                                            loc)]
            fun instantiateAndCurryFun {funVar = funVar as {namePath, ty}, 
                                        argTyList, 
                                        bodyTy, ruleList} =
                if length argTyList = 1 then
                  let
                    val polyFunTy = POLYty{boundtvars=btvEnv, body = ty}
                    val polyFunTerm = TPVAR({namePath = namePath, 
                                             ty = polyFunTy
                                             },
                                            loc)
                  in
                    (VALIDVAR {namePath = namePath, ty=polyFunTy},
                     polyFunTerm)
                  end
                else
                  let
                    val subst = 
                        TypesUtils.freshSubst  btvEnv
                    val instTyList = IEnv.listItems subst
                    val instArgTyList = map (TypesUtils.substBTvar subst) argTyList
                    val instBodyTy = TypesUtils.substBTvar subst bodyTy
                    val curriedFunTy = foldr (fn (ty, body) => FUNMty([ty], body)) instBodyTy instArgTyList
                    val unCurriedFunTy = FUNMty(instArgTyList, instBodyTy)
                    val polyFunTy = POLYty{boundtvars=btvEnv, body = unCurriedFunTy}
                    val polyFunTerm = TPVAR({namePath = namePath, 
                                             ty = polyFunTy},
                                            loc)
                    val unCurriedFunVar = 
                      TPTAPP{exp = polyFunTerm,
                             expTy = polyFunTy,
                             instTyList = instTyList,
                             loc = loc}
                    val newVars = 
                      map (fn ty => 
                           {namePath = (Counters.newVarName (), Path.NilPath),
                            ty = ty}
                           )
                      instArgTyList
                  val newBodyTerm = 
                    TPAPPM {argExpList = map (fn v => TPVAR(v,loc)) newVars,
                            funTy = unCurriedFunTy,
                            loc = loc,
                            funExp = unCurriedFunVar
                           }
                  val (_, funTerm) = 
                    foldr (fn (argVar as {ty,...}, (bodyTy, body)) => 
                           (
                            FUNMty([ty], bodyTy),
                            TPFNM {argVarList = [argVar],
                                   bodyTy = bodyTy,
                                   loc = loc,
                                   bodyExp = body
                                   }
                            )
                           )
                    (instBodyTy, newBodyTerm)
                    newVars
                  val {boundEnv = newBtvEnv,...} = 
                      TypesUtils.generalizer (curriedFunTy, T.toplevelDepth)
                  val _ =
                    map
                    (fn (TYVARty (r as ref(TVAR {recordKind = OVERLOADED (h :: tl), ...}))) => 
                           r := SUBSTITUTED h
                      | (TYVARty (r as ref (TVAR {recordKind=UNIV, ...}))) =>
                         let
                           val dummyty = TIU.nextDummyTy ()
                           
                         in
                           r := (SUBSTITUTED dummyty)
                         end
                       | (**** temporary fix of BUG 200 ***)
                         (TYVARty (r as ref (TVAR {recordKind=REC tySEnvMap, ...}))) =>
                             r := (SUBSTITUTED (RECORDty tySEnvMap))
                       | (TYVARty (r as ref (SUBSTITUTED _))) => ()
                       | _ => ()
                    )
                    instArgTyList
                in
                  (VALIDVAR {namePath = namePath, ty=POLYty{boundtvars=newBtvEnv, body = curriedFunTy}},
                   TPPOLY {btvEnv=newBtvEnv, 
                           expTyWithoutTAbs=curriedFunTy, 
                           exp=funTerm, 
                           loc=loc}
                   )
                end
            val outerBinds = map instantiateAndCurryFun fundecls
          in
            [TPLOCALDEC(polydecls,
                        [TPVAL(outerBinds,loc)],
                        loc)]
          end
        else [TPVALPOLYREC
              (btvEnv, 
               map (fn (v,ty,exp) => {var =v, exp = exp, expTy = ty})
                 (map (matchToFnCaseTerm  loc) fundecls),
               loc)]
    | TPVALPOLYREC (btvEnv, recBinds, loc) =>
        [
         TPVALPOLYREC (btvEnv, 
                       map (fn {var, expTy, exp} => {var=var, expTy = expTy, exp = uncurryExp  nil exp}) recBinds, 
                       loc) 
         ]
    | TPLOCALDEC (decl1, decl2, loc) =>
        [
         TPLOCALDEC (uncurryDeclList  false decl1, 
                     uncurryDeclList  isTop decl2, 
                     loc) 
         ]
    | TPINTRO _ => [tpdecl]
    | TPTYPE  _ => [tpdecl]
    | TPDATADEC _ => [tpdecl]
    | TPABSDEC ({absDataTyInfos, rawDataTyInfos, decls},loc) =>
        [
         TPABSDEC ({absDataTyInfos=absDataTyInfos, 
                    rawDataTyInfos=rawDataTyInfos, 
                    decls = uncurryDeclList  true decls
                    },
                   loc)
         ]
   | TPDATAREPDEC  _ => [tpdecl]
   | TPEXNDEC  _ => [tpdecl]
   | TPINFIXDEC  _ => [tpdecl]
   | TPINFIXRDEC _ => [tpdecl] 
   | TPNONFIXDEC _ => [tpdecl] 
   | TPREPLICATETYPE _ => [tpdecl]

  and uncurryDeclList  isTop pldeclList = 
    foldr (fn (decl, declList) => (uncurryDecl  isTop decl) @ declList)
    nil
    pldeclList

  and uncurryStrDeclList  pldeclList = 
    foldr (fn (decl, declList) => (uncurryStrDec  decl) @ declList)
    nil
    pldeclList

  and uncurryStrDec  strdec =
      case strdec of
          TPANDFLATTENED (decUnits, loc) =>
          [TPANDFLATTENED (map (fn (printSigExp, decs) => 
                                   (printSigExp, uncurryStrDeclList  decs))
                               decUnits, 
                               loc)]
        | TPCONSTRAINT (decs, specnamemap, loc) =>
          [TPCONSTRAINT (uncurryStrDeclList  decs, specnamemap, loc) ]
        | TPFUNCTORAPP _ => [strdec]
        | TPCOREDEC (decs, loc) => 
          [TPCOREDEC (uncurryDeclList  true decs, loc)]
        | TPSTRLOCAL(decs1, decs2, loc) =>
          [TPSTRLOCAL(uncurryStrDeclList  decs1, uncurryStrDeclList  decs2, loc)]

 and uncurryTopdec  topdec = 
    case topdec of
        TPDECSTR (decs, loc) => TPDECSTR (uncurryStrDeclList  decs, loc)
      | TPDECSIG _ => topdec
      | TPDECFUN (funBindInfoStringSigexpStrexpList, loc) =>
        TPDECFUN (map (fn ({funBindInfo, argName, argSpec, bodyDec = (decs, bodyNameMap, sigExpOpt)}) =>
                          {funBindInfo = funBindInfo, 
                           argName = argName, 
                           argSpec = argSpec,
                           bodyDec = (uncurryStrDeclList  decs, bodyNameMap, sigExpOpt)})
                      funBindInfoStringSigexpStrexpList, 
                  loc)
 and optimize (stamps : Counters.stamps) topdecList = 
     let
         val  _ = Counters.init stamps
         val decs = map uncurryTopdec topdecList
     in
         (Counters.getCountersStamps(), decs)
     end
end
end
