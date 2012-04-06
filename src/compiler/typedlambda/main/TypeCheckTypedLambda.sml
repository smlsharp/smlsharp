(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 * @author Huu-Duc Nguyen 
 *)
structure TypeCheckTypedLambda : TYPECHECK_TYPEDLAMBDA = struct
local

  open TypedLambda 
  open Types
  structure E = TypeCheckTypedLambdaError
  structure TU = TypesUtils
  structure PT = PredefinedTypes
  structure CT = ConstantTerm

  fun printTy ty = print (Control.prettyPrint (Types.format_ty nil ty))

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

  val intTy = PT.intty
  fun makeArrayTy elementTy = RAWty {tyCon = PT.arrayTyCon, args = [elementTy]}

  val emptyBtvEnv = BoundTypeVarID.Map.empty
  fun extendBtvEnv (oldBtvEnv, newBtvEnv) = BoundTypeVarID.Map.unionWith #1 (newBtvEnv, oldBtvEnv)


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
(*
          | (ABSSPECty(ty11, ty12), _) => eqTy btvEquiv (ty11,ty2)
          | (_, ABSSPECty(ty21, ty22)) => eqTy btvEquiv (ty1,ty21)
*)
          | (BOUNDVARty tv1, BOUNDVARty tv2) => 
            if tv1 = tv2 orelse isBtvEquiv (btvEquiv,(tv1,tv2)) then () else raise Eqty
          | (BOUNDVARty _, _) => (print "Eqty 1\n";raise Eqty)
          | (_, BOUNDVARty _) => (print "Eqty 2\n";raise Eqty)
          | (DUMMYty n2, DUMMYty n1) => if n1 = n2 then () else (print "Eqty 3\n";raise Eqty)
          | (DUMMYty _, _) => (print "Eqty 4\n";raise Eqty)
          | (_, DUMMYty _) => (print "Eqty 5\n";raise Eqty)
          | (SINGLETONty (INSTCODEty {oprimId=id1, oprimPolyTy=ty1, ...}),
             SINGLETONty (INSTCODEty {oprimId=id2, oprimPolyTy=ty2, ...})) =>
            if OPrimID.eq (id1, id2) then eqTy btvEquiv (ty1, ty2)
            else raise Eqty
          | (SINGLETONty (INDEXty (l1, ty1)),
             SINGLETONty (INDEXty (l2, ty2))) =>
            if l1 = l2 then eqTy btvEquiv (ty1, ty2) else raise Eqty
          | (TYVARty(ref(TVAR {id = id1, ...})), TYVARty(ref(TVAR {id = id2, ...}))) =>
            if FreeTypeVarID.eq(id1,id2)
              then () 
            else (print "Eqty 6\n";raise Eqty)
          | (TYVARty _, _) => (print "Eqty 7\n";raise Eqty)
          | (_, TYVARty _) => (print "Eqty 8\n";raise Eqty)
          | (FUNMty(domainTyList1, rangeTy1), FUNMty(domainTyList2, rangeTy2)) =>
            if length domainTyList1 = length domainTyList2
            then eqTys btvEquiv (ListPair.zip (domainTyList1, domainTyList2) @[(rangeTy1, rangeTy2)])
            else (print "Eqty 9\n";raise Eqty)
          | (RAWty{tyCon={id=id1,...}, args=tyList1}, RAWty{tyCon={id=id2,...}, args=tyList2}) =>
            if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2
            then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
            else (print "Eqty 10\n";raise Eqty)
