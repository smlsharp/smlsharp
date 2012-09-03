(**
 * MultipleValueCalc type check
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: MVTypeCheck.sml,v 1.5 2007/06/19 22:19:11 ohori Exp $
 *)
structure MVTypeCheck = struct

local

  structure E = MVTypeCheckError
  structure ATU = AnnotatedTypesUtils
  structure PT = PredefinedTypes
  structure CT = ConstantTerm
  structure AT = AnnotatedTypes
  open MultipleValueCalc
       
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

  fun formatCon (name,id) = name ^ "#" ^ (ID.toString id)

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
              (AT.ERRORty, _) => ()
            | (_, AT.ERRORty) => ()

            | (AT.DUMMYty n2, AT.DUMMYty n1) => if n1 = n2 then () else raise Eqty
            | (AT.DUMMYty _, _) => raise Eqty
            | (_, AT.DUMMYty _) => raise Eqty

            | (AT.TYVARty (ref{id = id1, ...}), AT.TYVARty (ref {id = id2, ...})) =>
              if id1 = id2 then () else raise Eqty
            | (AT.TYVARty _, _) => raise Eqty
            | (_, AT.TYVARty _) => raise Eqty

            | (AT.BOUNDVARty tv1, AT.BOUNDVARty tv2) => 
              if tv1 = tv2 orelse isBtvEquiv (btvEquiv,(tv1,tv2)) then () else raise Eqty
            | (AT.BOUNDVARty _, _) => raise Eqty
            | (_, AT.BOUNDVARty _) => raise Eqty

            | (AT.FUNMty{argTyList=argTyList1,bodyTy=bodyTy1,...}, 
               AT.FUNMty{argTyList=argTyList2,bodyTy=bodyTy2,...}) =>
              if length argTyList1 = length argTyList2
              then eqTys btvEquiv (ListPair.zip (argTyList1, argTyList2) @[(bodyTy1, bodyTy2)])
              else raise Eqty
            | (
               AT.CONty{tyCon = {name=name1,id=id1, boxedKind = ref boxedKindValue1,...}, args = tyList1},
               AT.CONty{tyCon = {name=name2,id=id2, boxedKind = ref boxedKindValue2,...}, args = tyList2}
              ) =>
              if length tyList1 = length tyList2
              then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
              else 
                if TypesUtils.isATOMty boxedKindValue1 andalso TypesUtils.isATOMty boxedKindValue2 
                then ()
                else raise Eqty
            | (AT.RECORDty {fieldTypes=flty1,...}, AT.RECORDty {fieldTypes=flty2,...}) =>
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
                        (nil, flty2)
                        flty1
              in
                if SEnv.isEmpty rest 
                then eqTys btvEquiv newTyEquations
                else raise Eqty
              end
            | (AT.MVALty tyList1, AT.MVALty tyList2) =>
              if length tyList1 = length tyList2
              then eqTys btvEquiv (ListPair.zip(tyList1,tyList2))
              else raise Eqty
            | (AT.BOXEDty, AT.BOXEDty) => ()
            | (AT.DOUBLEty, AT.DOUBLEty) => ()
            | (AT.ATOMty, AT.ATOMty) => ()
            | (AT.POLYty{boundtvars = btvenv1, body = body1},
               AT.POLYty{boundtvars = btvenv2, body = body2}) =>
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
            | _ => raise Eqty

        and eqTys btvEquiv nil = ()
          | eqTys btvEquiv ((ty1,ty2)::tail) = (eqTy btvEquiv (ty1,ty2); eqTys btvEquiv tail)
      in
        eqTys emptyBtvEquiv L
      end

  fun checkApplyTy (funTy, argExpTyList) =
      case funTy of
        AT.FUNMty{argTyList, bodyTy,...} => 
        (
         (
          if length argTyList = length argExpTyList 
          then (eqTyList (ListPair.zip (argTyList, argExpTyList)); bodyTy)
          else raise ApplyTy
         )
         handle Eqty => raise ApplyTy
        )
      | _ => raise ApplyTy

  fun staticFieldSelect (btvEnv:AT.btvEnv) (recordTy, label, loc) =
      case recordTy of
        AT.RECORDty {fieldTypes,...} =>
        (
         case SEnv.find(fieldTypes, label) of
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
                 AT.ERRORty
                )
        )
      | AT.BOUNDVARty i =>
        (
         case IEnv.find(btvEnv, i) of
           SOME {recKind = AT.REC fields,...} =>
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
               AT.ERRORty
              )
           )
         | _ => 
           (
            E.enqueueDiagnosis 
                (
                 loc,
                 "staticFieldSelect 2",
                 E.RecordFieldNotFound
                     {
                      recordTy = recordTy,
                      field = label
                     }
                );
            AT.ERRORty
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
         AT.ERRORty
        )
        
  fun typecheckExp btvEnv mvexp = 
      case mvexp of
        MVFOREIGNAPPLY {funExp, funTy, argExpList, convention, loc} =>
        let
          val funExpTy = typecheckExp btvEnv funExp
          val argExpTyList = map (typecheckExp btvEnv) argExpList
