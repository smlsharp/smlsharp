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
       val _ = TEnv.map (fn (tvstate as ref (T.TVAR ({
                                                      lambdaDepth,
                                                      tyvarName = SOME "RIGID", 
                                                      id,
                                                      recKind,
                                                      eqKind}))) =>
                            tvstate := T.TVAR {
                                               lambdaDepth = lambdaDepth,
                                               tyvarName = NONE,
                                               id = id,
                                               recKind = recKind,
                                               eqKind = eqKind
                                               }
                          | _ => raise Control.Bug "should be RIGID TYVAR"
                            )
                        tyvarIEnv
       val {boundEnv,...} = TU.generalizer (ty, T.toplevelDepth)
     in
       boundEnv
     end

 (* strId, strName, strPath is a relative path
  * representing the long structure identifier 
  * appearing in "open" declaration
  *)
 fun generateInstantiatedStructure (pathPrefix, loc) (strEnv, sigEnv) =
      let
        fun genInstExp (tpexp, strTy, sigTy) =
            let
              val instSigTy =
                  if TU.monoTy sigTy then sigTy
                  else TU.freshRigidInstTy sigTy
              val (newSigTy, exp) = 
                  let
                    val (instStrTy,tpexp) = TCU.freshInst(strTy, tpexp)
                    val _ = U.patternUnify [(instStrTy,instSigTy)]
                        (* To avoid duplication report : 
                         * Unify error should be already captured by
                         * 1.core language checking
                         * 2.signature checking
                         *)
                        handle U.Unify => ()
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

        fun genInstStrDecs pathPrefix loc (T.STRUCTURE strSECont, T.STRUCTURE sigSECont) =
            SEnv.foldl ( fn ({id, name, strpath, env}, strdecs) =>
                            let
                              val (subSigTE, subSigVE, subSigSE) = env
                              val strdec = 
                                  case SEnv.find(strSECont,name) of
                                    NONE => (* should be captured by typeinference *)
                                    nil
                                  | SOME {id, name, env = (subStrTE, subStrVE, subStrSE),...}
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
                       sigSECont
            
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