(*
            | (
               CONty{tyName = {name=name1,id=id1, boxedKind = ref Types.GENERICty,...}, args = tyList1},
               CONty{tyName = {name=name2,id=id2, boxedKind = ref Types.GENERICty,...}, args = tyList2}
              ) =>
  (*
              if !Control.doCompileObj 
              then
  *)
                if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2
                then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
                else (print "Eqty 10\n";raise Eqty)
  (*
              else  (print "Eqty 11\n";raise Eqty)
  *)
            | (
               CONty{tyName = {name=name1,id=id1, boxedKind = ref boxedKindValue1,...}, args = tyList1},
               CONty{tyName = {name=name2,id=id2, boxedKind = ref boxedKindValue2,...}, args = tyList2}
              ) =>
              if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2
              then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
              else 
                if TU.isATOMty boxedKindValue1 andalso TU.isATOMty boxedKindValue2 
                then ()
                else (print "\n ****** \n" ; printTy ty1; 
                      print "\n"; printTy ty2;
                      print "Eqty 12\n";raise Eqty)
*)
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
                          handle LibBase.NotFound => (print "Eqty 13\n";raise Eqty))
                      (nil, tyFields2)
                      tyFields1
            in
              if SEnv.isEmpty rest 
              then eqTys btvEquiv newTyEquations
              else (print "Eqty 14\n";raise Eqty)
            end
          | (POLYty{boundtvars = btvenv1, body = body1},
             POLYty{boundtvars = btvenv2, body = body2}) =>
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
                  else (print "Eqty 15\n";raise Eqty)
            in 
              eqTy newBtvEquiv (body1, body2) 
            end
          | (SPECty {tyCon = {id=id1,...}, args = tyList1},
             SPECty {tyCon = {id=id2,...}, args = tyList2}) =>
            if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2 
            then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
            else (print "Eqty 16\n";raise Eqty)
          | (SPECty {tyCon = {id=id1,...}, args = tyList1},
             RAWty {tyCon = {id=id2,...}, args = tyList2}) =>
            if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2 
            then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
            else (print "Eqty 16\n";raise Eqty)
          | (RAWty {tyCon = {id=id1,...}, args = tyList1},
             SPECty {tyCon = {id=id2,...}, args = tyList2}) =>
            if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2 
            then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
            else (print "Eqty 16\n";raise Eqty)
          | (OPAQUEty {spec ={tyCon = {id=id1,...}, args = tyList1}, implTy=implTy1},
             OPAQUEty {spec ={tyCon = {id=id2,...}, args = tyList2}, implTy=implTy2}) =>
            if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2 
            then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
            else (print "Eqty 17\n";raise Eqty)
(*
          | (SPECty ty1, SPECty ty2) => 
            if !Control.doCompileObj orelse !Control.doFunctorCompile
            then eqTy btvEquiv (ty1, ty2)
            else (print "Eqty 16\n";raise Eqty)
          | (SPECty(CONty{tyName = {name=name1,id=id1,...}, args = tyList1}),
             CONty{tyName = {name=name2,id=id2,...}, args = tyList2}) =>
            if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2 
            then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
            else (print "Eqty 17\n";raise Eqty)
          | (CONty{tyName = {name=name1,id=id1,...}, args = tyList1},
             SPECty(CONty{tyName = {name=name2,id=id2,...}, args = tyList2})) =>
            if TyConID.eq(id1, id2) andalso length tyList1 = length tyList2 
            then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
            else (print "Eqty 18\n";raise Eqty)
*)
          | _ => (print "Eqty 19\n";raise Eqty)
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

 fun staticFieldSelect (btvEnv:Types.btvKind BoundTypeVarID.Map.map) (recordTy, label, loc) =
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
      case BoundTypeVarID.Map.find(btvEnv, i) of
        SOME {recordKind = REC fields,...} =>
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
       TLFOREIGNAPPLY {funExp, funTy, argExpList, attributes, loc} =>
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
     | TLEXPORTCALLBACK {funExp, funTy, attributes, loc} =>
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
         PT.ptrty
       end             
     | TLEXCEPTIONTAG {tagValue, displayName, loc} => PT.exntagty
