(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Huu-Duc Nguyen 
 *)
structure TypeCheckTypedLambda = struct
local

  open TypedLambda 
  open Types
  structure E = TypeCheckTypedLambdaError
  structure TU = TypesUtils
  structure PT = PredefinedTypes
  structure CT = ConstantTerm


  exception Eqty
  exception ApplyTy
  exception NotYet

  structure btvEq:ordsig = struct 
                             type ord_key = int * int
                             fun compare ((i1,j1), (i2,j2)) = 
                               case Int.compare(i1,i2) of
                                 EQUAL => Int.compare (j1,j2)
                               | result => result
                           end
  structure BtvEquiv = BinarySetFn(btvEq)
  (*
   * equivalence relation on bound type variabls 
   * used to compute equality of polymorphic types
   *)
  fun addToBtvEquiv (btvEquiv, (i1,i2)) =
    if i1 > i2 
    then BtvEquiv.add(btvEquiv,(i2,i1))
    else BtvEquiv.add(btvEquiv,(i1,i2))
  fun isBtvEquiv (btvEquiv, (i1,i2)) =
    if i1 > i2 
    then BtvEquiv.member(btvEquiv,(i2,i1))
    else BtvEquiv.member(btvEquiv,(i1,i2))
  val emptyBtvEquiv = BtvEquiv.empty

  val intTy = PT.intty
  fun makeArrayTy elementTy = CONty{tyCon = PT.arrayTyCon, args = [elementTy]}

  val emptyBtvEnv = IEnv.empty
  fun extendBtvEnv (oldBtvEnv, newBtvEnv) = IEnv.unionWith #2 (oldBtvEnv, newBtvEnv)


  fun eqTyList L =
    let
      (*
       * the first parameter btvEquiv is an equivalence relation on
       * bound type variables.
       *
       *)
      fun eqTy btvEquiv (ty1, ty2) = 
          case (ty1, ty2) of
            (TYVARty (ref(SUBSTITUTED derefTy1)), _) => eqTy btvEquiv (derefTy1, ty2)
          | (_, TYVARty (ref(SUBSTITUTED derefTy2))) => eqTy btvEquiv (ty1, derefTy2)
          | (ALIASty(_, ty1), ty2) => eqTy btvEquiv (ty1, ty2)
          | (ty1, ALIASty(_, ty2)) => eqTy btvEquiv (ty1, ty2)
          | (ERRORty, _) => ()
          | (_, ERRORty) => ()
          | (ABSSPECty(ty11, ty12), _) => eqTy btvEquiv (ty12,ty2)
          | (_, ABSSPECty(ty21, ty22)) => eqTy btvEquiv (ty1,ty22)
          | (BOUNDVARty tv1, BOUNDVARty tv2) => 
            if tv1 = tv2 orelse isBtvEquiv (btvEquiv,(tv1,tv2)) then () else raise Eqty
          | (BOUNDVARty _, _) => raise Eqty
          | (_, BOUNDVARty _) => raise Eqty
          | (DUMMYty n2, DUMMYty n1) => if n1 = n2 then () else raise Eqty
          | (DUMMYty _, _) => raise Eqty
          | (_, DUMMYty _) => raise Eqty
          | (TYVARty(ref(TVAR {id = id1, ...})), TYVARty(ref(TVAR {id = id2, ...}))) =>
            if id1 = id2 then () else raise Eqty
          | (TYVARty _, _) => raise Eqty
          | (_, TYVARty _) => raise Eqty
          | (FUNMty(domainTyList1, rangeTy1), FUNMty(domainTyList2, rangeTy2)) =>
            if length domainTyList1 = length domainTyList2
            then eqTys btvEquiv (ListPair.zip (domainTyList1, domainTyList2) @[(rangeTy1, rangeTy2)])
            else raise Eqty
          | (
             CONty{tyCon = {name=name1,id=id1, boxedKind = ref Types.GENERICty,...}, args = tyList1},
             CONty{tyCon = {name=name2,id=id2, boxedKind = ref Types.GENERICty,...}, args = tyList2}
            ) =>
            if !Control.doCompileObj 
            then
              if ID.eq(id1, id2) andalso length tyList1 = length tyList2
              then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
              else raise Eqty
            else  raise Eqty
          | (
             CONty{tyCon = {name=name1,id=id1, boxedKind = ref boxedKindValue1,...}, args = tyList1},
             CONty{tyCon = {name=name2,id=id2, boxedKind = ref boxedKindValue2,...}, args = tyList2}
            ) =>
            if ID.eq(id1, id2) andalso length tyList1 = length tyList2
            then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
            else 
              if TU.isATOMty boxedKindValue1 andalso TU.isATOMty boxedKindValue2 
              then ()
              else raise Eqty
          | (RECORDty tyFields1, RECORDty tyFields2) =>
            let
              val (newTyEquations, rest) = 
                  SEnv.foldri 
                      (fn (label, ty1, (newTyEquations, rest)) =>
                          let 
                            val (rest, ty2) = SEnv.remove(rest, label)
                          in 
                            ((ty1, ty2) :: newTyEquations, rest) 
                          end
                          handle LibBase.NotFound => raise Eqty)
                      (nil, tyFields2)
                      tyFields1
            in
              if SEnv.isEmpty rest 
              then eqTys btvEquiv newTyEquations
              else raise Eqty
            end
          | (BOXEDty, BOXEDty) => ()
          | (DOUBLEty, DOUBLEty) => ()
          | (ATOMty, ATOMxty) => ()
          | (POLYty{boundtvars = btvenv1, body = body1},
             POLYty{boundtvars = btvenv2, body = body2}) =>
            let
              val btvlist1 = IEnv.listKeys btvenv1
              val btvlist2 = IEnv.listKeys btvenv2
              val newBtvEquiv =
                  if length btvlist1 = length btvlist2 
                  then 
                    ListPair.foldl 
                        (fn (btv1, btv2, btvEquiv) => addToBtvEquiv(btvEquiv, (btv1,btv2)))
                        btvEquiv 
                        (btvlist1, btvlist2)
                  else raise Eqty
            in 
              eqTy newBtvEquiv (body1, body2) 
            end
          | (ABSTRACTty, ABSTRACTty) => ()
          | (SPECty ty1, SPECty ty2) => 
            if !Control.doCompileObj 
            then eqTy btvEquiv (ty1, ty2)
            else raise Eqty
          | _ => raise Eqty
      and eqTys btvEquiv nil = ()
        | eqTys btvEquiv ((ty1,ty2)::tail) = (eqTy btvEquiv (ty1,ty2); eqTys btvEquiv tail)
    in
      eqTys emptyBtvEquiv L
    end

 fun checkApplyTy (funTy, argTyList) =
     case TU.derefTy funTy of
       FUNMty(paramTyList, resultTy) => 
       let
         val numParams = length paramTyList
         val numArgTys = length argTyList
       in
         (if numParams = numArgTys 
          then (eqTyList (ListPair.zip (paramTyList, argTyList)); resultTy)
          else raise ApplyTy)
         handle Eqty => raise ApplyTy
       end
     | _ => raise ApplyTy

 fun staticFieldSelect (btvEnv:Types.btvKind IEnv.map) (recordTy, label, loc) =
   case TU.derefTy recordTy of
     RECORDty tyFields =>
     (
      case SEnv.find(tyFields, label) of
        SOME fieldTy => fieldTy
      | _ => (E.enqueueDiagnosis
                  (
                   loc, 
                   "staticFieldSelect 1",
                   E.RecordFieldNotFound
                       {
                        recordTy = recordTy, 
                        field = label
                       }
                  );
              Types.ERRORty
             )
     )
   | BOUNDVARty i =>
     (
      case IEnv.find(btvEnv, i) of
        SOME {recKind = REC fields,...} =>
        (case SEnv.find(fields, label) of 
           SOME ty => ty
         | NONE => 
           (E.enqueueDiagnosis 
                (
                 loc,
                 "staticFieldSelect 2",
                 E.RecordFieldNotFound
                     {
                      recordTy = recordTy,
                      field = label
                     }
                );
            Types.ERRORty
           )
        )
      | _ => 
        (
         E.enqueueDiagnosis 
             (
              loc,
              "staticFieldSelect 3",
              E.RecordFieldNotFound
                  {
                   recordTy = recordTy,
                   field = label
                  }
             );
         Types.ERRORty
        )
     )
   | _ =>
       (
        E.enqueueDiagnosis
            (
             loc, 
             "staticFieldSelect 4",
             E.RecordFieldNotFound
                 {
                  recordTy = recordTy,
                  field = label
                 }
            );
        Types.ERRORty
       )

 fun typecheckExp btvEnv tlexp = 
     case tlexp of
       TLFOREIGNAPPLY {funExp, funTy, argExpList, convention, loc} =>
       let
         val funExpTy = typecheckExp btvEnv funExp
         val argExpTyList = map (typecheckExp btvEnv) argExpList
