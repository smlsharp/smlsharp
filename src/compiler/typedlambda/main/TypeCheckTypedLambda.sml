(**
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori 
 *)
structure TypeCheckTypedLambda = struct
local

 (* for debugging *)
  fun printTy ty = print (TypeFormatter.tyToString ty ^ "\n")
  fun debugprint x = if false then (print x) else () 

  open TypedLambda Types
  exception Eqty
  exception ApplyTy
  exception NotYet
  structure CT = ConstantTerm
  structure E = TypeCheckTypedLambdaError
  structure TU = TypesUtils
  structure PT = PredefinedTypes
  val emptyBtvEnv = IEnv.empty
  fun extendBtvEnv (oldBtvEnv, newBtvEnv) = IEnv.unionWith #2 (oldBtvEnv, newBtvEnv)

  fun printTlexp tlexp = print (Control.prettyPrint (TypedLambda.typedtlexp nil tlexp) ^ "\n")


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
    if i1 > i2 then BtvEquiv.add(btvEquiv,(i2,i1))
    else BtvEquiv.add(btvEquiv,(i1,i2))
  fun isBtvEquiv (btvEquiv, (i1,i2)) =
    if i1 > i2 then BtvEquiv.member(btvEquiv,(i2,i1))
    else BtvEquiv.member(btvEquiv,(i1,i2))
  val emptyBtvEquiv = BtvEquiv.empty


  fun eqTyList L =
    let
      (*
       * the first parameter btvEquiv is an equivalence relation on
       * bound type variables.
       *
       *)
      fun eqTy btvEquiv (ty1, ty2) = 
          case (ty1, ty2) of
              (TYVARty (ref(SUBSTITUTED derefTy1)), _) => 
              (debugprint "\n a1 \n";eqTy btvEquiv (derefTy1, ty2))
            | (_, TYVARty (ref(SUBSTITUTED derefTy2))) => 
              (debugprint "\n a2 \n";eqTy btvEquiv (ty1, derefTy2))
            | (ALIASty(_, ty1), ty2) => 
              (debugprint "\n a3 \n";eqTy btvEquiv (ty1, ty2))
            | (ty1, ALIASty(_, ty2)) => (debugprint "\n a4 \n";eqTy btvEquiv (ty1, ty2))
            | (ERRORty, _) => ()
            | (_, ERRORty) => ()
            | (ABSSPECty(ty11, ty12), ty2) => 
              (debugprint "\n a11.1 \n";eqTy btvEquiv (ty11,ty2))
            | (ty1, ABSSPECty(ty21, ty22)) => 
              (debugprint "\n a11.2 \n";eqTy btvEquiv (ty1,ty21))
            | (BOUNDVARty tv1, BOUNDVARty tv2) => 
                (debugprint "\n a5 \n";if tv1 = tv2 orelse isBtvEquiv (btvEquiv,(tv1,tv2)) then () 
                else raise Eqty)
            | (BOUNDVARty _, _) => (debugprint "\n a6 \n";raise Eqty)
            | (_, BOUNDVARty _) => (debugprint "\n a7 \n";raise Eqty)
            | (DUMMYty n2, DUMMYty n1) => (debugprint "\n a8 \n";if n1 = n2 then () else raise Eqty)
            | (DUMMYty _, _) => (debugprint "\n a9 \n";raise Eqty)
            | (_, DUMMYty _) => (debugprint "\n a10 \n";raise Eqty)
            | (TYVARty(ref(TVAR {id = id1, ...})), TYVARty(ref(TVAR {id = id2, ...}))) =>
              (debugprint "\n a13 \n";if id1 = id2 then () else raise Eqty)
            | (TYVARty _, _) => (debugprint "\n a14 \n";raise Eqty)
            | (_, TYVARty _) => (debugprint "\n a15 \n";raise Eqty)
            | (FUNMty(domainTyList1, rangeTy1), FUNMty(domainTyList2, rangeTy2)) =>
              (debugprint "\n a16 \n";
                 if length domainTyList1 = length domainTyList2
                   then eqTys btvEquiv (ListPair.zip (domainTyList1, domainTyList2)
                                        @[(rangeTy1, rangeTy2)])
                  else raise Eqty before (debugprint"eq1"))
            | (
               CONty{tyCon = {name=name1,id=id1, boxedKind = ref boxedKindValue1,...}, args = tyList1},
               CONty{tyCon = {name=name2,id=id2, boxedKind = ref boxedKindValue2,...}, args = tyList2}
               ) =>
                 (debugprint "\n a18 \n";
                  if ID.eq(id1, id2) andalso length tyList1 = length tyList2
                      then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
                  else if TU.isATOMty boxedKindValue1 andalso TU.isATOMty boxedKindValue2 
                    then ()
                  else raise Eqty)
            | (RECORDty tyFields1, RECORDty tyFields2) =>
                 let
                   val _ = debugprint "\n a19 \n"
                   val (newTyEquations, rest) = 
                     SEnv.foldri 
                     (fn (label, ty1, (newTyEquations, rest)) =>
                      let val (rest, ty2) = SEnv.remove(rest, label)
                      in ((ty1, ty2) :: newTyEquations, rest) end
                      handle LibBase.NotFound => raise Eqty)
                     (nil, tyFields2)
                     tyFields1
                 in
                   if SEnv.isEmpty rest 
                     then eqTys btvEquiv newTyEquations
                   else raise Eqty
                 end
            | (BOXEDty, BOXEDty) => (debugprint "\n a20 \n";())
            | (DOUBLEty, DOUBLEty) => (debugprint "\n a21 \n";())
            | (ATOMty, ATOMxty) => (debugprint "\n a22 \n";())
            | (INDEXty(ty1,l1), INDEXty(ty2,l2)) => 
              (debugprint "\n a23 \n";
               if l1 = l2 then eqTy btvEquiv (ty1,ty2)
               else raise Eqty)
            | (POLYty{boundtvars = btvenv1, body = body1},
               POLYty{boundtvars = btvenv2, body = body2}) =>
                 let
                   val _ = debugprint "\n a24 \n"
                   val btvlist1 = IEnv.listKeys btvenv1
                   val btvlist2 = IEnv.listKeys btvenv2
                   val newBtvEquiv =
                     if length btvlist1 = length btvlist2 then 
                       ListPair.foldl (fn (btv1, btv2, btvEquiv) =>
                                       addToBtvEquiv(btvEquiv, (btv1,btv2)))
                       btvEquiv (btvlist1, btvlist2)
                     else raise Eqty
                 in eqTy newBtvEquiv (body1, body2) 
                 end
            | (ABSTRACTty, ABSTRACTty) => (debugprint "\n a25 \n";())
            | (SPECty ty1, SPECty ty2) => 
              (debugprint "\n a26 \n";
               if !Control.doCompileObj then 
                eqTy btvEquiv (ty1, ty2)
              else 
                (print "ty1 : " ; printTy ty1;
                 print "ty2 : " ; printTy ty2;
                 raise Eqty)) 
           (*
             The following two cases are for the code like:
                datatype 'a foo = A
                A
             Here A is compiled to 0 (of int)
             but its type is ['a.'a foo]
           *)
            | (
               POLYty{boundtvars = btvenv1, body = 
                      CONty{tyCon = {name=name1,id=id1, boxedKind = ref boxedKindValue1,...}, args = tyList1}},
               CONty{tyCon = {name=name2,id=id2, boxedKind = ref boxedKindValue2,...}, args = tyList2}
               ) =>
                 (debugprint "\n a28 \n";
                  if ID.eq(id1, id2) andalso length tyList1 = length tyList2
                      then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
                  else if TU.isATOMty boxedKindValue1 andalso TU.isATOMty boxedKindValue2 
                    then ()
                  else raise Eqty)
            | (
               CONty{tyCon = {name=name2,id=id2, boxedKind = ref boxedKindValue2,...}, args = tyList2},
               POLYty{boundtvars = btvenv1, body = 
                      CONty{tyCon = {name=name1,id=id1, boxedKind = ref boxedKindValue1,...}, args = tyList1}}
               ) =>
                 (debugprint "\n a29 \n";
                  if ID.eq(id1, id2) andalso length tyList1 = length tyList2
                      then eqTys btvEquiv  (ListPair.zip (tyList1, tyList2))
                  else if TU.isATOMty boxedKindValue1 andalso TU.isATOMty boxedKindValue2 
                    then ()
                  else raise Eqty)
            | _ => (debugprint "\n a27 \n";
                 (print "ty1 : " ; printTy ty1;
                  print "ty2 : " ; printTy ty2;
                  raise Eqty))
      and eqTys btvEquiv nil = ()
        | eqTys btvEquiv ((ty1,ty2)::tail) = (eqTy btvEquiv (ty1,ty2); eqTys btvEquiv tail)
    in
      eqTys emptyBtvEquiv L
    end

