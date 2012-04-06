(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 *)
structure UncurryFundecl : UNCURRYFUNDECL = struct
local

  structure T = Types
  structure TU = TypesUtils
  structure TIU = TypeInferenceUtils
  structure TC = TypedCalc
  structure TCU = TypedCalcUtils

  fun makeVar ty = TCU.newTCVarInfo ty

  fun grabTy (ty, arity) =
    let
      fun grab 0 ty tyList = (tyList, ty)
        | grab n ty tyList = 
            (case TypesUtils.derefTy ty of
               (T.FUNMty([domty], ranty)) =>
                 grab (n - 1) ranty (tyList@[domty])
              | _ => 
                 (
                  T.printTy ty;
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
             TC.TPFNM {argVarList = [var],
                       bodyTy = bodyTy,
                       bodyExp = bodyExp,
                       loc = loc}
            )
            )
           (bodyTy,
            TC.TPAPPM
              {funExp =funbody, 
               funTy = T.FUNMty (argTyList, bodyTy),
               argExpList =
                 (map #1 spine @ (map (fn v => TC.TPVAR(v,loc)) newVars)), 
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
                 TC.TPAPPM{funExp = funbody, 
                           funTy = funty,
                           argExpList = [exp],
                           loc = loc}
            )
            (case argsToFun of
                 nil => funbody
               | _ => 
                   TC.TPAPPM 
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
           TC.TPAPPM{funExp=funbody, funTy=funty, argExpList=[exp],loc=loc}
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
         funVarInfo as {path=funPath,id=funId,...}, 
         argTyList, 
         bodyTy, 
         ruleList = ruleList as _::_
        }
      =
      let
        val (newVars, newPats) = 
            foldr 
              (fn (ty, (newVars, newPats)) => 
                  let 
                    val varInfo = makeVar ty
                  in
                    (
                     varInfo::newVars,
                     TC.TPPATVAR (varInfo, loc)::newPats
                    )
                  end
              )
              (nil,nil)
              argTyList
        val newTy = T.FUNMty(argTyList, bodyTy)
      in
        ({path=funPath, id=funId, ty =newTy},
         newTy,
         TC.TPFNM {argVarList = newVars,
                   bodyTy = bodyTy,
                   loc = loc,
                   bodyExp =
                   TC.TPCASEM
                     {expList = map (fn v => TC.TPVAR(v, loc)) newVars,
                      expTyList = argTyList,
                      ruleList = 
                        map 
                        (fn {args,body}=>{args=args,body=uncurryExp  nil body})
                        ruleList,
                      ruleBodyTy = bodyTy,
                      caseKind = PatternCalc.MATCH,
                      loc = loc}
                  }
        )
      end

  and uncurryExp spine tpexp = 
    case tpexp of
      TC.TPERROR => tpexp
    | TC.TPCONSTANT {const, ty, loc} => makeApply(tpexp, spine, loc)
    | TC.TPGLOBALSYMBOL {name, kind, ty, loc} => makeApply(tpexp, spine, loc)
    | TC.TPVAR (_,loc) => makeApply (tpexp, spine, loc)
    | TC.TPEXVAR (exVarInfo, loc) => makeApply (tpexp, spine, loc)
    | 
      (*
       * grab the arity amount of argument from the spine stack and make 
       * an uncurried application.
       * If the spine does not contain enough arguments, then we perfrom 
       * eta-expansion.
       * If the size of the spine is larger than arity then 
       * we re-construct applications, i.e. uncurrying is performed 
       * only for statically know function indicated by TC.TPRECFUNVAR.
       *)
      TC.TPRECFUNVAR {var={path, id, ty}, arity, loc} =>
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
                  (TC.TPTAPP
                     {exp = TC.TPVAR ({path=path, id=id, ty=newPolyTy},
                                      loc),
                      expTy = newPolyTy,
                      instTyList =
                      map
                        T.BOUNDVARty
                        (BoundTypeVarID.Map.listKeys boundtvars),
                      loc = loc},
                   argTyList, 
                   newBodyTy,
                   spine, 
                   loc)
          in
            TC.TPPOLY{btvEnv =boundtvars,
                      expTyWithoutTAbs = newPoyTyBody,
                      exp = newPolyTtermBody,
                      loc = loc
                     }
          end
       | (T.POLYty {boundtvars, body}, x::_) =>
         raise Control.Bug "polymorphic uncurried function with non nil spine"
       | _ => 
         (
          let
            val (argTyList, bodyTy) = grabTy (ty, arity)
          in
            grabAndApply 
              (TC.TPVAR
                 ({path=path, id=id, ty= T.FUNMty(argTyList, bodyTy)},
                  loc), 
               argTyList, 
               bodyTy,
               spine, 
               loc)
          end
          handle x => raise x
         )
      )
    | TC.TPFNM {argVarList, bodyTy, bodyExp, loc} =>
      let
        val newBodyExp = uncurryExp  nil bodyExp
      in
        makeApply(TC.TPFNM {argVarList = argVarList, 
                            bodyTy = bodyTy, 
                            bodyExp = newBodyExp, 
                            loc = loc},
                  spine,
                  loc)
      end
    | TC.TPAPPM {funExp, funTy, argExpList = [argExp], loc} =>
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
      TC.TPAPPM {funExp, funTy, argExpList, loc} =>
      let
        val newFunExp = uncurryExp nil funExp
        val newArgExpList = map (uncurryExp nil) argExpList
      in
        makeApply (TC.TPAPPM{funExp = newFunExp, 
                             funTy = funTy, 
                             argExpList = newArgExpList, 
                             loc = loc},
                   spine,
                   loc)
      end
    | TC.TPDATACONSTRUCT {con, instTyList, argExpOpt = SOME exp, loc} =>
      let
        val newTpexp = TC.TPDATACONSTRUCT
                         {con=con, 
                          instTyList=instTyList, 
                          argExpOpt = SOME (uncurryExp nil exp), 
                          loc = loc}
      in
        makeApply (newTpexp, spine, loc)
      end
    | TC.TPDATACONSTRUCT {con, instTyList, argExpOpt = NONE, loc} =>
      makeApply (tpexp, spine, loc)
    | TC.TPEXNCONSTRUCT {exn, instTyList, argExpOpt = SOME exp, loc} =>
      let
        val newTpexp = TC.TPEXNCONSTRUCT
                         {exn=exn, 
                          instTyList=instTyList, 
                          argExpOpt = SOME (uncurryExp nil exp), 
                          loc = loc}
      in
         makeApply (newTpexp, spine, loc)
      end
    | TC.TPEXNCONSTRUCT {exn, instTyList, argExpOpt = NONE, loc} =>
      makeApply (tpexp, spine, loc)
    | TC.TPEXN_CONSTRUCTOR {exnInfo, loc} =>
      makeApply (tpexp, spine, loc)
    | TC.TPEXEXN_CONSTRUCTOR {exExnInfo, loc} =>
      makeApply (tpexp, spine, loc)
    | TC.TPCASEM {expList, expTyList, ruleList, ruleBodyTy, caseKind, loc} =>
      let
        val newExpList = map (uncurryExp  nil) expList
        val newRuleList =
            map
              (fn {args, body} => {args=args, body= uncurryExp  nil body})
              ruleList
      in
        makeApply(TC.TPCASEM {expList = newExpList, 
                              expTyList = expTyList, 
                              ruleList = newRuleList, 
                              ruleBodyTy = ruleBodyTy,
                              caseKind = caseKind,
                              loc = loc},
                  spine,
                  loc)
      end
    | TC.TPPRIMAPPLY {primOp, instTyList, argExp = exp, loc} => 
      let
        val newTpexp = TC.TPPRIMAPPLY {primOp=primOp, 
                                       instTyList=instTyList, 
                                       argExp = uncurryExp nil exp, 
                                       loc = loc}
       in
        makeApply (newTpexp, spine, loc)
      end
    | TC.TPOPRIMAPPLY
        {oprimOp, instTyList, argExp = exp, loc} => 
      let
        val newTpexp = TC.TPOPRIMAPPLY {oprimOp = oprimOp,
                                        instTyList = instTyList, 
                                        argExp = uncurryExp nil exp, 
                                        loc = loc}
      in
        makeApply (newTpexp, spine, loc)
      end
    | TC.TPRECORD {fields, recordTy, loc} =>
      let
        val newFields = LabelEnv.map (uncurryExp  nil) fields
      in
        makeApply
          (TC.TPRECORD {fields = newFields, recordTy = recordTy, loc=loc},
           spine,
           loc)
      end
    | TC.TPSELECT {label, exp, expTy, resultTy, loc} =>
      let
        val newExp = uncurryExp  nil exp
      in
        makeApply(TC.TPSELECT {label = label, 
                               exp = newExp, 
                               expTy = expTy, 
                               resultTy = resultTy,
                               loc = loc},
                  spine,
                  loc)
      end
    | TC.TPMODIFY {label, recordExp, recordTy, elementExp, elementTy, loc} =>
      let
        val newRecordExp = uncurryExp  nil recordExp
        val newElementExp = uncurryExp  nil elementExp
      in
        makeApply(TC.TPMODIFY {label = label, 
                               recordExp = newRecordExp, 
                               recordTy = recordTy, 
                               elementExp = newElementExp,
                               elementTy = elementTy,
                               loc = loc},
                  spine,
                  loc)
      end
    | TC.TPSEQ {expList, expTyList, loc} =>
      let
        val newExpList = map (uncurryExp nil) expList
      in
        makeApply(TC.TPSEQ {expList=newExpList, 
                            expTyList = expTyList, 
                            loc = loc},
                  spine,
                  loc)
      end
    | TC.TPMONOLET {binds, bodyExp, loc} =>
      let
        val newBinds = map (fn (v,exp) => (v, uncurryExp  nil exp))binds
        val newBodyExp = uncurryExp  nil bodyExp
      in
        makeApply(TC.TPMONOLET {binds=newBinds, bodyExp=newBodyExp, loc=loc},
                  spine,
                  loc)
      end
    | TC.TPLET {decls, body, tys, loc} =>
      let
        val decls = uncurryDeclList decls
        val body = map (uncurryExp  nil) body
      in
        makeApply(TC.TPLET {decls=decls, body=body, tys=tys, loc=loc},
                  spine,
                  loc)
      end
    | TC.TPRAISE {exp,ty,loc} =>
      makeApply(TC.TPRAISE{exp=uncurryExp  nil exp,ty=ty,loc=loc},
                spine,
                loc)
    | TC.TPHANDLE {exp, exnVar, handler, loc} =>
      let
        val newExp = uncurryExp  nil exp
        val newHandler = uncurryExp  nil handler
      in
        makeApply(TC.TPHANDLE {exp = newExp, 
                               exnVar = exnVar, 
                               handler = newHandler, 
                               loc = loc},
                  spine,
                  loc)
      end
    | TC.TPPOLYFNM
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
        makeApply(TC.TPPOLYFNM
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
    | TC.TPPOLY {btvEnv, expTyWithoutTAbs, exp, loc} =>
      let
        val newExp = uncurryExp  nil exp
      in
        makeApply(TC.TPPOLY {btvEnv=btvEnv, 
                             expTyWithoutTAbs = expTyWithoutTAbs, 
                             exp = newExp, 
                             loc = loc},
                  spine,
                  loc)
      end
    | TC.TPTAPP
        {exp = TC.TPRECFUNVAR {var={path, id, ty}, arity, loc=loc1},
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
             | _ => raise Control.Bug "non function type in TC.TPRECFUNVAR"
       in
         grabAndApply 
           (TC.TPTAPP
              {exp = TC.TPVAR ({path=path, id=id, ty=newPolyTy},loc1), 
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
    | TC.TPTAPP {exp, expTy, instTyList, loc} =>
      let
        val newExp = uncurryExp  nil exp
      in
        makeApply(TC.TPTAPP {exp=newExp, 
                             expTy = expTy, 
                             instTyList = instTyList, 
                             loc = loc},
                  spine,
                  loc)
      end
    | TC.TPFFIIMPORT {ptrExp, ffiTy, stubTy, loc} =>
      makeApply (TC.TPFFIIMPORT {ptrExp = uncurryExp nil ptrExp,
                                 ffiTy = ffiTy,
                                 stubTy = stubTy,
                                 loc = loc},
                 spine, loc)
    | TC.TPCAST (tpexp, ty, loc) =>
      makeApply(TC.TPCAST(uncurryExp nil tpexp, ty, loc),
                spine,
                loc)
      
    | TC.TPSIZEOF (_,loc) => makeApply (tpexp, spine, loc)
    | TC.TPSQLSERVER {server, schema, resultTy, loc} =>
      let
        val server = map (fn (l,e) => (l,uncurryExp nil e)) server
      in
        makeApply (TC.TPSQLSERVER{server=server, schema=schema,
                                  resultTy=resultTy, loc=loc},
                   spine, loc)
      end

  and uncurryDecl tpdecl = 
      case tpdecl of
        TC.TPVAL (valIdTpexpList, loc) => 
        [TC.TPVAL(map (fn (id,exp) => (id, uncurryExp  nil exp))
                      valIdTpexpList,
                  loc)]
      | TC.TPFUNDECL (fundecls, loc) =>
        [TC.TPVALREC
           (map (fn (var, ty, exp) => {var=var,exp=exp, expTy = ty}) 
                (map (matchToFnCaseTerm  loc) fundecls),
            loc)]
      | TC.TPPOLYFUNDECL (btvEnv, fundecls, loc) =>
        [TC.TPVALPOLYREC
           (btvEnv, 
            map (fn (v,ty,exp) => {var =v, exp = exp, expTy = ty})
                (map (matchToFnCaseTerm  loc) fundecls),
            loc)]
      | TC.TPVALREC (bindList, loc) =>
        [TC.TPVALREC
           (map (fn {var, expTy, exp} =>
                    {var=var, expTy=expTy, exp=uncurryExp  nil exp})
                bindList, loc)
        ]
      | TC.TPVALPOLYREC (btvEnv, recBinds, loc) =>
        [
         TC.TPVALPOLYREC
           (btvEnv, 
            map
              (fn {var, expTy, exp}
                  => {var=var, expTy = expTy, exp = uncurryExp  nil exp})
              recBinds, 
            loc) 
        ]
      | TC.TPEXD _ => [tpdecl]
      | TC.TPEXNTAGD _ => [tpdecl]
      | TC.TPEXTERNVAR  _ => [tpdecl]
      | TC.TPEXTERNEXN  _ => [tpdecl]
      | TC.TPEXPORTEXN  _ => [tpdecl]
      | TC.TPEXPORTVAR (TC.VARID var,loc) => [tpdecl]
      | TC.TPEXPORTVAR (TC.RECFUNID (var as {ty,path,...}, arity),loc) => 
        let
          val tpexp =
              uncurryExp nil (TC.TPRECFUNVAR{var=var,arity=arity,loc=loc})
          val newVar = {path=path,id=VarID.generate(), ty=ty}
          val decl = TC.TPVAL([(newVar,tpexp)], loc)
          val newExport = TC.TPEXPORTVAR (TC.VARID newVar,loc)
        in
          [decl, newExport]
        end

  and uncurryDeclList pldeclList = 
      foldr (fn (decl, declList) => (uncurryDecl decl) @ declList)
            nil
            pldeclList

  and optimize decList =  uncurryDeclList decList handle exn => raise exn

end
end