(*
             case (map (typecheckExp btvEnv) argExpList) of 
               nil => [PT.unitty]
             | tyList => tyList
*)
       in
         checkApplyTy (funTy, argExpTyList)
         handle ApplyTy =>
                (
                 E.enqueueDiagnosis 
                     (
                      loc,
                      "typecheckExp 1",
                      E.OperatorOperandMismatch
                          {
                           funTy = funTy,
                           argTyList = argExpTyList
                          }
                     );
                 ERRORty
                )
       end
     | TLEXPORTCALLBACK {funExp, funTy, loc} =>
       let
         val funExpTy = typecheckExp btvEnv funExp
         val _ =
             eqTyList [(funExpTy,funTy)]
             handle Eqty => 
                    E.enqueueDiagnosis
                        (
                         loc, 
                         "typecheckExp 2",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = funTy,
                              expType = funExpTy
                             }
                        )
       in
         PT.wordty
       end             
     | TLEXCEPTIONTAG {tagValue, loc} => CT.constDefaultTy (CT.INT(Int32.fromInt(tagValue)))       
     | TLCONSTANT {value,...} => CT.constDefaultTy value
     | TLSIZEOF {ty, loc} => intTy
     | TLVAR {varInfo, ...} => #ty varInfo
     | TLGETFIELD {arrayExp, indexExp, elementTy, loc} => 
       let
         val arrayExpTy = typecheckExp btvEnv arrayExp
         val arrayTy = makeArrayTy elementTy
         val _ =
             eqTyList [(arrayExpTy, arrayTy)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 3",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = arrayTy,
                              expType = arrayExpTy
                             }
                        )
         val arrayIndexTy = typecheckExp btvEnv indexExp
         val _ =
             eqTyList [(arrayIndexTy, intTy)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 4",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = intTy,
                              expType = arrayIndexTy
                             }
                        )
       in
         elementTy
       end
     | TLSETTAIL {consExp, newTailExp, listTy, consRecordTy, tailLabel, loc} => 
       let
         val consExpTy = typecheckExp btvEnv consExp
         val newTailExpTy = typecheckExp btvEnv newTailExp
         val _ =
           eqTyList[(consExpTy, listTy),
                    (newTailExpTy, listTy)
                    ]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 27",
                         E.SetTailMismatch 
                         {
                          consExpTy = consExpTy, 
                          newTailExpTy = newTailExpTy,
                          listTy = listTy
                          }
                        )
       in
         PT.unitty
       end
         
     | TLSETFIELD {arrayExp, indexExp, valueExp, elementTy, loc } => 
       let
         val valueExpTy = typecheckExp btvEnv valueExp
         val _ =
             eqTyList [(valueExpTy, elementTy)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 5",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = elementTy,
                              expType = valueExpTy
                             }
                        )
         val arrayExpTy = typecheckExp btvEnv arrayExp
         val arrayTy = makeArrayTy elementTy
         val _ =
             eqTyList [(arrayExpTy, arrayTy)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 6",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = arrayTy,
                              expType = arrayExpTy
                             }
                        )
         val arrayIndexTy = typecheckExp btvEnv indexExp
         val _ =
             eqTyList [(arrayIndexTy, intTy)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 7",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = intTy,
                              expType = arrayIndexTy
                             }
                        )
         
       in 
         PT.unitty
       end
     | TLGETGLOBAL {valueTy, ...} => valueTy
     | TLSETGLOBAL {valueExp, valueTy, loc, ...} => 
       let
         val valueExpTy = TU.compactTy (typecheckExp btvEnv valueExp)
         val valueTy = TU.compactTy valueTy
         val _ =
             eqTyList [(valueExpTy, valueTy)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 8",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = valueTy,
                              expType = valueExpTy
                             }
                        )
       in 
         PT.unitty
       end
     | TLINITARRAY _  => PT.unitty
     | TLARRAY {sizeExp, initialValue, elementTy, loc} => 
       let
         val sizeExpTy = typecheckExp btvEnv sizeExp
         val _ = 
             eqTyList [(sizeExpTy, intTy)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 9",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = intTy,
                              expType = sizeExpTy
                             }
                        )
         val initialValueTy = typecheckExp btvEnv initialValue
         val _ = 
             eqTyList [(initialValueTy, elementTy)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 10",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = elementTy,
                              expType = initialValueTy
                             }
                        )
       in
         CONty{tyCon = PT.arrayTyCon, args = [initialValueTy]}
       end
     | TLPRIMAPPLY {primInfo, argExpList, loc} => 
       let
         val funTy = #ty primInfo
         val argExpTyList = map (typecheckExp btvEnv) argExpList
         val resultTy  = 
             checkApplyTy (funTy, argExpTyList)
             handle ApplyTy =>
                    (
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "typecheckExp 11",
                          E.OperatorOperandMismatch
                              {
                               funTy = funTy,
                               argTyList = argExpTyList
                              }
                         );
                     ERRORty
                    )
       in
         resultTy
       end
     | TLAPPM {funExp, funTy, argExpList, loc} => 
       let
         val expFunTy = typecheckExp btvEnv funExp
         val _ = 
             eqTyList [(funTy, expFunTy)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 12",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = funTy,
                              expType = expFunTy
                             }
                        )
         val argExpTyList = map  (typecheckExp btvEnv) argExpList
         val resultTy  = 
             checkApplyTy (funTy, argExpTyList)
             handle ApplyTy =>
                    (
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "typecheckExp 16",
                          E.OperatorOperandMismatch
                              {
                               funTy = funTy,
                               argTyList = argExpTyList
                              }
                         );
                     ERRORty
                    )
       in
         resultTy
       end
     | TLLET {localDeclList, mainExp, loc} => 
       let
         val _ = typecheckTldeclList btvEnv localDeclList
       in
         typecheckExp btvEnv mainExp
       end
     | TLRECORD {expList, recordTy, loc, ...} => 
       let
         val expTyList = map (typecheckExp btvEnv) expList
         val tyList = 
             case TU.derefTy recordTy of
               RECORDty tyFields => SEnv.listItems tyFields
             | _ => 
               (E.enqueueDiagnosis
                    (
                     loc, 
                     "typecheckExp 13",
                     E.RecordTermDoNotHaveARecordType recordTy
                    );
                map (fn x => Types.ERRORty) expList
               )
         val _ = 
             (if length tyList = length expTyList 
              then eqTyList (ListPair.zip (tyList, expTyList))
              else E.enqueueDiagnosis
                       (loc,
                        "typecheckExp 14",
                        E.ArgNumAndArgTyListMisMatch
                            {
                             numArgs = length expTyList,
                             numArgTys = length tyList
                            }
                       )
             )
             handle Eqty => 
                    (
                     E.enqueueDiagnosis
                         (loc,
                          "typecheckExp 15",
                          E.ArgTyListAndArgExpTyListMismatch
                              {
                               argTyList = tyList, 
                               argExpTyList = expTyList
                              }
                         )
                    )
       in
         recordTy
       end
     | TLSELECT {recordExp, label, recordTy, loc} => 
       let
         val expRecordTy = typecheckExp btvEnv recordExp
         val _ = 
             eqTyList [(expRecordTy, recordTy)]
             handle Eqty =>
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 16",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = recordTy,
                              expType = expRecordTy
                             }
                        )
       in
         staticFieldSelect btvEnv (recordTy, label, loc)
       end
     | TLMODIFY {recordExp, recordTy, label, valueExp, loc} => 
       let
         val expRecordTy = typecheckExp btvEnv recordExp
         val _ = 
             eqTyList [(expRecordTy, recordTy)]
             handle Eqty =>
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 17",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = recordTy,
                              expType = expRecordTy
                             }
                        )
         val valueTy = typecheckExp btvEnv valueExp
         val fieldTy = staticFieldSelect btvEnv (recordTy, label, loc)
         val _ = 
             eqTyList [(valueTy, fieldTy)]
             handle Eqty =>
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 18",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = valueTy,
                              expType = fieldTy
                             }
                        )
       in
         recordTy
       end
     | TLRAISE {argExp, resultTy, loc} => 
       let
         val expTy = typecheckExp btvEnv argExp
       in
         resultTy
       end
     | TLHANDLE {exp, exnVar as {ty,...}, handler, loc} => 
       let
         val expTy = typecheckExp btvEnv exp
         val _ = 
             eqTyList [(ty, PT.exnty)]
             handle Eqty =>
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 19",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = PT.exnty,
                              expType = ty
                             }
                        )
         val handlerTy = typecheckExp btvEnv handler
         val _ = 
             eqTyList [(expTy, handlerTy)]
             handle Eqty =>
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 20",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = expTy,
                              expType = handlerTy
                             }
                        )
       in
         expTy
       end
     | TLFNM {argVarList, bodyTy, bodyExp, loc} => 
       let
         val argTyList = map #ty argVarList
         val bodyExpTy = typecheckExp btvEnv bodyExp
         val _ = 
             eqTyList [(bodyTy, bodyExpTy)]
             handle Eqty =>
                    E.enqueueDiagnosis
                        (
                         loc,
                         "typecheckExp 21",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = bodyTy,
                              expType = bodyExpTy
                             }
                        )
       in
         FUNMty(argTyList, bodyTy)
       end
     | TLPOLY {btvEnv = btvKind, expTyWithoutTAbs, exp, loc} => 
       let
         val bodyExpTy = typecheckExp (extendBtvEnv(btvEnv,btvKind)) exp
         val _ = 
             eqTyList [(expTyWithoutTAbs, bodyExpTy)]
             handle Eqty =>
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 22",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = expTyWithoutTAbs,
                              expType = bodyExpTy
                             }
                        )
       in
         POLYty{boundtvars = btvKind, body = bodyExpTy}
       end
     | TLTAPP {exp, expTy, instTyList, loc} => 
       let
         val polyExpTy = typecheckExp btvEnv exp
         val _ = 
             eqTyList [(expTy, polyExpTy)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 23",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = expTy,
                              expType = polyExpTy
                             }
                        )
         val instanciatedTy = 
             case TypesUtils.derefTy expTy of
               POLYty {boundtvars, body} => 
               let
                 val polyArity = IEnv.numItems boundtvars 
                 val numTyArgs = List.length instTyList
               in
                 if polyArity = numTyArgs
                 then TU.tpappTy(expTy, instTyList)
                 else 
                   (
                    E.enqueueDiagnosis
                        (
                         loc, 
                         "typecheckExp 24",
                         E.InstanceArityMisMatch
                             {
                              polyArity = polyArity, 
                              numTyargs = numTyArgs
                             }
                        );
                    Types.ERRORty
                   )
               end
       in
         instanciatedTy
       end
     | TLSWITCH {switchExp, expTy, branches, defaultExp, loc} => 
       let
         val switchExpTy = typecheckExp btvEnv switchExp
         val defaultExpTy = typecheckExp btvEnv defaultExp
         val _ = 
             eqTyList [(switchExpTy, expTy)]
             handle Eqty =>
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 25",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = expTy,
                              expType = switchExpTy
                             }
                        )
         val _ = 
             map 
                 (fn {constant, exp} =>
                     let
                       val ruleBodyTy = typecheckExp btvEnv exp
                     in
                       eqTyList [(defaultExpTy,ruleBodyTy)]
                       handle Eqty =>
                              E.enqueueDiagnosis 
                                  (
                                   loc,
                                   "typecheckExp 26",
                                   E.TypeAndAnnotationMismatch
                                       {
                                        annotation = defaultExpTy,
                                        expType = ruleBodyTy
                                       }
                                  )
                     end
                 )
                 branches
       in
         defaultExpTy
       end
     | TLCAST {exp, targetTy, loc} => 
       let
         val expTy = typecheckExp btvEnv exp
       in
         targetTy
       end

 and typecheckTldecl btvEnv tldecl = 
     case tldecl of
     TLVAL {boundVar as {ty,...}, boundExp, loc} => 
     let
       val expTy = typecheckExp btvEnv boundExp
     in
       (eqTyList [(ty, expTy)])
       handle Eqty =>
              E.enqueueDiagnosis 
                  (
                   loc,
                   "typecheckTldecl 1",
                   E.TypeAndAnnotationMismatch
                       {
                        annotation = ty,
                        expType = expTy
                       }
                  )
     end
   | TLVALREC {recbindList, loc} => 
     (
      map 
          (fn {boundVar as {ty,...}, boundExp} =>
              let
                val expTy = typecheckExp btvEnv boundExp
              in
                eqTyList [(ty, expTy)]
                handle Eqty =>
                       E.enqueueDiagnosis 
                           (
                            loc,
                            "typecheckTldecl 2",
                            E.TypeAndAnnotationMismatch
                                {
                                 annotation = ty,
                                 expType = expTy
                                }
                           )
              end
          )
          recbindList;
      ()
     )
   | TLVALPOLYREC {btvEnv = btvKinds, recbindList, loc} => 
     (
      map 
          (fn {boundVar = {ty,...}, boundExp} =>
              let
                val expTy = typecheckExp (extendBtvEnv(btvEnv,btvKinds)) boundExp
              in
                eqTyList [(ty, expTy)]
                handle Eqty =>
                       E.enqueueDiagnosis 
                           (
                            loc,
                            "typecheckTldecl 3",
                            E.TypeAndAnnotationMismatch
                                {
                                 annotation = ty,
                                 expType = expTy
                                }
                           )
              end
          )
          recbindList;
      ()
     )

  and typecheckTldeclList btvEnv  nil = ()
    | typecheckTldeclList btvEnv (tldecl::tldeclList) =
      (typecheckTldecl btvEnv tldecl;
       typecheckTldeclList btvEnv tldeclList)

in

  fun typecheck tldeclList = 
      (
       E.initializeTypecheckError();
       map (typecheckTldecl emptyBtvEnv) tldeclList;
       E.getDiagnoses()
       )
      handle NotYet => E.getDiagnoses()
      
end
end