in

 fun checkApplyTy (funTy, argTyList) =
   case TU.derefTy funTy of
     FUNMty(paramTyList, resultTy) => 
       let
         val numParams = length paramTyList
         val numArgTys = length argTyList
       in
         (if numParams = numArgTys then
           (eqTyList (ListPair.zip (paramTyList, argTyList));
            resultTy)
         else raise ApplyTy)
            handle Eqty => raise ApplyTy
       end
   | _ => raise ApplyTy

 fun staticFieldSelect (btvEnv:Types.btvKind IEnv.map) (recordTy, indexTy, loc) =
   case (TU.derefTy recordTy, TU.derefTy indexTy) of
     (RECORDty tyFields, INDEXty(indexRecordTy, l)) =>
       let
         val fieldTy = case SEnv.find(tyFields, l) of
                         SOME fieldTy => fieldTy
                       | _ => (E.enqueueDiagnosis(loc, 
                                                  "staticFieldSelect 1",
                                                  E.RecordFieldNotFound
                                                  {
                                                   recordTy = recordTy, 
                                                   field = l
                                                   }
                                                  );
                               Types.ERRORty
                               )
         val _ = eqTyList [(recordTy, indexRecordTy)]
           handle Eqty =>
                    E.enqueueDiagnosis (loc,
                                        "staticFieldSelect 2",
                                        E.TypeAndAnnotationMismatch
                                        {
                                         annotation = recordTy,
                                         expType = indexRecordTy
                                         }
                                        )
       in
         fieldTy
       end
   | (BOUNDVARty i, INDEXty(BOUNDVARty j, l)) =>
       if i = j then
         case IEnv.find(btvEnv, i) of
           SOME {recKind = REC fields,...} =>
             (case SEnv.find(fields, l) of 
                SOME ty => ty
              | NONE => 
                    (E.enqueueDiagnosis (loc,
                                        "staticFieldSelect 2",
                                        E.RecordFieldNotFound
                                        {
                                         recordTy = recordTy,
                                         field = l
                                         }
                                        );
                     Types.ERRORty
                     )
              )
         | _ => 
            (E.enqueueDiagnosis (loc,
                                 "staticFieldSelect 2",
                                 E.InconsistentFieldSelector
                                 {
                                  selectorType = indexTy, 
                                  recordTy = recordTy
                                  }
                                 );
             Types.ERRORty)
       else
         (E.enqueueDiagnosis (loc,
                              "staticFieldSelect 2",
                              E.InconsistentFieldSelector
                              {
                               selectorType = indexTy, 
                               recordTy = recordTy
                               }
                              );
          Types.ERRORty)
   | _ =>
       (E.enqueueDiagnosis(loc, 
                           "staticFieldSelect 3",
                           E.InconsistentFieldSelector
                           {
                            selectorType = indexTy, 
                            recordTy = recordTy
                            }
                           );
        Types.ERRORty)

 fun typecheckExp btvEnv tlexp = 
   case tlexp of
     TLFOREIGNAPPLY {
                     funTy,
                     instTyList, 
                     argExpList, 
                     argTyList,
                     loc,
                     ...
                     } =>
       let
         val instFunTy = 
           case TypesUtils.derefTy funTy of
             POLYty {boundtvars, body} => 
               let
                 val polyArity = IEnv.numItems boundtvars 
                 val numTyArgs = List.length instTyList
               in
                 if polyArity = numTyArgs
                   then TU.tpappTy(funTy, instTyList)
                 else 
                   (
                    E.enqueueDiagnosis(loc, 
                                       "typecheckExp 0",
                                       E.InstanceArityMisMatch
                                       {polyArity = polyArity, 
                                        numTyargs = numTyArgs
                                        }
                                       );
                    Types.ERRORty
                    )
               end
           | funty => (case instTyList of nil => funty 
                          | _ => (
                                  E.enqueueDiagnosis(loc, 
                                                     "typecheckExp 1",
                                                     E.InstanceArityMisMatch
                                                     {polyArity = 0,
                                                      numTyargs = length instTyList
                                                      }
                                                     );
                                  Types.ERRORty
                                  )
                         )

         val argExpTyList = map (typecheckExp btvEnv) argExpList 
         val _ = if length argTyList = length argExpTyList then
                   eqTyList (ListPair.zip (argTyList,argExpTyList))
                  else ()
         val _ =  eqTyList (ListPair.zip (argTyList,argExpTyList))
                  handle Eqty => E.enqueueDiagnosis(loc,
                                                    "typecheckExp 3",
                                                    E.ArgTyListAndArgExpTyListMismatch
                                                    {
                                                     argTyList = argTyList, 
                                                     argExpTyList = argExpTyList
                                                     }
                                                    )
         val resultTy  = checkApplyTy (instFunTy, argExpTyList)
                          handle ApplyTy =>
                            (E.enqueueDiagnosis (loc,
                                                 "typecheckExp 4",
                                                 E.OperatorOperandMismatch
                                                 {
                                                  funTy = instFunTy,
                                                  argTyList = argExpTyList
                                                  });
                             ERRORty
                             )
       in
         resultTy
       end

   | TLEXPORTCALLBACK {funExp, instTyList, argTyList, resultTy, loc} =>
       let
         val funTy = typecheckExp btvEnv funExp
         val instFunTy =
             case TypesUtils.derefTy funTy of
               POLYty {boundtvars, body} => 
                 let
                   val polyArity = IEnv.numItems boundtvars 
                   val numTyArgs = List.length instTyList
                 in
                   if polyArity = numTyArgs
                   then TU.tpappTy(funTy, instTyList)
                   else 
                     (
                      E.enqueueDiagnosis(loc, 
                                         "typecheckExp 36",
                                         E.InstanceArityMisMatch
                                         {polyArity = polyArity, 
                                          numTyargs = numTyArgs
                                          }
                                         );
                      Types.ERRORty
                     )
                 end
             | funty => (case instTyList of
                           nil => funty 
                         | _ => (
                                 E.enqueueDiagnosis(loc, 
                                                    "typecheckExp 37",
                                                    E.InstanceArityMisMatch
                                                    {polyArity = 0,
                                                     numTyargs = length instTyList});
                                 Types.ERRORty
                                ))
         val _ =
             (case TypesUtils.derefTy instFunTy of
                FUNMty (paramTyList, retTy) =>
                if length paramTyList = length argTyList
                then eqTyList ((retTy, resultTy)
                               :: ListPair.zip (paramTyList, argTyList))
                else raise ApplyTy
              | _ => raise ApplyTy)
             handle ApplyTy => E.enqueueDiagnosis(loc, 
                                                  "typecheckExp 38",
                                                  E.OperatorOperandMismatch
                                                      {
                                                       funTy = instFunTy,
                                                       argTyList = argTyList
                                                      })
       in
         PT.ptrty
       end             

   | TLSIZEOF {ty, loc} => PT.intty
   | TLCONSTANT {value = constant, loc} => CT.constDefaultTy constant
   | TLEXCEPTIONTAG {tagValue, loc} => CT.constDefaultTy (INT(Int32.fromInt(tagValue)))
   | TLVAR {varInfo = varIdInfo, loc} => #ty varIdInfo
   | TLGETGLOBAL (string, ty, loc) => ty
   | TLGETFIELD {arrayExp, indexExp, elementTy, loc} => elementTy
   | TLSETFIELD {valueExp, arrayExp, indexExp, elementTy, loc} => 
     PT.unitty
   | TLGETGLOBALVALUE {arrayIndex, offset, ty, loc} => ty
   | TLSETGLOBALVALUE {arrayIndex, offset, valueExp, ty, loc} => 
     PT.unitty
   | TLINITARRAY {arrayIndex, size, elemTy, loc} =>
     PT.unitty
   | TLARRAY {sizeExp, initialValue, elementTy, resultTy, loc} => 
       let
         val initialValueTy = typecheckExp btvEnv initialValue
         val _ = eqTyList [(initialValueTy, elementTy)]
           handle Eqty => 
             E.enqueueDiagnosis (loc,
                                 "typecheckExp 5",
                                 E.TypeAndAnnotationMismatch
                                 {
                                  annotation = elementTy,
                                  expType = initialValueTy
                                  }
                                 )
       in
         resultTy
       end
   | TLPRIMAPPLY {primOp, instTyList, argExpList, loc} => 
       let
         val funTy = #ty primOp
         val instFunTy = 
           case TypesUtils.derefTy funTy of
             POLYty {boundtvars, body} => 
               let
                 val polyArity = IEnv.numItems boundtvars 
                 val numTyArgs = List.length instTyList
               in
                 if polyArity = numTyArgs
                   then TU.tpappTy(funTy, instTyList)
                 else 
                   (
                    E.enqueueDiagnosis(loc, 
                                       "typecheckExp 6",
                                       E.InstanceArityMisMatch
                                       {polyArity = polyArity, 
                                        numTyargs = numTyArgs
                                        }
                                       );
                    Types.ERRORty
                    )
               end
           | FUNMty _ => (case instTyList of 
                               nil => funTy
                             | _ => (
                                     print "typecheckExp 8\n";
                                     print (#name primOp);
                                     print "\n";
                                     E.enqueueDiagnosis(loc, 
                                                        "typecheckExp 8",
                                                        E.InstanceArityMisMatch
                                                        {polyArity = 0, 
                                                         numTyargs = length instTyList
                                                         }
                                                        );
                                     Types.ERRORty
                                     )
                           )
         val argExpTyList = map (typecheckExp btvEnv) argExpList
         val resultTy  = checkApplyTy (instFunTy, argExpTyList)
                          handle ApplyTy =>
                            (E.enqueueDiagnosis (loc,
                                                 "typecheckExp 9",
                                                 E.OperatorOperandMismatch
                                                 {
                                                  funTy = instFunTy,
                                                  argTyList = argExpTyList
                                                  });
                             ERRORty
                             )
       in
         resultTy
       end
   | TLAPPM {funExp, funTy, argExpList, loc} => 
       let
         val expFunTy = typecheckExp btvEnv funExp
         val _ = eqTyList [(funTy, expFunTy)]
           handle Eqty => 
             E.enqueueDiagnosis (loc,
                                 "typecheckExp 12",
                                 E.TypeAndAnnotationMismatch
                                 {
                                  annotation = funTy,
                                  expType = expFunTy
                                  }
                                 )
         val argExpTyList = map  (typecheckExp btvEnv) argExpList
         val resultTy  = checkApplyTy (funTy, argExpTyList)
                          handle ApplyTy =>
                            (E.enqueueDiagnosis (loc,
                                                 "typecheckExp 13",
                                                 E.OperatorOperandMismatch
                                                 {
                                                  funTy = funTy,
                                                  argTyList = argExpTyList
                                                  });
                             ERRORty
                             )
       in
         resultTy
       end
   | TLMONOLET {binds=varIdInfoTlexpList, bodyExp=tlexp, loc} => 
       let
         val _ =
           map (fn ({ty = varidTy,...}, tlexp) =>
                let
                  val expTy = typecheckExp btvEnv tlexp
                in
                  (eqTyList [(varidTy, expTy)])
                  handle Eqty =>
                    E.enqueueDiagnosis (loc,
                                        "typecheckExp 14",
                                        E.TypeAndAnnotationMismatch
                                        {
                                         annotation = varidTy,
                                         expType = expTy
                                         }
                                        )
                end
                )
           varIdInfoTlexpList
       in
         typecheckExp btvEnv tlexp
       end
   | TLLET {localDeclList = tldeclList, mainExpList = tlexpList, mainExpTyList = tyList, loc} => 
       let
         val _ = typecheckTldeclList btvEnv tldeclList
         val argExpTyList = map (typecheckExp btvEnv) tlexpList
         val _ = (if length tyList = length argExpTyList then
                   eqTyList (ListPair.zip (tyList, argExpTyList))
                  else E.enqueueDiagnosis(loc,
                                          "typecheckExp 15",
                                          E.ArgNumAndArgTyListMisMatch
                                          {
                                           numArgs = length argExpTyList,
                                           numArgTys = length tyList
                                           }
                                          )
                  )
           handle Eqty => E.enqueueDiagnosis(loc,
                                             "typecheckExp 16",
                                             E.ArgTyListAndArgExpTyListMismatch
                                             {
                                              argTyList = tyList, 
                                              argExpTyList = argExpTyList
                                              }
                                             )
       in
         List.last tyList
       end
   | TLRECORD {expList=tlexpList, internalTy=ty, externalTy=tyopt, loc=loc} => 
       let
         val expTyList = map (typecheckExp btvEnv) tlexpList
         val tyList = case TU.derefTy ty of
                       RECORDty tyFields =>
                         SEnv.listItems tyFields
                     | _ => 
                         (E.enqueueDiagnosis(loc, 
                                             "typecheckExp 17",
                                             E.RecordTermDoNotHaveARecordType ty
                                             );
                          map (fn x => Types.ERRORty) tlexpList
                          )
         val _ = (if length tyList = length expTyList then
                   eqTyList (ListPair.zip (tyList, expTyList))
                  else E.enqueueDiagnosis(loc,
                                          "typecheckExp 18",
                                          E.ArgNumAndArgTyListMisMatch
                                          {
                                           numArgs = length expTyList,
                                           numArgTys = length tyList
                                           }
                                          )
                  )
           handle Eqty => 
             (printTlexp tlexp;
              E.enqueueDiagnosis(loc,
                                 "typecheckExp 19",
                                 E.ArgTyListAndArgExpTyListMismatch
                                 {
                                  argTyList = tyList, 
                                  argExpTyList = expTyList
                                  }
                                 )
              )
       in
         case tyopt of 
           SOME exteranlTy => exteranlTy 
         | _ => ty
       end
   | TLSELECT {recordExp, indexExp, recordTy, loc} => 
       let
         val expRecordTy = typecheckExp btvEnv recordExp
         val _ = eqTyList [(expRecordTy, recordTy)]
           handle Eqty =>
                    E.enqueueDiagnosis (loc,
                                        "typecheckExp 20",
                                        E.TypeAndAnnotationMismatch
                                        {
                                         annotation = recordTy,
                                         expType = expRecordTy
                                         }
                                        )
         val indexTy = typecheckExp btvEnv indexExp
       in
         staticFieldSelect btvEnv (recordTy, indexTy, loc)
       end
   | TLMODIFY {recordExp, recordTy, indexExp, elementExp, elementTy, loc} => 
       let
         val expRecordTy = typecheckExp btvEnv recordExp
         val _ = eqTyList [(expRecordTy, recordTy)]
           handle Eqty =>
                    E.enqueueDiagnosis (loc,
                                        "typecheckExp 21",
                                        E.TypeAndAnnotationMismatch
                                        {
                                         annotation = recordTy,
                                         expType = expRecordTy
                                         }
                                        )
         val valueTy = typecheckExp btvEnv elementExp
         val _ = eqTyList [(elementTy, valueTy)]
           handle Eqty =>
                    E.enqueueDiagnosis (loc,
                                        "typecheckExp 22",
                                        E.TypeAndAnnotationMismatch
                                        {
                                         annotation = elementTy,
                                         expType = valueTy
                                         }
                                        )
         val indexTy = typecheckExp btvEnv indexExp
         val fieldTy = staticFieldSelect btvEnv (recordTy, indexTy, loc)
         val _ = eqTyList [(elementTy, fieldTy)]
           handle Eqty =>
                    E.enqueueDiagnosis (loc,
                                        "typecheckExp 23",
                                        E.TypeAndAnnotationMismatch
                                        {
                                         annotation = elementTy,
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
   | TLHANDLE {exp=tlexp1, exnVar={ty=varTy,...}, handler=tlexp2, loc} => 
       let
         val tlexpTy1 = typecheckExp btvEnv tlexp1
         val _ = eqTyList [(varTy, PT.exnty)]
           handle Eqty =>
                    E.enqueueDiagnosis (loc,
                                        "typecheckExp 24",
                                        E.TypeAndAnnotationMismatch
                                        {
                                         annotation = PT.exnty,
                                         expType = varTy
                                         }
                                        )
         val tlexpTy2 = typecheckExp btvEnv tlexp2
         val _ = eqTyList [(tlexpTy1, tlexpTy2)]
           handle Eqty =>
                    E.enqueueDiagnosis (loc,
                                        "typecheckExp 25",
                                        E.TypeAndAnnotationMismatch
                                        {
                                         annotation = tlexpTy1,
                                         expType = tlexpTy2
                                         }
                                        )
       in
         tlexpTy1
       end
   | TLFNM {argVarList, bodyTy, bodyExp, loc} => 
       let
         val parmTyList = map #ty argVarList
         val bodyExpTy = typecheckExp btvEnv bodyExp
         val _ = eqTyList [(bodyTy, bodyExpTy)]
           handle Eqty =>
                    E.enqueueDiagnosis (loc,
                                        "typecheckExp 26",
                                        E.TypeAndAnnotationMismatch
                                        {
                                         annotation = bodyTy,
                                         expType = bodyExpTy
                                         }
                                        )
       in
         FUNMty(parmTyList, bodyTy)
       end
   | TLPOLY {btvEnv=newBtvEnv, expTyWithoutTAbs, exp, loc} => 
       let
         val bodyExpTy = typecheckExp (extendBtvEnv(btvEnv,newBtvEnv)) exp
         val _ = eqTyList [(expTyWithoutTAbs, bodyExpTy)]
           handle Eqty =>
                    E.enqueueDiagnosis (loc,
                                        "typecheckExp 28",
                                        E.TypeAndAnnotationMismatch
                                        {
                                         annotation = expTyWithoutTAbs,
                                         expType = bodyExpTy
                                         }
                                        )
       in
         POLYty{boundtvars=newBtvEnv, body=bodyExpTy}
       end
   | TLTAPP {exp, expTy, instTyList, loc} => 
       let
         val polyExpTy = typecheckExp btvEnv exp
         val _ = eqTyList [(expTy, polyExpTy)]
           handle Eqty => E.enqueueDiagnosis (loc,
                                              "typecheckExp 29",
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
                    E.enqueueDiagnosis(loc, 
                                       "typecheckExp 30",
                                       E.InstanceArityMisMatch
                                       {polyArity = polyArity, 
                                        numTyargs = numTyArgs
                                        }
                                       );
                    Types.ERRORty
                    )
               end
       in
         instanciatedTy
       end
   | TLSWITCH {switchExp, expTy=annotatedTy, branches=constantTlexpList, defaultExp, loc} => 
       let
         val expTy = typecheckExp btvEnv switchExp
         val defaultExpTy = typecheckExp btvEnv defaultExp
         val _ = eqTyList [(annotatedTy, expTy)]
           handle Eqty =>
                    E.enqueueDiagnosis (loc,
                                        "typecheckExp 31",
                                        E.TypeAndAnnotationMismatch
                                        {
                                         annotation = annotatedTy,
                                         expType = expTy
                                         }
                                        )
         val _ = map (fn {constant, exp = tlexp} =>
                      let
                        val ruleBodyTy = typecheckExp btvEnv tlexp
                      in
                        eqTyList[(defaultExpTy,ruleBodyTy)]
                        handle Eqty =>
                          E.enqueueDiagnosis (loc,
                                              "typecheckExp 32",
                                              E.TypeAndAnnotationMismatch
                                              {
                                               annotation = defaultExpTy,
                                               expType = ruleBodyTy
                                               }
                                              )
                      end
                      )
                     constantTlexpList
       in
         defaultExpTy
       end
   | TLSEQ {expList=tlexpList, expTyList = tyList, loc} => 
       let
         val expTyList = map (typecheckExp btvEnv)  tlexpList
         val _ = (if length expTyList = length tyList then
                   eqTyList (ListPair.zip (expTyList, tyList))
                  else E.enqueueDiagnosis(loc,
                                          "typecheckExp 33",
                                          E.ArgNumAndArgTyListMisMatch
                                          {numArgs = length expTyList, 
                                           numArgTys = length tyList
                                           }
                                          )
                  )
           handle Eqty => E.enqueueDiagnosis(loc,
                                             "typecheckExp 34",
                                             E.ArgTyListAndArgExpTyListMismatch
                                             {
                                              argTyList = tyList, 
                                              argExpTyList = expTyList
                                              }
                                             )
       in
         List.last expTyList
       end
   | TLCAST {exp, targetTy, loc} => 
       let
         val expTy = typecheckExp btvEnv exp
(*
         val _ =
           E.enqueueDiagnosis(loc,
                              "typecheckExp 35",
                              E.CompilerCast
                              {
                               source = expTy, 
                               target = targetTy
                               }
                              )
*)
       in
         targetTy
       end
   | TLOFFSET {recordTy = ty, label = string, loc} => INDEXty(ty, string)

 and typecheckTldecl btvEnv tldecl = 
   case tldecl of
     TLVAL {bindList = valIdentTlexpList, loc} => 
       (map (fn {boundValIdent = valIdent, boundExp = tlexp} =>
            let
              val varidTy = case valIdent of 
                               VALIDENT {ty,...} => ty
                             | VALIDENTWILD ty =>  ty
              val expTy = typecheckExp btvEnv tlexp
            in
              (eqTyList [(varidTy, expTy)])
              handle Eqty =>
                E.enqueueDiagnosis (loc,
                                    "typecheckTldecl 1",
                                    E.TypeAndAnnotationMismatch
                                    {
                                     annotation = varidTy,
                                     expType = expTy
                                     }
                                    )
            end
            )
        valIdentTlexpList;
        ()
        )
   | TLVALREC {recbindList = varIdInfoTyTlexpList, loc} => 
       (map (fn {boundVar={ty=varidTy,...}, boundTy = ty, boundExp = tlexp} =>
            let
              val expTy = typecheckExp btvEnv tlexp
            in
              (eqTyList [(varidTy, expTy)]
               handle Eqty =>
                 E.enqueueDiagnosis (loc,
                                     "typecheckTldecl 2",
                                     E.TypeAndAnnotationMismatch
                                     {
                                      annotation = varidTy,
                                      expType = expTy
                                      }
                                     );
                 eqTyList [(ty, expTy)]
                 handle Eqty =>
                   E.enqueueDiagnosis (loc,
                                       "typecheckTldecl 3",
                                       E.TypeAndAnnotationMismatch
                                       {
                                        annotation = ty,
                                        expType = expTy
                                        }
                                       )
                   )
            end
            )
       varIdInfoTyTlexpList;
       ()
       )
   | TLVALPOLYREC {btvEnv = btvKindIEnvMap, indexVars = varIdInfoList, recbindList = varIdInfoTyTlexpList, loc} => 
     (*
      * we ignore varIdInfoList which is the set of index variables
      *)
       (map (fn {boundVar = {ty=varidTy,...}, boundTy = ty, boundExp = tlexp} =>
            let
              val expTy = typecheckExp (extendBtvEnv(btvEnv,btvKindIEnvMap)) tlexp
            in
              (eqTyList [(varidTy, expTy)]
               handle Eqty =>
                 E.enqueueDiagnosis (loc,
                                     "typecheckTldecl 4",
                                     E.TypeAndAnnotationMismatch
                                     {
                                      annotation = varidTy,
                                      expType = expTy
                                      }
                                     );
                 eqTyList [(ty, expTy)]
                 handle Eqty =>
                   E.enqueueDiagnosis (loc,
                                       "typecheckTldecl 5",
                                       E.TypeAndAnnotationMismatch
                                       {
                                        annotation = ty,
                                        expType = expTy
                                        }
                                       )
                   )
            end
            )
       varIdInfoTyTlexpList;
       ()
       )
   | TLLOCALDEC {localDeclList = tldeclList1, mainDeclList = tldeclList2, loc} => 
       (typecheckTldeclList btvEnv tldeclList1;
        typecheckTldeclList btvEnv tldeclList2;
        ())
   | TLSETGLOBAL (string, tlexp, loc) => ()
   | TLEMPTY loc => ()

  and typecheckTldeclList btvEnv  nil = ()
    | typecheckTldeclList btvEnv (tldecl::tldeclList) =
      (typecheckTldecl btvEnv tldecl;
       typecheckTldeclList btvEnv tldeclList)

  fun typechekTypedLambda tldeclList = 
      (
       E.initializeTypecheckError();
       map (typecheckTldecl emptyBtvEnv) tldeclList;
       E.getDiagnoses()
       )
      handle NotYet => E.getDiagnoses()
      
end
end
