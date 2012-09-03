(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 *)
structure UncurryFundecl : UNCURRYFUNDECL = struct
local

 (* for debugging *)
  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")

  structure T = Types
  structure TP =TypedCalc
  structure TIU = TypeInferenceUtils

  fun grabTy (ty, arity) =
    let
      fun grab 0 ty tyList = (tyList, ty)
        | grab n ty tyList = 
            (case TypesUtils.derefTy ty of
               (T.FUNMty([domty], ranty)) =>
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

  fun grabAndApply (funbody, argTyList, bodyTy, spine, loc) = 
    (*
     * funbody should be a fun id whose type has already been 
     * converted to uncurried one.
     * spine : (A,a -> b -> c -> d)::(B,b -> c -> d)::(C,c -> d)
     * funBody this should be of type  (a -> b -> c -> d)
     *)
    let
      fun take 0 L = (nil, L)
        | take n (h::t) = 
          let
            val (L1, L2) = take (n - 1) t 
          in
            (h::L1, L2) 
          end
        | take n nil =
          raise
            Control.Bug
              "take from nil (typeinference/main/UncurryFundecl.sml)"
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
            (T.FUNMty([ty], bodyTy),
             TP.TPFNM {argVarList = [var],
                       bodyTy = bodyTy,
                       bodyExp = bodyExp,
                       loc = loc}
            )
            )
           (bodyTy,
            TP.TPAPPM
              {funExp =funbody, 
               funTy = T.FUNMty (argTyList, bodyTy),
               argExpList =
                 (map #1 spine @ (map (fn v => TP.TPVAR(v,loc)) newVars)), 
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
                 TP.TPAPPM{funExp = funbody, 
                           funTy = funty,
                           argExpList = [exp],
                           loc = loc}
            )
            (case argsToFun of
                 nil => funbody
               | _ => 
                   TP.TPAPPM 
                   {funExp = funbody, 
                    funTy = T.FUNMty (argTyList, bodyTy),
                    argExpList = map #1 argsToFun,
                    loc=loc})
            remainingArgs
        end
    end

  fun makeApply  (funbody, spine, loc) = 
      foldl 
       (fn ((exp, funty), funbody) => 
        TP.TPAPPM{funExp = funbody, 
                  funTy = funty,
                  argExpList = [exp],
                  loc = loc}
        )
       funbody
       spine
in

  val dummyTy = TIU.nextDummyTy ()

  fun matchToFnCaseTerm  loc {ruleList = nil,...} =
      raise
        Control.Bug
          "empty rule in matchToFnCaseTerm\
          \(typeinference/main/UncurryFundecl.sml)"
    | matchToFnCaseTerm  
        loc
        {
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
                     TP.TPPATVAR (varPathInfo, loc)::newPats
                    )
                  end
              )
              (nil,nil)
              argTyList
        val newTy = T.FUNMty(argTyList, bodyTy)
      in
        ({namePath = funNamePath, ty =newTy},
         newTy,
         TP.TPFNM {argVarList = newVars,
                   bodyTy = bodyTy,
                   loc = loc,
                   bodyExp =
                   TP.TPCASEM
                     {expList = map (fn v => TP.TPVAR(v, loc)) newVars,
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
      TP.TPFOREIGNAPPLY {loc,...} => makeApply (tpexp, spine, loc)
    | TP.TPEXPORTCALLBACK {loc,...} => makeApply (tpexp, spine, loc)
    | TP.TPSIZEOF (_,loc) => makeApply (tpexp, spine, loc)
    | TP.TPERROR => tpexp
    | TP.TPCONSTANT (_, _, loc) => makeApply(tpexp, spine, loc)
    | TP.TPGLOBALSYMBOL (_, _, _, loc) => makeApply(tpexp, spine, loc)
    | TP.TPVAR (_,loc) => makeApply (tpexp, spine, loc)
    | 
      (*
       * grab the arity amount of argument from the spine stack and make 
       * an uncurried application.
       * If the spine does not contain enough arguments, then we perfrom 
       * eta-expansion.
       * If the size of the spine is larger than arity then 
       * we re-construct applications, i.e. uncurrying is performed 
       * only for statically know function indicated by TP.TPRECFUNVAR.
       *)
      TP.TPRECFUNVAR {var={namePath, ty}, arity, loc} =>
      (
       case (TypesUtils.derefTy ty, spine) of
         (polyty as T.POLYty {boundtvars, body}, nil) =>
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
            val newPoyTyBody = T.FUNMty(argTyList, newBodyTy)
            val newPolyTy =
                T.POLYty{boundtvars = boundtvars, body = newPoyTyBody}
            val newPolyTtermBody =
                grabAndApply 
                  (TP.TPTAPP
                     {exp = TP.TPVAR ({namePath = namePath, ty=newPolyTy},
                                      loc),
                      expTy = newPolyTy,
                      instTyList =
                      map T.BOUNDVARty (IEnv.listKeys boundtvars),
                      loc = loc},
                   argTyList, 
                   newBodyTy,
                   spine, 
                   loc)
          in
            TP.TPPOLY{btvEnv =boundtvars,
                      expTyWithoutTAbs = newPoyTyBody,
                      exp = newPolyTtermBody,
                      loc = loc
                     }
          end
       | (T.POLYty {boundtvars, body}, x::_) =>
         raise
           Control.Bug "polymorphic uncurried function with non nil spine"
       | _ => 
         (
          let
            val (argTyList, bodyTy) = grabTy (ty, arity)
          in
            grabAndApply 
              (TP.TPVAR
                 ({namePath = namePath, ty= T.FUNMty(argTyList, bodyTy)},
                  loc), 
               argTyList, 
               bodyTy,
               spine, 
               loc)
          end
          handle x => raise x
         )
      )
    | TP.TPTAPP
        {exp = TP.TPRECFUNVAR {var={namePath, ty}, arity, loc=loc1},
         expTy,
         instTyList,
         loc=loc2} =>
      (
       let
         val instTy = TypesUtils.tpappTy(expTy, instTyList)
         val (argTyList, bodyTy) = grabTy (instTy, arity)
         val newPolyTy =
             case TypesUtils.derefTy ty of 
               T.POLYty{boundtvars, body} =>
               T.POLYty{boundtvars = boundtvars,
                        body = T.FUNMty(grabTy(body, arity))}
             | _ => raise Control.Bug "non function type in TP.TPRECFUNVAR"
       in
         grabAndApply 
           (TP.TPTAPP
              {exp = TP.TPVAR ({namePath = namePath, ty=newPolyTy},loc1), 
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
    | TP.TPPRIMAPPLY {primOp, instTyList, argExpOpt = SOME exp, loc} => 
      let
        val newTpexp = TP.TPPRIMAPPLY {primOp=primOp, 
                                       instTyList=instTyList, 
                                       argExpOpt = SOME (uncurryExp nil exp), 
                                       loc = loc}
       in
        makeApply (newTpexp, spine, loc)
      end
    | TP.TPPRIMAPPLY {argExpOpt = NONE, loc,...} => 
      makeApply (tpexp, spine, loc)
    | TP.TPOPRIMAPPLY
        {oprimOp, keyTyList, instances, argExpOpt = SOME exp, loc} => 
      let
        val newTpexp = TP.TPOPRIMAPPLY {oprimOp = oprimOp,
                                        keyTyList = keyTyList,
                                        instances = instances, 
                                        argExpOpt = SOME (uncurryExp nil exp), 
                                        loc = loc}
      in
        makeApply (newTpexp, spine, loc)
      end
    | TP.TPOPRIMAPPLY {argExpOpt = NONE, loc,...} => 
      makeApply (tpexp, spine, loc)
    | TP.TPDATACONSTRUCT {con, instTyList, argExpOpt = SOME exp, loc} =>
      let
        val newTpexp = TP.TPDATACONSTRUCT
                         {con=con, 
                          instTyList=instTyList, 
                          argExpOpt = SOME (uncurryExp nil exp), 
                          loc = loc}
      in
        makeApply (newTpexp, spine, loc)
      end
    | TP.TPDATACONSTRUCT {con, instTyList, argExpOpt = NONE, loc} =>
      makeApply (tpexp, spine, loc)
    | TP.TPEXNCONSTRUCT {exn, instTyList, argExpOpt = SOME exp, loc} =>
      let
        val newTpexp = TP.TPEXNCONSTRUCT
                         {exn=exn, 
                          instTyList=instTyList, 
                          argExpOpt = SOME (uncurryExp nil exp), 
                          loc = loc}
      in
         makeApply (newTpexp, spine, loc)
      end
    | TP.TPEXNCONSTRUCT {exn, instTyList, argExpOpt = NONE, loc} =>
      makeApply (tpexp, spine, loc)
    | TP.TPAPPM {funExp, funTy, argExpList = [argExp], loc} =>
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
      TP.TPAPPM {funExp, funTy, argExpList, loc} =>
      let
        val newFunExp = uncurryExp nil funExp
        val newArgExpList = map (uncurryExp nil) argExpList
      in
        makeApply (TP.TPAPPM{funExp = newFunExp, 
                             funTy = funTy, 
                             argExpList = newArgExpList, 
                             loc = loc},
                   spine,
                   loc)
      end
    | TP.TPMONOLET {binds, bodyExp, loc} =>
      let
        val newBinds = map (fn (v,exp) => (v, uncurryExp  nil exp))binds
        val newBodyExp = uncurryExp  nil bodyExp
      in
        makeApply(TP.TPMONOLET {binds=newBinds, bodyExp=newBodyExp, loc=loc},
                  spine,
                  loc)
      end
    | TP.TPLET (tpdeclList, tpexpList, tyList,loc) =>
      let
        val newTpdeclList = uncurryDeclList  false tpdeclList
        val newTpexplist = map (uncurryExp  nil) tpexpList
      in
        makeApply(TP.TPLET (newTpdeclList, newTpexplist, tyList, loc),
                  spine,
                  loc)
      end
    | TP.TPRECORD {fields, recordTy, loc} =>
      let
        val newFields = SEnv.map (uncurryExp  nil) fields
      in
        makeApply
          (TP.TPRECORD {fields = newFields, recordTy = recordTy, loc=loc},
           spine,
           loc)
      end
    | TP.TPSELECT {label, exp, expTy, resultTy, loc} =>
      let
        val newExp = uncurryExp  nil exp
      in
        makeApply(TP.TPSELECT {label = label, 
                               exp = newExp, 
                               expTy = expTy, 
                               resultTy = resultTy,
                               loc = loc},
                  spine,
                  loc)
      end
    | TP.TPMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
      let
        val newRecordExp = uncurryExp  nil recordExp
        val newElementExp = uncurryExp  nil elementExp
      in
        makeApply(TP.TPMODIFY {label = label, 
                               recordExp = newRecordExp, 
                               recordTy = recordTy, 
                               elementExp = newElementExp,
                               elementTy = elementTy,
                               loc = loc},
                  spine,
                  loc)
      end
    | TP.TPRAISE (tpexp,ty,loc) =>
      makeApply(TP.TPRAISE(uncurryExp  nil tpexp, ty,loc),
                spine,
                loc)
    | TP.TPHANDLE {exp, exnVar, handler, loc} =>
      let
        val newExp = uncurryExp  nil exp
        val newHandler = uncurryExp  nil handler
      in
        makeApply(TP.TPHANDLE {exp = newExp, 
                               exnVar = exnVar, 
                               handler = newHandler, 
                               loc = loc},
                  spine,
                  loc)
      end
    | TP.TPCASEM {expList, expTyList, ruleList, ruleBodyTy, caseKind, loc} =>
      let
        val newExpList = map (uncurryExp  nil) expList
        val newRuleList =
            map
              (fn (patList, exp) => (patList, uncurryExp  nil exp))
              ruleList
      in
        makeApply(TP.TPCASEM {expList = newExpList, 
                              expTyList = expTyList, 
                              ruleList = newRuleList, 
                              ruleBodyTy = ruleBodyTy,
                              caseKind = caseKind,
                              loc = loc},
                  spine,
                  loc)
      end
    | TP.TPFNM {argVarList, bodyTy, bodyExp, loc} =>
      let
        val newBodyExp = uncurryExp  nil bodyExp
      in
        makeApply(TP.TPFNM {argVarList = argVarList, 
                            bodyTy = bodyTy, 
                            bodyExp = newBodyExp, 
                            loc = loc},
                  spine,
                  loc)
      end
    | TP.TPPOLYFNM
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
        makeApply(TP.TPPOLYFNM
                    {
                     btvEnv = btvEnv,
                     argVarList = argVarList,
                     bodyTy = bodyTy,
                     bodyExp = newBodyExp,
                     loc = loc
                    },
                  spine,
                  loc)
        end
    | TP.TPPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
      let
        val newExp = uncurryExp  nil exp
      in
        makeApply(TP.TPPOLY {btvEnv=btvEnv, 
                             expTyWithoutTAbs = expTyWithoutTAbs, 
                             exp = newExp, 
                             loc = loc},
                  spine,
                  loc)
      end
    | TP.TPTAPP {exp, expTy, instTyList, loc} =>
      let
        val newExp = uncurryExp  nil exp
      in
        makeApply(TP.TPTAPP {exp=newExp, 
                             expTy = expTy, 
                             instTyList = instTyList, 
                             loc = loc},
                  spine,
                  loc)
      end
    | TP.TPLIST {expList, listTy, loc} =>
      let
        val newExpList = map (uncurryExp  nil) expList
      in
        makeApply(TP.TPLIST {expList=newExpList, 
                             listTy = listTy, 
                             loc = loc},
                  spine,
                  loc)
      end
    | TP.TPSEQ {expList, expTyList, loc} =>
      let
        val newExpList = map (uncurryExp nil) expList
      in
        makeApply(TP.TPSEQ {expList=newExpList, 
                            expTyList = expTyList, 
                            loc = loc},
                  spine,
                  loc)
      end
    | TP.TPCAST (tpexp, ty, loc) =>
      makeApply(TP.TPCAST(uncurryExp nil tpexp, ty, loc),
                spine,
                loc)
      
  and uncurryDecl isTop tpdecl = 
      case tpdecl of
        TP.TPVAL (valIdTpexpList, loc) => 
        [TP.TPVAL(map (fn (id,exp) => (id, uncurryExp  nil exp))
                      valIdTpexpList,
                  loc)]
      | TP.TPFUNDECL (fundecls, loc) =>
        if isTop then
          let
            val curriedFunBinds =
                foldr
                  (fn ({funVar = {namePath, ty},
                        argTyList,
                        bodyTy,
                        ruleList
                       },
                       curriedFunBinds) =>
                      if length argTyList = 1 then
                        curriedFunBinds
                      else 
                        (
                         T.VALIDVAR {namePath = namePath, ty = ty},
                         grabAndApply 
                           (TP.TPVAR({namePath = namePath, 
                                      ty = T.FUNMty(argTyList, bodyTy)
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
              nil => [TP.TPVALREC
                        (map
                           (fn (var, ty, exp) => {var=var,exp=exp, expTy = ty})
                           (map (matchToFnCaseTerm   loc) fundecls),
                         loc)]
            | _ => [TP.TPVALREC
                      (map (fn (var, ty, exp) => {var=var,exp=exp, expTy = ty})
                           (map (matchToFnCaseTerm  loc) fundecls),
                       loc),
                    TP.TPVAL (curriedFunBinds, loc)]
          end
        else [TP.TPVALREC
                (map (fn (var, ty, exp) => {var=var,exp=exp, expTy = ty}) 
                     (map (matchToFnCaseTerm  loc) fundecls),
                 loc)]
(*
    | TP.TPNONRECFUN ({
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
            TP.TPCASEM {expList = map (fn v => TP.TPVAR(v,loc)) newVars,
                     expTyList = argTyList,
                     ruleList = 
                       map 
                       (fn (patList, exp) => (patList, uncurryExp  nil exp))
                       ruleList,
                     ruleBodyTy = bodyTy,
                     caseKind = MATCH,
                     loc = loc}
          val funTy  =
              foldr (fn (ty, bodyTy) => T.FUNMty ([ty], bodyTy)) argTyList,
          val (_, funTerm) = 
            foldr (fn (argVar as {ty,...}, (bodyTy, body)) => 
                   (
                    T.FUNMty([ty], bodyTy),
                    TP.TPFNM {argVarList = [argVar],
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
           TP.TPVAL ([(T.VALIDVAR {name = name, ty = ty}, funTerm)], loc)
           ]
        end
*)
      | TP.TPVALREC (bindList, loc) =>
        [TP.TPVALREC
           (map (fn {var, expTy, exp} =>
                    {var=var, expTy=expTy, exp=uncurryExp  nil exp})
                bindList, loc)
        ]
      | TP.TPVALRECGROUP (stringList, tpdeclList,loc) =>
        [TP.TPVALRECGROUP (stringList, uncurryDeclList  isTop tpdeclList, loc)]
      | TP.TPPOLYFUNDECL (btvEnv, fundecls, loc) =>
        if isTop then
          let
            val polydecls =
                [TP.TPVALPOLYREC
                   (btvEnv, 
                    map (fn (v,ty,exp) => {exp=exp, expTy = ty, var = v})
                        (map (matchToFnCaseTerm  loc) fundecls), 
                    loc)]
            fun instantiateAndCurryFun {funVar = funVar as {namePath, ty}, 
                                        argTyList, 
                                        bodyTy, ruleList} =
                if length argTyList = 1 then
                  let
                    val polyFunTy = T.POLYty{boundtvars=btvEnv, body = ty}
                    val polyFunTerm = TP.TPVAR({namePath = namePath, 
                                                ty = polyFunTy
                                               },
                                               loc)
                  in
                    (T.VALIDVAR {namePath = namePath, ty=polyFunTy},
                     polyFunTerm)
                  end
                else
                  let
                    val subst = 
                        TypesUtils.freshSubst  btvEnv
                    val instTyList = IEnv.listItems subst
                    val instArgTyList =
                        map (TypesUtils.substBTvar subst) argTyList
                    val instBodyTy = TypesUtils.substBTvar subst bodyTy
                    val curriedFunTy =
                        foldr
                          (fn (ty, body) => T.FUNMty([ty], body))
                          instBodyTy
                          instArgTyList
                    val unCurriedFunTy = T.FUNMty(instArgTyList, instBodyTy)
                    val polyFunTy =
                        T.POLYty{boundtvars=btvEnv, body = unCurriedFunTy}
                    val polyFunTerm = TP.TPVAR({namePath = namePath, 
                                                ty = polyFunTy},
                                               loc)
                    val unCurriedFunVar = 
                        TP.TPTAPP{exp = polyFunTerm,
                                  expTy = polyFunTy,
                                  instTyList = instTyList,
                                  loc = loc}
                    val newVars = 
                        map
                          (fn ty => 
                              {namePath =
                                 (Counters.newVarName (), Path.NilPath),
                               ty = ty}
                          )
                          instArgTyList
                    val newBodyTerm = 
                        TP.TPAPPM
                          {argExpList = map (fn v => TP.TPVAR(v,loc)) newVars,
                           funTy = unCurriedFunTy,
                           loc = loc,
                           funExp = unCurriedFunVar
                          }
                    val (_, funTerm) = 
                      foldr
                        (fn (argVar as {ty,...}, (bodyTy, body)) => 
                            (
                             T.FUNMty([ty], bodyTy),
                             TP.TPFNM {argVarList = [argVar],
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
                          (fn 
                              (T.TYVARty
                                 (r
                                    as
                                    ref(T.TVAR
                                          {recordKind = T.OCONSTkind (h::_),
                                           ...}))
                              ) => 
                              r := T.SUBSTITUTED h
                            | (T.TYVARty
                                 (r
                                   as
                                   ref(T.TVAR
                                        {recordKind =
                                         T.OPRIMkind {instances =h::_,...},
                                         ...}))
                              ) =>
                              r := T.SUBSTITUTED h
                            | (T.TYVARty
                                 (r as
                                    ref (T.TVAR {recordKind=T.UNIV, ...}))) =>
                              let
                                val dummyty = TIU.nextDummyTy ()
                              in
                                r := (T.SUBSTITUTED dummyty)
                              end
                            | (**** temporary fix of BUG 200 ***)
                                (T.TYVARty
                                   (r as
                                      ref (T.TVAR
                                             {recordKind=T.REC tySEnvMap,
                                              ...})))
                              =>
                              r := (T.SUBSTITUTED (T.RECORDty tySEnvMap))
                            | (T.TYVARty (r as ref (T.SUBSTITUTED _))) => ()
                            | _ => ()
                          )
                          instArgTyList
                  in
                    (T.VALIDVAR
                       {namePath = namePath,
                        ty=T.POLYty
                          {boundtvars=newBtvEnv, body = curriedFunTy}},
                     TP.TPPOLY {btvEnv=newBtvEnv, 
                                expTyWithoutTAbs=curriedFunTy, 
                                exp=funTerm, 
                                loc=loc}
                    )
                  end
            val outerBinds = map instantiateAndCurryFun fundecls
          in
            [TP.TPLOCALDEC(polydecls,
                           [TP.TPVAL(outerBinds,loc)],
                           loc)]
          end
        else [TP.TPVALPOLYREC
                (btvEnv, 
                 map (fn (v,ty,exp) => {var =v, exp = exp, expTy = ty})
                     (map (matchToFnCaseTerm  loc) fundecls),
                 loc)]
      | TP.TPVALPOLYREC (btvEnv, recBinds, loc) =>
        [
         TP.TPVALPOLYREC
           (btvEnv, 
            map
              (fn {var, expTy, exp}
                  => {var=var, expTy = expTy, exp = uncurryExp  nil exp})
              recBinds, 
            loc) 
        ]
      | TP.TPLOCALDEC (decl1, decl2, loc) =>
        [
         TP.TPLOCALDEC (uncurryDeclList  false decl1, 
                        uncurryDeclList  isTop decl2, 
                        loc) 
        ]
      | TP.TPINTRO _ => [tpdecl]
      | TP.TPTYPE  _ => [tpdecl]
      | TP.TPDATADEC _ => [tpdecl]
      | TP.TPABSDEC ({absDataTyInfos, rawDataTyInfos, decls},loc) =>
        [
         TP.TPABSDEC ({absDataTyInfos=absDataTyInfos, 
                       rawDataTyInfos=rawDataTyInfos, 
                       decls = uncurryDeclList  true decls
                      },
                      loc)
        ]
      | TP.TPDATAREPDEC  _ => [tpdecl]
      | TP.TPEXNDEC  _ => [tpdecl]
      | TP.TPINFIXDEC  _ => [tpdecl]
      | TP.TPINFIXRDEC _ => [tpdecl] 
      | TP.TPNONFIXDEC _ => [tpdecl] 
      | TP.TPREPLICATETYPE _ => [tpdecl]

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
        TP.TPANDFLATTENED (decUnits, loc) =>
        [TP.TPANDFLATTENED (map (fn (printSigExp, decs) => 
                                    (printSigExp, uncurryStrDeclList  decs))
                                decUnits, 
                            loc)]
      | TP.TPCONSTRAINT (decs, specnamemap, loc) =>
        [TP.TPCONSTRAINT (uncurryStrDeclList  decs, specnamemap, loc) ]
      | TP.TPFUNCTORAPP _ => [strdec]
      | TP.TPCOREDEC (decs, loc) => 
        [TP.TPCOREDEC (uncurryDeclList  true decs, loc)]
      | TP.TPSTRLOCAL(decs1, decs2, loc) =>
        [TP.TPSTRLOCAL
           (uncurryStrDeclList  decs1, uncurryStrDeclList  decs2, loc)]
        
  and uncurryTopdec  topdec = 
      case topdec of
        TP.TPDECSTR (decs, loc) => TP.TPDECSTR (uncurryStrDeclList  decs, loc)
      | TP.TPDECSIG _ => topdec
      | TP.TPDECFUN (funBindInfoStringSigexpStrexpList, loc) =>
        TP.TPDECFUN
          (map
             (fn ({funBindInfo,
                   argName,
                   argSpec,
                   bodyDec = (decs, bodyNameMap, sigExpOpt)}
                 )
                 =>
                 {funBindInfo = funBindInfo, 
                  argName = argName, 
                  argSpec = argSpec,
                  bodyDec =
                  (uncurryStrDeclList  decs, bodyNameMap, sigExpOpt)})
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
