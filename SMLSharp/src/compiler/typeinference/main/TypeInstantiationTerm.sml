(**
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 *)
structure TypeInstantiationTerm =
struct
local
 
  structure TU = TypesUtils
  structure TCU = TypedCalcUtils
  structure U = Unify
  structure TC = TypedCalc
  structure SU = SigUtils
  structure TIU = TypeInferenceUtils
  structure TIC = TypeInferenceContext
  structure T = Types
  structure TConT = TypeContext
  structure P = Path
  structure NPEnv = NameMap.NPEnv
  fun printType ty = print (TypeFormatter.tyToString ty ^ "\n")
  
in
     
 fun computeRigidTyvarEnv ty =
     TypeTransducer.foldTyPostOrder
       (fn (T.TYVARty(tvstate as ref(T.TVAR ({tyvarName = SOME "RIGID", id = id, ...}))), 
            rtvEnv)  => 
           if TEnv.inDomain(rtvEnv,id) then
             rtvEnv
           else
             TEnv.insert(rtvEnv, id, tvstate)
         | (_, rtvEnv) => rtvEnv)
       TEnv.empty
       ty

 (* imperative effect : RIGID tyvar ocurring in sigTy and strTy
  *                     is replaced by real type variable
  *)
 fun generalizeRigidTyvarBoundEnv ty = 
     let
       val tyvarIEnv = computeRigidTyvarEnv ty
       val _ = TEnv.map (fn (tvstate as ref (T.TVAR ({
                                                      lambdaDepth,
                                                      tyvarName = SOME "RIGID", 
                                                      id,
                                                      recordKind,
                                                      eqKind}))) =>
                            tvstate := T.TVAR {
                                               lambdaDepth = lambdaDepth,
                                               tyvarName = NONE,
                                               id = id,
                                               recordKind = recordKind,
                                               eqKind = eqKind
                                               }
                          | _ => raise Control.Bug "should be RIGID TYVAR"
                            )
                        tyvarIEnv
       val {boundEnv,...} = TU.generalizer (ty, T.toplevelDepth)
     in
       boundEnv
     end

 fun genInstExp (tpexp, strTy, sigTy) =
     let
         val instSigTy =
             if TU.monoTy sigTy then sigTy
             else 
                 let
                     val newTy = TU.freshRigidInstTy sigTy
                 in
                     newTy
                 end
         val (newSigTy, exp) = 
             let
                 val (instStrTy, tpexp) = TCU.freshInst (strTy, tpexp)
                 (* Note: unify error should captured by signature check. *)
                 val _ = U.patternUnify [(instStrTy,instSigTy)] 
                     handle _ => () 
                 val boundEnv = 
                     generalizeRigidTyvarBoundEnv instSigTy
             in 
                 if IEnv.isEmpty boundEnv then
                     (instSigTy,tpexp)
                 else
                     (
                      T.POLYty{boundtvars = boundEnv, body = instSigTy},
                      TC.TPPOLY{btvEnv=boundEnv, 
                                expTyWithoutTAbs=instSigTy, 
                                exp=tpexp, 
                                loc=TCU.getLocOfExp tpexp}
                       )
             end
     in
         (newSigTy,exp)
     end
         
 fun genInstValDecs loc (strVE:T.varEnv, sigVE:T.varEnv) usrSrcToSysNPEnv =
     let
         (* The correct program should always find the sysNamePath,
          * otherwise the error should be captured by signature matching and 
          * reported to users.
          *) 
         fun getSysNamePath (namePathNPEnv, namePath)  =
             case NPEnv.find(namePathNPEnv, namePath) of
                 SOME x => NameMap.getNamePathFromIdstate x
               | NONE => namePath
     in
         NPEnv.foldli
             (fn (varNamePath, idstate, valDecs) =>
                 case idstate of
                     T.VARID {ty = sigTy,...} =>
                     let
                         val (strTy,tpexp) = 
                             case NPEnv.find(strVE, varNamePath) of
                                 NONE => 
                                 (* shoule be captured by typeinference *)
                                 (T.ERRORty,
                                  TC.TPVAR ({namePath = 
                                             getSysNamePath (usrSrcToSysNPEnv, varNamePath), 
                                             ty = T.ERRORty },
                                            loc))
                               | SOME (T.VARID {ty, ...}) => 
                                 (ty,
                                  TC.TPVAR ({namePath = 
                                             getSysNamePath (usrSrcToSysNPEnv, varNamePath), 
                                             ty = ty },
                                            loc))
                               | SOME (idState as T.CONID {ty, ...}) => 
                                 TIU.etaExpandCon (getSysNamePath (usrSrcToSysNPEnv, varNamePath))
                                                  loc
                                                  idState
                               | SOME (idState as T.EXNID {ty, ...}) => 
                                 TIU.etaExpandCon (getSysNamePath (usrSrcToSysNPEnv, varNamePath))
                                                  loc
                                                  idState
                               | SOME (idState as T.PRIM {ty, ...}) =>
                                 TIU.etaExpandCon (getSysNamePath (usrSrcToSysNPEnv, varNamePath))
                                                  loc
                                                  idState
                               | _ =>  
                                 raise Control.Bug
                                           ("genInstValDecs:"^
                                            NameMap.namePathToString (varNamePath)^
                                            " is declared as PRIM/OPRIM")
                         val (ty, valExp) =
                             genInstExp (tpexp, strTy, sigTy)
                         val valDec = 
                             TC.TPCOREDEC
                                 ([TC.TPVAL
                                       ([(T.VALIDVAR
                                              {namePath = 
                                               getSysNamePath (usrSrcToSysNPEnv, varNamePath),
                                               ty = ty},
                                          valExp)],
                                        loc)],
                                  loc)
                     in
                         valDec :: valDecs
                     end
                   | _ => valDecs
             )
             nil
             sigVE
     end

 (* To be done:  functor specfication instantiation; not fully test, maybe buggy
  * Illustration: for the following functor
  *
  *      functor F(S: sig val f int -> int end) =
  *      struct
  *            val x = S.f 1
  *            fun g x = x
  *      end
  *
  * if it is constrained by the following interface,
  *
  *      functor F: sig val f : 'a -> 'a end => sig val g : bool -> bool end
  *
  * Then the instantiated functor term is
  *      TPDECFUN {bodyDec = { val S.f = S.f {int}
  *                            val x = S.f 1
  *                            fun g x = x
  *                            val g = g {bool}
  *                          },
  *                ....}
  *)
 fun genInstFunctorDecsFunBind 
         functorInstInfoEnv
         (funBind as {funBindInfo = {funName, 
                                     functorSig = {argSigEnv,
			                           body = (tyConIdSet, bodyEnv),
                                                   argStrPrefixedEnv,
                                                   argTyConIdSet,
                                                   generativeExnTagSet
                                                  },
                                     ...
                                    },
                      argSpec = (argSpec, formalArgNamePathEnv),
                      bodyDec = (bodyDecs, bodyBasicNameMap, printOption),
                      argName}
         )
         loc
  =
  case SEnv.find(functorInstInfoEnv, funName) of
      NONE => (funBind, functorInstInfoEnv)
    | SOME {argSigVarEnv, bodySigVarEnv} =>
      let
          (* contravariant *)
          val argInstDecs = 
              genInstValDecs loc (argSigVarEnv:T.varEnv, (#2 argSigEnv):T.varEnv) (#2 formalArgNamePathEnv)
          (* covariant *)
          val bodyNamePathEnv = NameMap.basicNameMapToFlattenedNamePathEnv bodyBasicNameMap
          val bodyInstDecs =
              genInstValDecs loc ((#2 bodyEnv):T.varEnv, bodySigVarEnv:T.varEnv) (#2 bodyNamePathEnv)
              
          val newBodyDecs = argInstDecs @ bodyDecs @ bodyInstDecs

          val newFunBind = 
              {funBindInfo = {funName = funName, 
                              argName = argName,
                              functorSig = {argSigEnv = argSigEnv,
			                    body = (tyConIdSet, bodyEnv),
                                            argStrPrefixedEnv = argStrPrefixedEnv,
                                            generativeExnTagSet = generativeExnTagSet,
                                            argTyConIdSet = argTyConIdSet}
                             },
               argSpec = (argSpec, formalArgNamePathEnv),
               bodyDec = (newBodyDecs, bodyBasicNameMap, printOption),
               argName = argName}
          val (newFunctorInstInfoEnvEnv, elem) = SEnv.remove(functorInstInfoEnv, funName)
      in
          (newFunBind, newFunctorInstInfoEnvEnv)
      end
      
 and genInstFunctorDecs functorInstInfoEnv tpdecs =
     let
         (* browse tpdecs for functor declaration and instantiate 
          * the functor with functorInstInfo
          *)
         val (newTpdecs, _) =
             foldr (fn (topDec, (newTopDecs, functorInstInfoEnv)) =>
                       case topDec of
                           TC.TPDECFUN  (funBinds, loc) =>
                           let
                               val (newFunBinds, newFunctorInstInfoEnv) = 
                                   foldr (fn (funBind, (newFunBinds, functorInstInfoEnv)) =>
                                             let
                                                 val (newFunBind, newFunctorInstInfoEnv) =
                                                     genInstFunctorDecsFunBind functorInstInfoEnv funBind loc
                                             in
                                                 (newFunBind :: newFunBinds, newFunctorInstInfoEnv)
                                             end)
                                         (nil, functorInstInfoEnv)
                                         funBinds
                           in
                               (TC.TPDECFUN (newFunBinds, loc) :: newTopDecs,
                                newFunctorInstInfoEnv)
                           end
                         | _ => (topDec :: newTopDecs, functorInstInfoEnv)
                   )
                   (nil, functorInstInfoEnv)
                   tpdecs
     in
         newTpdecs
     end
end
end