(*
       (case ExnTagID.getExportNameInID tagValue of
           SOME name =>  
           (case (PT.exnTagNameToInt name) of
                SOME (int: int) => CT.constDefaultTy (CT.INT(Int32.fromInt(int)))
              | NONE => raise Control.Bug "exception tag is not predefined"
           )
         | NONE =>
           case ExnTagID.getNonExportIDInID tagValue of
               SOME int => CT.constDefaultTy (CT.INT(Int32.fromInt(int)))
             | NONE => raise Control.Bug "exception tag is not string"
       )
*)
     | TLCONSTANT {value,...} => CT.constDefaultTy value
     | TLGLOBALSYMBOL {ty,...} => ty
     | TLTAGOF {ty, loc} => PT.wordty
     | TLSIZEOF {ty, loc} => PT.wordty
     | TLINDEXOF {label, recordTy, loc} =>
       (staticFieldSelect btvEnv (recordTy, label, loc);
        SINGLETONty (INDEXty (label, recordTy)))
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
     | TLARRAY {sizeExp, initialValue, elementTy, isMutable, loc} => 
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
         RAWty{tyCon = PT.arrayTyCon, args = [initialValueTy]}
       end
     | TLCOPYARRAY {srcExp, srcIndexExp, dstExp, dstIndexExp, lengthExp, elementTy, loc } => 
       let
         val arrayTy = makeArrayTy elementTy

         val srcExpTy = typecheckExp btvEnv srcExp
         val _ = 
             eqTyList [(srcExpTy, arrayTy)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 27",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = arrayTy,
                              expType = srcExpTy
                             }
                        )
         val srcIndexExpTy = typecheckExp btvEnv srcIndexExp
         val _ = 
             eqTyList [(srcIndexExpTy, PT.intty)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 28",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = PT.intty,
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
                         "typecheckExp 29",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = arrayTy,
                              expType = dstExpTy
                             }
                        )
         val dstIndexExpTy = typecheckExp btvEnv dstIndexExp
         val _ = 
             eqTyList [(dstIndexExpTy, PT.intty)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 28",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = PT.intty,
                              expType = dstIndexExpTy
                             }
                        )
         val lengthExpTy = typecheckExp btvEnv lengthExp
         val _ = 
             eqTyList [(lengthExpTy, PT.intty)]
             handle Eqty => 
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 30",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = PT.intty,
                              expType = lengthExpTy
                             }
                        )
       in 
         PT.unitty
       end
     | TLPRIMAPPLY {primInfo, argExpList, instTyList, loc} => 
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
     | TLSELECT {recordExp, indexExp, label, recordTy, resultTy = resultTyAnnotation, loc} => 
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
         val indexExpTy = typecheckExp btvEnv indexExp
         val _ =
             eqTyList
               [(indexExpTy, SINGLETONty (INDEXty (label, recordTy)))]
             handle Eqty =>
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 16-2",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = indexExpTy,
                              expType = SINGLETONty (INDEXty (label, recordTy))
                             }
                        )
         val resultTy = staticFieldSelect btvEnv (recordTy, label, loc)
         val _ = 
             eqTyList [(resultTy, resultTyAnnotation)]
             handle Eqty =>
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 16-3",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = resultTyAnnotation,
                              expType = resultTy
                             }
                        )
       in
         resultTy
       end
     | TLMODIFY {recordExp, recordTy, indexExp, label, valueExp, loc} => 
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
         val indexExpTy = typecheckExp btvEnv indexExp
         val _ = 
             eqTyList
               [(indexExpTy, SINGLETONty (INDEXty (label, recordTy)))]
             handle Eqty =>
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 18",
                         E.TypeAndAnnotationMismatch
                             {
                              annotation = indexExpTy,
                              expType = SINGLETONty (INDEXty (label, recordTy))
                             }
                        )
         val fieldTy = staticFieldSelect btvEnv (recordTy, label, loc)
         val valueTy = typecheckExp btvEnv valueExp
         val _ = 
             eqTyList [(valueTy, fieldTy)]
             handle Eqty =>
                    E.enqueueDiagnosis 
                        (
                         loc,
                         "typecheckExp 18-2",
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
                 val polyArity = BoundTypeVarID.Map.numItems boundtvars 
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
             | _ => 
               raise 
                 Control.Bug 
                 "instantiate non poly ty in typecheckExp (typedlambda/main/TypeCheclTypedLambda.sml)"
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
                   (
                    print "typecheck TLSWITCH\n";
                    print (TypedLambdaFormatter.tlexpToString tlexp);
                    print "\n";
                    print (TypedLambdaFormatter.tlexpToString switchExp);
                    print "\n";
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
         case TU.derefTy expTy of
           BOUNDVARty _ =>
           E.enqueueDiagnosis 
             (
              loc,
              "typecheckExp 27",
              E.CompilerCast 
                {
                  source = expTy,
                  target = targetTy
                }
             )
         | _ => ();
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
         (print "*** typecheckTlDecl*** \n";
          print (Control.prettyPrint (TypedLambda.format_tldecl nil tldecl));
          print "\n";
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

  and typecheckTldeclList btvEnv  nil = ()
    | typecheckTldeclList btvEnv (tldecl::tldeclList) =
      (typecheckTldecl btvEnv tldecl;
       typecheckTldeclList btvEnv tldeclList)

in

  fun typecheckBasicBlock basicBlock = 
      case basicBlock of
          TLVALBLOCK {code, exnIDSet} =>
          (map (typecheckTldecl emptyBtvEnv) code;())
        | TLLINKFUNCTORBLOCK _ => ()

  fun typecheckTopBlock topBlock =
      case topBlock of
          TLBASICBLOCK basicBlock =>
          typecheckBasicBlock basicBlock
        | TLFUNCTORBLOCK {bodyCode, ...} => 
          let
              val originalMode = !Control.doFunctorCompile
              val _ = Control.doFunctorCompile := true
              val _ = map typecheckBasicBlock bodyCode
          in Control.doFunctorCompile := originalMode end

  fun typecheck topGroupList = 
      (
       E.initializeTypecheckError();
       map typecheckTopBlock topGroupList;
       E.getDiagnoses()
       )
      handle NotYet => E.getDiagnoses()
      
end
end