(*
            Inside of the FOREIGNAPPLY, function type my have 0-argument type.
              case (map (typecheckExp btvEnv) argExpList) of 
                nil => [AT.unitty]
              | tyList => tyList
*)
        in
          checkApplyTy (funTy, argExpTyList)
          handle ApplyTy =>
                 (
                  E.enqueueDiagnosis 
                      (
                       loc,
                       "mvtypecheckExp 1",
                       E.OperatorOperandMismatch
                           {
                            funTy = funTy,
                            argTyList = argExpTyList
                           }
                      );
                  AT.ERRORty
                 )
        end
      | MVEXPORTCALLBACK {funExp, funTy, loc} =>
        let
          val funExpTy = typecheckExp btvEnv funExp
          val _ =
              eqTyList [(funExpTy,funTy)]
              handle Eqty => 
                     E.enqueueDiagnosis
                         (
                          loc, 
                          "mvtypecheckExp 2",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = funTy,
                               expType = funExpTy
                              }
                         )
        in
          AT.wordty
        end             
      | MVSIZEOF {ty, loc} => AT.intty
      | MVEXCEPTIONTAG {tagValue, loc} => AT.intty
      | MVCONSTANT {value,...} => ATU.constDefaultTy value
      | MVVAR {varInfo, ...} => #ty varInfo
      | MVGETGLOBAL {valueTy, ...} => valueTy
      | MVSETGLOBAL {valueExp, valueTy, loc, ...} => 
        let
          val valueExpTy = typecheckExp btvEnv valueExp
          val _ =
              eqTyList [(valueExpTy, valueTy)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 3",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = valueTy,
                               expType = valueExpTy
                              }
                         )
        in 
          AT.unitty
        end
      | MVINITARRAY _  => AT.unitty
      | MVGETFIELD {arrayExp, indexExp, elementTy, loc} => 
        let
          val arrayExpTy = typecheckExp btvEnv arrayExp
          val arrayTy = AT.arrayty elementTy
          val _ =
              eqTyList [(arrayExpTy, arrayTy)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 4",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = arrayTy,
                               expType = arrayExpTy
                              }
                         )
          val arrayIndexTy = typecheckExp btvEnv indexExp
          val _ =
              eqTyList [(arrayIndexTy, AT.wordty)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 5",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = AT.wordty,
                               expType = arrayIndexTy
                              }
                         )
        in
          elementTy
        end

      | MVSETFIELD {arrayExp, indexExp, valueExp, elementTy, loc } => 
        let
          val valueExpTy = typecheckExp btvEnv valueExp
          val _ =
              eqTyList [(valueExpTy, elementTy)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 6",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = elementTy,
                               expType = valueExpTy
                              }
                         )
          val arrayExpTy = typecheckExp btvEnv arrayExp
          val arrayTy = AT.arrayty elementTy
          val _ =
              eqTyList [(arrayExpTy, arrayTy)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 7",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = arrayTy,
                               expType = arrayExpTy
                              }
                         )
          val arrayIndexTy = typecheckExp btvEnv indexExp
          val _ =
              eqTyList [(arrayIndexTy, AT.wordty)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 8",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = AT.wordty,
                               expType = arrayIndexTy
                              }
                         )
        in 
          AT.unitty
        end

      | MVSETTAIL {consExp, newTailExp, listTy, consRecordTy, tailLabel, loc } => 
        let
          val consExpTy = typecheckExp btvEnv consExp
          val newTailExpTy = typecheckExp btvEnv newTailExp
          val _ =
              eqTyList [
                        (consExpTy, listTy),
                        (newTailExpTy, listTy)
                        ]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 30",
                          E.SetTailMismatch
                              {
                               consExpTy = consExpTy,
                               newTailExpTy = newTailExpTy,
                               listTy = listTy
                              }
                         )
        in 
          AT.unitty
        end

      | MVARRAY {sizeExp, initialValue, elementTy, loc} => 
        let
          val sizeExpTy = typecheckExp btvEnv sizeExp
          val _ = 
              eqTyList [(sizeExpTy, AT.wordty)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 9",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = AT.wordty,
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
                          "mvtypecheckExp 10",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = elementTy,
                               expType = initialValueTy
                              }
                         )
        in
          AT.arrayty initialValueTy
        end
      | MVPRIMAPPLY {primInfo, argExpList, loc} => 
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
                           "mvtypecheckExp 11",
                           E.OperatorOperandMismatch
                               {
                                funTy = funTy,
                                argTyList = argExpTyList
                               }
                          );
                      AT.ERRORty
                     )
        in
          resultTy
        end
      | MVAPPM {funExp, funTy, argExpList, loc} => 
        let
          val expFunTy = typecheckExp btvEnv funExp
          val _ = 
              eqTyList [(funTy, expFunTy)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 12",
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
                           "mvtypecheckExp 13",
                           E.OperatorOperandMismatch
                               {
                                funTy = funTy,
                                argTyList = argExpTyList
                               }
                          );
                      AT.ERRORty
                     )
        in
          resultTy
        end
      | MVLET {localDeclList, mainExp, loc} => 
        let
          val _ = typecheckDeclList btvEnv localDeclList
        in
          typecheckExp btvEnv mainExp
        end
      | MVMVALUES {expList, tyList, loc} =>
        let
          val _ = 
              if List.all (fn (AT.MVALty _) => false | _ => true) tyList
              then ()
              else
                E.enqueueDiagnosis
                    (loc,
                     "mvtypecheckExp 14",
                     E.InvalidSingleTypeList
                         {
                          tyList = tyList
                         }
                    )
          val expTyList = map (typecheckExp btvEnv) expList
          val _ =
              (if length tyList = length expTyList 
               then eqTyList (ListPair.zip (tyList, expTyList))
               else E.enqueueDiagnosis
                        (loc,
                         "mvtypecheckExp 15",
                         E.ArgNumAndArgTyListMismatch
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
                           "mvtypecheckExp 16",
                           E.ArgTyListAndArgExpTyListMismatch
                               {
                                argTyList = tyList, 
                                argExpTyList = expTyList
                               }
                          )
                     )
