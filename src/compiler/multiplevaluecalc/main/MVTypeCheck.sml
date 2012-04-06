(**
 * MultipleValueCalc type check
 * @copyright (c) 2006, Tohoku University.
 * @author Huu-Duc Nguyen 
 * @version $Id: MVTypeCheck.sml,v 1.34 2008/11/19 20:04:38 ohori Exp $
 *
   This must be called after function localization.
 *
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
            
  structure btvEq:ORD_KEY = struct 
    type ord_key = BoundTypeVarID.id * BoundTypeVarID.id
    fun compare ((i1,j1), (i2,j2)) = 
        case BoundTypeVarID.compare(i1,i2) of
          EQUAL => BoundTypeVarID.compare (j1,j2)
        | result => result
  end
  structure BtvEquiv = BinarySetFn(btvEq)

  fun formatCon (name,id) = name ^ "#" ^ (VarID.toString id)

  (*
   * equivalence relation on bound type variabls 
   * used to compute equality of polymorphic types
   *)
  fun addToBtvEquiv (btvEquiv, (i1,i2)) =
      case BoundTypeVarID.compare (i1, i2) of
        GREATER => BtvEquiv.add(btvEquiv,(i2,i1))
      | _ => BtvEquiv.add(btvEquiv,(i1,i2))
  fun isBtvEquiv (btvEquiv, (i1,i2)) =
      case BoundTypeVarID.compare (i1, i2) of
        GREATER => BtvEquiv.member(btvEquiv,(i2,i1))
      | _ => BtvEquiv.member(btvEquiv,(i1,i2))
  val emptyBtvEquiv = BtvEquiv.empty

  val emptyBtvEnv = BoundTypeVarID.Map.empty
  fun extendBtvEnv (oldBtvEnv, newBtvEnv) =
      BoundTypeVarID.Map.unionWith #2 (oldBtvEnv, newBtvEnv)

                                            
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

            | (AT.DUMMYty n2, AT.DUMMYty n1) =>
                if n1 = n2 then () else (print "\n 1 \n";raise Eqty)
            | (AT.DUMMYty _, _) => (print "\n 2 \n";raise Eqty)
            | (_, AT.DUMMYty _) => (print "\n 3 \n";raise Eqty)

            | (AT.SINGLETONty
                 (AT.INSTCODEty {oprimId=id1, oprimPolyTy=ty1, ...}),
               AT.SINGLETONty
                 (AT.INSTCODEty {oprimId=id2, oprimPolyTy=ty2, ...})) =>
              if OPrimID.eq (id1, id2) then eqTy btvEquiv (ty1, ty2)
              else raise Eqty
            | (AT.SINGLETONty (AT.INDEXty (l1, ty1)),
               AT.SINGLETONty (AT.INDEXty (l2, ty2))) =>
              if l1 = l2 then eqTy btvEquiv (ty1, ty2) else raise Eqty

            | (AT.BOUNDVARty tv1, AT.BOUNDVARty tv2) => 
              if tv1 = tv2 orelse isBtvEquiv (btvEquiv,(tv1,tv2)) then ()
              else (print "\n 7 \n"; raise Eqty)
            | (AT.BOUNDVARty _, _) => (print "\n 8 \n";raise Eqty)
            | (_, AT.BOUNDVARty _) => (print "\n 9 \n";raise Eqty)

            | (AT.FUNMty{argTyList=argTyList1,bodyTy=bodyTy1,...}, 
               AT.FUNMty{argTyList=argTyList2,bodyTy=bodyTy2,...}) =>
              if length argTyList1 = length argTyList2
              then 
                eqTys
                btvEquiv
                (ListPair.zip (argTyList1, argTyList2) @[(bodyTy1, bodyTy2)])
              else (print "\n 10 \n";raise Eqty)
            | (
               AT.RAWty{tyCon = {id=id1,...}, args = tyList1},
               AT.RAWty{tyCon = {id=id2,...}, args = tyList2}
              ) =>
                if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2
                  then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
                else (print "\n 11 \n";raise Eqty)
            | (AT.SPECty {tyCon = {id=id1,...}, args = tyList1},
               AT.SPECty {tyCon = {id=id2,...}, args = tyList2}) =>
              if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2 
              then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
              else (print "Eqty 16\n";raise Eqty)
            | (AT.SPECty {tyCon = {id=id1,...}, args = tyList1},
               AT.RAWty {tyCon = {id=id2,...}, args = tyList2}) =>
              if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2 
              then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
              else (print "Eqty 16\n";raise Eqty)
            | (AT.RAWty {tyCon = {id=id1,...}, args = tyList1},
               AT.SPECty {tyCon = {id=id2,...}, args = tyList2}) =>
              if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2 
              then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
              else (print "Eqty 16\n";raise Eqty)
(*
            | (
               AT.CONty{tyName = {name=name1,id=id1, boxedKind = ref boxedKindValue1,...}, args = tyList1},
               AT.CONty{tyName = {name=name2,id=id2, boxedKind = ref boxedKindValue2,...}, args = tyList2}
              ) =>
              if length tyList1 = length tyList2
              then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
              else 
                if TypesUtils.isATOMty boxedKindValue1 andalso TypesUtils.isATOMty boxedKindValue2 
                then ()
                else raise Eqty
*)
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
                            handle LibBase.NotFound => (print "\n 12 \n";raise Eqty))
                        (nil, flty2)
                        flty1
              in
                if SEnv.isEmpty rest 
                then eqTys btvEquiv newTyEquations
                else (print "\n 13 \n";raise Eqty)
              end
            | (AT.MVALty tyList1, AT.MVALty tyList2) =>
              if length tyList1 = length tyList2
              then eqTys btvEquiv (ListPair.zip(tyList1,tyList2))
              else (print "\n 14 \n";raise Eqty)
            | (AT.POLYty{boundtvars = btvenv1, body = body1},
               AT.POLYty{boundtvars = btvenv2, body = body2}) =>
              let
                val btvlist1 = BoundTypeVarID.Map.listKeys btvenv1
                val btvlist2 = BoundTypeVarID.Map.listKeys btvenv2
                val newBtvEquiv =
                    if length btvlist1 = length btvlist2 
                    then 
                      ListPair.foldl 
                          (fn (btv1, btv2, btvEquiv) => addToBtvEquiv(btvEquiv, (btv1,btv2)))
                          btvEquiv 
                          (btvlist1, btvlist2)
                    else (print "\n 15 \n";raise Eqty)
              in 
                  eqTy newBtvEquiv (body1, body2) 
              end
