(**
 * Copyright (c) 2006, Tohoku University.
 *
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
  structure T = Types
  structure TConT = TypeContext
  structure P = Path
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
       val _ = TEnv.map (fn (tvstate as ref (T.TVAR ({tyvarName = SOME "RIGID", 
                                                      id,
                                                      recKind,
                                                      eqKind}))) =>
                            tvstate := T.TVAR {
                                               tyvarName = NONE,
                                               id = id,
                                               recKind = recKind,
                                               eqKind = eqKind
                                               }
                          | _ => raise Control.Bug "should be RIGID TYVAR"
                            )
                        tyvarIEnv
       val {boundEnv,...} = TU.generalizer (ty,SEnv.empty,SEnv.empty)
     in
       boundEnv
     end
(*                             
 fun generateInstTermFunOnStructure (sigTy, strTy) =
     let
       val instTermFun = 
           let
             val instSigTy = 
                 if TU.monoTy sigTy then sigTy 
                 else TU.freshRigidInstTy sigTy
           in   
             fn tpvar => 
              (
               let
                 val (instStrTy,tpexp) = TCU.freshInst(strTy,tpvar)
                 (* unify error captured by signature check *)
                 val _ = U.unify [(instStrTy,instSigTy)]
                 val boundEnv = 
                     (* after the imperative operation
                      * instSigTy = instStrTy 
                      *)
                     generalizeRigidTyvarBoundEnv instStrTy
               in 
                 if IEnv.isEmpty boundEnv then
                   tpexp
                 else
                   TC.TPPOLY {btvEnv=boundEnv, expTyWithoutTAbs=instSigTy, exp=tpexp, loc=TCU.getLocOfExp tpvar}
               end)
              handle U.Unify => tpvar
           end
     in
       instTermFun
     end
*)
(* fun generateInstVarEnvOnStructure (actualVarEnv, constrainedVarEnv) =
     SEnv.foldli (fn (varName,idstate,instVarEnv) =>
                     case idstate of
                       T.VARID({name, strpath, ty = sigTy}) =>
                       ( 
                        case SEnv.find(actualVarEnv,varName) of
                          SOME(idstate as T.VARID({name, strpath, ty = strTy})) =>
                          (
                           let
                             val instTerm = 
                                 generateInstTermFunOnStructure (sigTy,strTy) 
                           in
                             SEnv.insert(instVarEnv,varName, (instTerm,idstate))
                           end
                           )
                        | SOME(idstate as T.CONID({ty = strTy,...})) =>
                          (
                           let
                             val instTerm =
                                 generateInstTermFunOnStructure (sigTy,strTy) 
                           in
                             SEnv.insert(instVarEnv,varName, (instTerm,idstate))
                           end
                           ) 
                        | _ => instVarEnv
                       )
                     | T.CONID({ty = sigTy,...}) =>
                       (
                        case SEnv.find(actualVarEnv,varName) of
                          SOME(idstate as T.CONID{ty = strTy,...}) =>
                            let
                              val instTerm = 
                                  generateInstTermFunOnStructure (sigTy,strTy) 
                            in
                              SEnv.insert(instVarEnv,varName, (instTerm,idstate))
                            end
                        | _ => instVarEnv
                       )
                     | _ => instVarEnv
                  )
                 SEnv.empty
                 constrainedVarEnv
                 
 fun generateInstStrEnvOnStructure (actualStrEnv, constrainedStrEnv) =
     SEnv.foldli (fn (strName, T.STRUCTURE{ env = (_, cVE, cSE),...}, instStrEnv) =>
                     case SEnv.find(actualStrEnv,strName) of
                       SOME(T.STRUCTURE{ env = (_, aVE, aSE),...}) =>
                       let
                         val subInstVarEnv = 
                             generateInstVarEnvOnStructure(aVE, cVE)
                         val subInstStrEnv = 
                             generateInstStrEnvOnStructure(aSE, cSE)
                       in
                         SEnv.insert(instStrEnv,
                                     strName,
                                     (TConT.InstStr(subInstVarEnv,subInstStrEnv)))
                       end
                     | NONE => 
                       (* error case captured by signature check *)
                       instStrEnv
                         )
                 SEnv.empty
                 constrainedStrEnv

 fun generateInstEnvOnStructure (actualEnv , constrainedEnv) =
     let
       val (_, aVarEnv, aStrEnv) = actualEnv
       val (_, cVarEnv, cStrEnv) = constrainedEnv
       val instVarEnv = generateInstVarEnvOnStructure (aVarEnv, cVarEnv)
       val instStrEnv = generateInstStrEnvOnStructure (aStrEnv, cStrEnv)
     in
       (instVarEnv, instStrEnv)
     end
*)
  (************ refractoring ******************)
  (* strId, strName, strPath is a relative path
   * representing the long structure identifier 
   * appearing in "open" declaration
   *)
  fun generateInstantiatedStructure (strId, strName, strPath, loc) (strEnv, sigEnv) =
      let
        val pathPrefix = Path.appendPath (strPath, strId, strName)
        fun genInstExp (tpexp, strTy, sigTy) =
            let
              val instSigTy =
                  if TU.monoTy sigTy then sigTy
                  else TU.freshRigidInstTy sigTy
              val (newSigTy, exp) = 
                  let
                    val (instStrTy,tpexp) = TCU.freshInst(strTy, tpexp)
                    (* unify error captured by signature check *)
                    val _ = U.patternUnify [(instStrTy,instSigTy)]
                    val boundEnv = 
                        generalizeRigidTyvarBoundEnv instStrTy
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

        fun genInstValDecs pathPrefix loc (strVE:T.varEnv, sigVE:T.varEnv) =
            SEnv.foldl (fn (idstate, valDecs) =>
                           case idstate of
                             T.VARID {name, strpath, ty = sigTy} =>
                             let
                               val (strTy,tpexp) = 
                                   case SEnv.find(strVE,name) of
                                     NONE => 
                                     (* shoule be captured by typeinference *)
                                     (T.ERRORty,
                                      TC.TPVAR ({ name = name, 
                                                  strpath = P.NilPath, 
                                                  ty = T.ERRORty },
                                                loc)
                                      )
                                   | SOME (T.VARID {ty,...}) => 
                                     (ty,
                                      TC.TPVAR ({ name = name, 
                                                  strpath = P.NilPath, 
                                                  ty = ty },
                                                loc)
                                      )
                                   | SOME (idState as T.CONID {ty,...}) => 
                                     TIU.etaExpandCon (P.NilPath, name)
                                                      loc
                                                      idState
                                   | SOME (T.FFID {ty,...}) =>
                                     (ty,
                                      TC.TPVAR ({ name = name,
                                                  strpath = P.NilPath,
                                                  ty = ty},
                                                loc)
                                      )
                                   | _ =>  
                                     raise Control.Bug
                                             ("genInstValDecs:"^name^" is declared as PRIM/OPRIM")
                               val (ty,valExp) =
                                   genInstExp (tpexp, strTy, sigTy)
                               val valDec = 
                                   TC.TPVAL([(T.VALIDVAR {name = name, ty = ty},
                                             valExp)],
                                            loc)
                             in
                               TC.TPMCOREDEC([valDec],loc) :: valDecs
                             end
                           | _ => valDecs
                       )
                       nil
                       sigVE

        fun genInstStrDecs pathPrefix loc (strSE:T.strEnv, sigSE:T.strEnv) =
            SEnv.foldl ( fn (T.STRUCTURE {id, name, strpath, env}, strdecs) =>
                            let
                              val (subSigTE, subSigVE, subSigSE) = env
                              val strdec = 
                                  case SEnv.find(strSE,name) of
                                    NONE => (* should be captured by typeinference *)
                                    nil
                                  | SOME 
                                      (T.STRUCTURE 
                                         {id, name, env = (subStrTE, subStrVE, subStrSE),...}
                                         ) 
                                      =>
                                      let
                                        val openDec =
                                            TC.TPMCOREDEC
                                              ([TC.TPOPEN ([{id = id, 
                                                             name = name,
                                                             strpath = pathPrefix,
                                                             env = (subStrTE, subStrVE, subStrSE)
                                                             }
                                                            ],
                                                           loc)
                                                ],
                                               loc)
                                        val pathPrefix = 
                                            Path.appendPath (pathPrefix, id, name)
                                        val valDecs2 = 
                                            genInstValDecs pathPrefix loc (subStrVE, subSigVE)
                                        val strDecs2 = 
                                            genInstStrDecs pathPrefix loc (subStrSE, subSigSE)
                                        val strExp = TC.TPMSTRUCT  ((openDec :: (valDecs2 @ strDecs2)),loc)
                                        val strDec =
                                            [
                                             TC.TPMSTRBIND 
                                               (
                                                [
                                                 ({ id = id,
                                                    name = name,
                                                    env = 
                                                    (subSigTE, subSigVE, subSigSE)}
                                                  ,strExp)
                                                 ],
                                                loc
                                                )
                                               ]
                                      in
                                        strDec
                                      end

                            in
                              strdecs @ strdec
                            end
                       )
                       nil
                       sigSE
            
        fun genInstTopStrDecs pathPrefix loc (strEnv,sigEnv) =
            let
              val (_, strVE, strSE) = strEnv 
              val (_, sigVE, sigSE) = sigEnv
              val valDecs = genInstValDecs pathPrefix loc (strVE, sigVE)
              val strDecs = genInstStrDecs pathPrefix loc (strSE, sigSE)
            in
              valDecs @ strDecs 
            end
      in
        genInstTopStrDecs pathPrefix loc (strEnv,sigEnv)
      end
end
end