(*           val _ = *)
(*               if length tyList <= 1 *)
(*               then  *)
(*                 E.enqueueDiagnosis *)
(*                     ( *)
(*                      loc, *)
(*                      "mvtypecheckExp 17", *)
(*                      E.MultipleValueExpHasTooFewElements *)
(*                          { *)
(*                           numArgs = length tyList *)
(*                          } *)
(*                     ) *)
(*               else () *)
        in
          AT.MVALty tyList
        end
      | MVRECORD {expList, recordTy, loc,...} => 
        let
          val expTyList = map (typecheckExp btvEnv) expList
          val tyList = 
              case recordTy of
                AT.RECORDty {fieldTypes,...} => SEnv.listItems fieldTypes
              | _ => 
                (E.enqueueDiagnosis
                     (
                      loc, 
                      "mvtypecheckExp 18",
                      E.RecordTermDoNotHaveARecordType recordTy
                     );
                 map (fn x => AT.ERRORty) expList
                )
          val _ = 
              if List.all (fn (AT.MVALty _) => false | _ => true) tyList
              then ()
              else
                E.enqueueDiagnosis
                    (loc,
                     "mvtypecheckExp 19",
                     E.InvalidSingleTypeList
                         {
                          tyList = tyList
                         }
                    )
          val _ = 
              (if length tyList = length expTyList 
               then eqTyList (ListPair.zip (tyList, expTyList))
               else E.enqueueDiagnosis
                        (loc,
                         "mvtypecheckExp 20",
                         E.ArgNumAndArgTyListMismatch
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
                           "mvtypecheckExp 21",
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
      | MVSELECT {recordExp, label, recordTy, loc} => 
        let
          val expRecordTy = typecheckExp btvEnv recordExp
          val _ = 
              eqTyList [(expRecordTy, recordTy)]
              handle Eqty =>
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 22",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = recordTy,
                               expType = expRecordTy
                              }
                         )
        in
          staticFieldSelect btvEnv (recordTy, label, loc)
        end
      | MVMODIFY {recordExp, recordTy, label, valueExp, valueTy, loc} => 
        let
          val expRecordTy = typecheckExp btvEnv recordExp
          val _ = 
              eqTyList [(expRecordTy, recordTy)]
              handle Eqty =>
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 23",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = recordTy,
                               expType = expRecordTy
                              }
                         )
          val valueExpTy = typecheckExp btvEnv valueExp
          val _ = 
              eqTyList [(valueTy, valueExpTy)]
              handle Eqty =>
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 24",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = valueTy,
                               expType = valueExpTy
                              }
                         )
          val fieldTy = staticFieldSelect btvEnv (recordTy, label, loc)
          val _ = 
              eqTyList [(valueTy, fieldTy)]
              handle Eqty =>
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 25",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = valueTy,
                               expType = fieldTy
                              }
                         )
        in
          recordTy
        end
      | MVRAISE {argExp, resultTy, loc} => 
        let
          val expTy = typecheckExp btvEnv argExp
        in
          resultTy
        end
      | MVHANDLE {exp, exnVar as {ty,...}, handler, loc} => 
        let
          val expTy = typecheckExp btvEnv exp
          val _ = 
              eqTyList [(ty, AT.exnty)]
              handle Eqty =>
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 26",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = AT.exnty,
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
                          "mvtypecheckExp 27",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = expTy,
                               expType = handlerTy
                              }
                         )
        in
          expTy
        end
      | MVFNM {argVarList, funTy, bodyExp, annotation, loc} => 
        let
          val argTyList = map #ty argVarList
          val bodyTy  = 
              checkApplyTy (funTy, argTyList)
              handle ApplyTy =>
                     (
                      E.enqueueDiagnosis 
                          (
                           loc,
                           "mvtypecheckExp 28",
                           E.OperatorOperandMismatch
                               {
                                funTy = funTy,
                                argTyList = argTyList
                               }
                          );
                      AT.ERRORty
                     )
          val bodyExpTy = typecheckExp btvEnv bodyExp
          val _ = 
              eqTyList [(bodyTy, bodyExpTy)]
              handle Eqty =>
                     E.enqueueDiagnosis
                         (
                          loc,
                          "mvtypecheckExp 29",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = bodyTy,
                               expType = bodyExpTy
                              }
                         )
        in
          funTy
        end
      | MVPOLY {btvEnv = btvKind, expTyWithoutTAbs, exp, loc} => 
        let
          val bodyExpTy = typecheckExp (extendBtvEnv(btvEnv,btvKind)) exp
          val _ = 
              eqTyList [(expTyWithoutTAbs, bodyExpTy)]
              handle Eqty =>
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 30",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = expTyWithoutTAbs,
                               expType = bodyExpTy
                              }
                         )
        in
          AT.POLYty{boundtvars = btvKind, body = bodyExpTy}
        end
      | MVTAPP {exp, expTy, instTyList, loc} => 
        let
          val polyExpTy = typecheckExp btvEnv exp
          val _ = 
              eqTyList [(expTy, polyExpTy)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 31",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = expTy,
                               expType = polyExpTy
                              }
                         )
          val instanciatedTy = 
              case expTy of
                AT.POLYty {boundtvars, body} => 
                let
                  val polyArity = IEnv.numItems boundtvars 
                  val numTyArgs = List.length instTyList
                in
                  if polyArity = numTyArgs
                  then ATU.tpappTy(expTy, instTyList)
                  else 
                    (
                     E.enqueueDiagnosis
                         (
                          loc, 
                          "mvtypecheckExp 32",
                          E.InstanceArityMismatch
                              {
                               polyArity = polyArity, 
                               numTyargs = numTyArgs
                              }
                         );
                     AT.ERRORty
                    )
                end
        in
          instanciatedTy
        end
      | MVSWITCH {switchExp, expTy, branches, defaultExp, loc} => 
        let
          val switchExpTy = typecheckExp btvEnv switchExp
          val defaultExpTy = typecheckExp btvEnv defaultExp
          val _ = 
              eqTyList [(switchExpTy, expTy)]
              handle Eqty =>
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 33",
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
                                    "mvtypecheckExp 34",
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
      | MVCAST {exp, expTy, targetTy, loc} => 
        let
          val ty = typecheckExp btvEnv exp
          val _ =
              eqTyList [(ty,expTy)]
              handle Eqty =>
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 35",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = expTy,
                               expType = ty
                              }
                         )
        in
          targetTy
        end

  and typecheckDecl btvEnv mvdecl = 
      case mvdecl of
        MVVAL {boundVars, boundExp, loc} => 
        let
          val expTyList = 
              case typecheckExp btvEnv boundExp of
                AT.MVALty tyList => tyList
              | ty => [ty]
          val tyList = map #ty boundVars
        in
          (
           if length tyList = length expTyList 
           then eqTyList (ListPair.zip (tyList, expTyList))
           else E.enqueueDiagnosis
                    (loc,
                     "mvtypecheckDecl 1",
                     E.ArgNumAndArgTyListMismatch
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
                       "mvtypecheckDecl 2",
                       E.ArgTyListAndArgExpTyListMismatch
                           {
                            argTyList = tyList, 
                            argExpTyList = expTyList
                           }
                      )
                 )
        end
      | MVVALREC {recbindList, loc} => 
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
                               "mvtypecheckDecl 3",
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
      | MVVALPOLYREC {btvEnv = btvKinds, recbindList, loc} => 
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
                               "mvtypecheckDecl 4",
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

  and typecheckDeclList btvEnv  nil = ()
    | typecheckDeclList btvEnv (decl::declList) =
      (typecheckDecl btvEnv decl; typecheckDeclList btvEnv declList)

in

  fun typecheck declList = 
      (
       E.initializeTypecheckError();
       typecheckDeclList emptyBtvEnv declList;
       E.getDiagnoses()
      )
      handle NotYet => E.getDiagnoses()
end
      
end