(*
            | (AT.SPECty ty1, AT.SPECty ty2) =>
              eqTy btvEquiv (ty1, ty2) 
            | (
               AT.SPECty(AT.CONty{tyName = {name=name1, id=id1,...}, 
                                  args = tyList1}),
               AT.CONty{tyName = {name=name2, id=id2, ...}, 
                        args = tyList2}
               ) =>
              if !Control.doCompileObj orelse !Control.doFunctorCompile then
                  if length tyList1 = length tyList2 andalso GlobalID.compare(id1, id2) = EQUAL
                  then (eqTys btvEquiv  (ListPair.zip (tyList1, tyList2)))
                  else raise Eqty
              else raise Eqty
            | (
               AT.CONty{tyName = {name=name1, id=id1, ...}, 
                        args = tyList1},
               AT.SPECty(AT.CONty{tyName = {name=name2, id=id2,...}, 
                                  args = tyList2})
               ) =>
              if !Control.doCompileObj orelse !Control.doFunctorCompile then
                  if length tyList1 = length tyList2 andalso GlobalID.compare(id1, id2) = EQUAL
                  then (eqTys btvEquiv  (ListPair.zip (tyList1, tyList2)))
                  else raise Eqty
              else raise Eqty
*)
            | _ => (print "\n 16 \n"; raise Eqty)

        and eqTys btvEquiv nil = ()
          | eqTys btvEquiv ((ty1,ty2)::tail) = (eqTy btvEquiv (ty1,ty2); eqTys btvEquiv tail)
      in
        eqTys emptyBtvEquiv L
      end

  fun checkApplyTy (funTy, argExpTyList) =
    let
      val (argTyList, bodyTy) = 
        case funTy of
          AT.FUNMty{argTyList, bodyTy,...} => (argTyList, bodyTy)
        | _ => 
            (print "ApplyTy 1\n";
             raise ApplyTy)
    in
      (
       if length argTyList = length argExpTyList 
         then (eqTyList (ListPair.zip (argTyList, argExpTyList)); bodyTy)
       else 
         (print "ApplyTy 2\n";
          raise ApplyTy)
      )
      handle EqTy => 
         (print "ApplyTy 3\n";
          raise ApplyTy)
    end

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
         case BoundTypeVarID.Map.find(btvEnv, i) of
           SOME {recordKind = AT.REC fields,...} =>
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
              "staticFieldSelect 4",
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
        MVFOREIGNAPPLY {funExp, funTy, argExpList, attributes, loc} =>
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
      | MVEXPORTCALLBACK {funExp, funTy, attributes, loc} =>
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
          AT.foreignfunty
        end             
      | MVTAGOF {ty, loc} => AT.SINGLETONty (AT.TAGty ty)
      | MVSIZEOF {ty, loc} => AT.SINGLETONty (AT.SIZEty ty)
      | MVINDEXOF {label, recordTy, loc} =>
        (staticFieldSelect btvEnv (recordTy, label, loc);
         AT.SINGLETONty (AT.INDEXty (label, recordTy)))
      | MVEXCEPTIONTAG {tagValue, displayName, loc} => AT.exntagty
      | MVCONSTANT {value,...} => ATU.constDefaultTy value
      | MVGLOBALSYMBOL {ty,...} => ty
      | MVVAR {varInfo, ...} => #ty varInfo
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
              eqTyList [(arrayIndexTy, AT.intty)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 5",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = AT.intty,
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
              eqTyList [(arrayIndexTy, AT.intty)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 8",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = AT.intty,
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

      | MVARRAY {sizeExp, initialValue, elementTy, isMutable, loc} => 
        let
          val sizeExpTy = typecheckExp btvEnv sizeExp
          val _ = 
              eqTyList [(sizeExpTy, AT.intty)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 9",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = AT.intty,
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
      | MVCOPYARRAY
            {srcExp,srcIndexExp,dstExp,dstIndexExp,lengthExp,elementTy,loc} =>
        let
          val arrayTy = AT.arrayty elementTy

          val srcExpTy = typecheckExp btvEnv srcExp
          val _ = 
              eqTyList [(srcExpTy, arrayTy)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 36",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = arrayTy,
                               expType = srcExpTy
                              }
                         )
          val srcIndexExpTy = typecheckExp btvEnv srcIndexExp
          val _ = 
              eqTyList [(srcIndexExpTy, AT.intty)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 37",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = AT.intty,
                               expType = srcIndexExpTy
                              }
                         )
          val dstExpTy = typecheckExp btvEnv dstExp
          val _ = 
              eqTyList [(dstExpTy, arrayTy)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 38",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = arrayTy,
                               expType = dstExpTy
                              }
                         )
          val dstIndexExpTy = typecheckExp btvEnv dstIndexExp
          val _ = 
              eqTyList [(dstIndexExpTy, AT.intty)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 39",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = AT.intty,
                               expType = dstIndexExpTy
                              }
                         )
          val lengthExpTy = typecheckExp btvEnv lengthExp
          val _ = 
              eqTyList [(lengthExpTy, AT.intty)]
              handle Eqty => 
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 40",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = AT.intty,
                               expType = lengthExpTy
                              }
                         )
        in
          AT.unitty
        end
      | MVPRIMAPPLY {primInfo, argExpList, instTyList, loc} => 
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
      | MVSELECT {recordExp, indexExp, label, recordTy, resultTy = resultAnnotation, loc} => 
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
          val indexExpTy = typecheckExp btvEnv indexExp
          val _ =
              eqTyList
                [(indexExpTy, AT.SINGLETONty (AT.INDEXty (label, recordTy)))]
              handle Eqty =>
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 22-2",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = indexExpTy,
                               expType = AT.SINGLETONty
                                           (AT.INDEXty (label, recordTy))
                              }
                         )
          val resultTy = staticFieldSelect btvEnv (recordTy, label, loc)
          val _ = 
              eqTyList [(resultTy, resultAnnotation)]
              handle Eqty =>
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 22-3",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = resultAnnotation,
                               expType = resultTy
                              }
                         )
        in
          resultTy
        end
      | MVMODIFY {recordExp, recordTy, indexExp, label, valueExp, valueTy,
                  loc} => 
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
          val indexExpTy = typecheckExp btvEnv indexExp
          val _ = 
              eqTyList
                [(indexExpTy, AT.SINGLETONty (AT.INDEXty (label, recordTy)))]
              handle Eqty =>
                     E.enqueueDiagnosis 
                         (
                          loc,
                          "mvtypecheckExp 24-2",
                          E.TypeAndAnnotationMismatch
                              {
                               annotation = indexExpTy,
                               expType = AT.SINGLETONty
                                           (AT.INDEXty (label, recordTy))
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
        typecheckFunction btvEnv {argVarList = argVarList, funTy = funTy, bodyExp = bodyExp, loc = loc}
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
                  val polyArity = BoundTypeVarID.Map.numItems boundtvars 
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
              | _ => 
                raise
                  Control.Bug
                  "non poly ty in MVTAPP  (multiplevaluecalc/main/MVTypeCheck.sml)"
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

  and typecheckFunction btvEnv {argVarList, funTy, bodyExp, loc} =
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

  and typecheckDeclList btvEnv  nil = ()
    | typecheckDeclList btvEnv (decl::declList) =
      (typecheckDecl btvEnv decl; typecheckDeclList btvEnv declList)

in

  fun typecheckBasicBlock basicBlock = 
      case basicBlock of
          MVVALBLOCK {code, exnIDSet} =>
          (map (typecheckDecl emptyBtvEnv) code;())
        | MVLINKFUNCTORBLOCK _ => ()

  fun typecheckTopBlock topBlock =
      case topBlock of
          MVBASICBLOCK basicBlock =>
          typecheckBasicBlock basicBlock
        | MVFUNCTORBLOCK {bodyCode, ...} => 
          let
              val originalMode = !Control.doFunctorCompile
              val _ = Control.doFunctorCompile := true
              val _ = map typecheckBasicBlock bodyCode
          in Control.doFunctorCompile := originalMode end

  fun typecheck topBlockList = 
      (
       E.initializeTypecheckError();
       map typecheckTopBlock topBlockList;
       E.getDiagnoses()
      )
      handle NotYet => E.getDiagnoses()
end
      
end
