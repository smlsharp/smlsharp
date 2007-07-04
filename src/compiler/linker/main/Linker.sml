(**
 * Linker
 *
 * @copyright (c) 2006, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: Linker.sml,v 1.23 2007/04/19 05:06:52 ducnh Exp $
 *)
structure Linker:
          sig
              val link : string -> string list -> unit
              val useObj : {moduleEnv : StaticModuleEnv.moduleEnv,
                             topTypeContext : InitialTypeContext.topTypeContext}
                           * LinkageUnit.linkageUnit
                           -> TypeContext.context *
                              StaticModuleEnv.deltaModuleEnv *
                              TypedLambda.tldecl list
          end =
struct
  local
      val tyBindToString = Control.prettyPrint o Types.format_tyBindInfo nil
      fun printTyBind tyBind = print (tyBindToString tyBind ^ "\n")
      structure C = Control
      structure TC = TypeContext
      structure ITC = InitialTypeContext
      structure TCU = TypeContextUtils
      structure SME = StaticModuleEnv
      structure STE = StaticTypeEnv
      structure STEU = StaticTypeEnvUtils
      structure IMC = InitialModuleContext
      structure TO = TopObject
      structure PE = PathEnv
      structure SC = SigCheck
      structure FAU = FunctorApplyUtils
      structure P = Pickle
      structure E = TypeInferenceError
      structure UE = UserError 
      structure LE = LinkError
      structure SU = SigUtils
      structure PT = PredefinedTypes

      exception ExSigCheckFailure
      open LinkageUnit
      open LinkerUtils
      val debug = ref true
      fun printDebug x = if !debug then print x else ()

  in
    (*************************************************************)  

    val emptyImportTypeEnv = STE.emptyTypeEnv
    val emptyExportTypeEnv = STE.emptyTypeEnv
    val emptyImportModuleEnv = PathEnv.emptyPathBasis
    val emptyExportModuleEnv = PathEnv.emptyPathBasis

    (*************************************************************)
    (* dupcliate index *)
    exception exDuplicateElem 

    fun allocateActualIndexInTyInstValIndexList 
            substTyEnv freeGlobalArrayIndex freeEntryPointer hiddenValIndexList =
        foldl 
        (fn ((pathVar, globalIndex, ty),
             (freeGlobalArrayIndex,
              freeEntryPointer,
              indexEnv,
              arrayHdElemIndices,
              newTyInstValIndexList)) =>
            let
                val (newPageFlag, newFreeGlobalArrayIndex, newFreeEntryPointer, newGlobalIndex) =
                    IndexAllocator.allocateActualIndexAtLinking 
                        (freeGlobalArrayIndex,
                         freeEntryPointer, 
                         {displayName = PE.pathVarToString(pathVar), 
                          ty = substTy (injectSubstTyEnvInSubstContext substTyEnv) ty})
            in
                (newFreeGlobalArrayIndex,
                 newFreeEntryPointer,
                 IndexEnv.insert(indexEnv,
                                 (getKeyInIndex globalIndex),
                                 newGlobalIndex),
                 if newPageFlag then arrayHdElemIndices @ [newGlobalIndex] else arrayHdElemIndices,
                 newTyInstValIndexList @ [(pathVar, newGlobalIndex, ty)])
            end)
        (freeGlobalArrayIndex, freeEntryPointer, IndexEnv.empty, nil, nil)
        hiddenValIndexList

    fun allocateAbstractIndexInTyInstValIndexList 
            (substTyConEnv, substTyConIdEnv) freeEntryPointer hiddenValIndexList =
        foldl 
        (fn ((pathVar, globalIndex, ty),
             (freeEntryPointer,
              indexEnv,
              newTyInstValIndexList)) =>
            let
                val (newFreeEntryPointer, newGlobalIndex) =
                    IndexAllocator.allocateAbstractIndex freeEntryPointer
                val newTy = 
                    let
                        val (ty1, visited) = 
                            TCU.substTyConIdInTy ID.Set.empty substTyConIdEnv ty
                        val (ty2, visited) =
                            TCU.substTyConInTy ID.Set.empty substTyConEnv ty1
                    in
                        ty2
                    end
                        
            in
                (
                 newFreeEntryPointer,
                 IndexEnv.insert(indexEnv,
                                 (getKeyInIndex globalIndex),
                                 newGlobalIndex),
                 newTyInstValIndexList @ [(pathVar, newGlobalIndex, newTy)]
                 )
            end)
        (freeEntryPointer, IndexEnv.empty, nil)
        hiddenValIndexList


    (*
     * merge object files,
     * allocate abstract index to exported value identifier
     *)
    fun reAllocateAbstractIndexInExportVarEnv 
            exportVarEnv accExportVarEnv freeEntryPointer
      =
      SEnv.foldli (fn (varName,
                       PE.TopItem (pathVar, index, ty),
                         (freeEntryPointer, 
                          indexEnv, 
                          hiddenValIndexList,
                          exportVarEnv)) =>
                      let
                          val (newFreeEntryPointer, newIndex) =
                              IndexAllocator.allocateAbstractIndex freeEntryPointer
                          val newIndexEnv = 
                              IndexEnv.insert(indexEnv,
                                              (getKeyInIndex index),
                                              newIndex)
                          val newExportVarEnv =
                              SEnv.insert (exportVarEnv,
                                           varName, 
                                           PE.TopItem(pathVar, newIndex, ty))
                      in
                          case SEnv.find(accExportVarEnv, varName) of
                              NONE =>(newFreeEntryPointer, 
                                      newIndexEnv, 
                                      hiddenValIndexList,
                                      newExportVarEnv)
                            | SOME (PE.TopItem (pathVar, index, ty)) =>
                              (newFreeEntryPointer, 
                               newIndexEnv, 
                               hiddenValIndexList @ [(pathVar,index,ty)],
                               newExportVarEnv)
                            | SOME (PE.CurItem _ ) =>
                              raise Control.Bug "CurItem occurs at linking phase"
                      end
                    | (varName, PE.CurItem _, _) => 
                      raise Control.Bug "CurItem occurs at linking phase"
                  )
                  (freeEntryPointer, IndexEnv.empty, nil, SEnv.empty)
                  exportVarEnv     

    (* 
     * allocate abstract index
     * 1. inner already exported and then imported value identifier are resolved
     * 2. outer imported value identifier are still kept their imported status
     *)
    fun reAllocateAbstractIndexInImportVarEnv 
            importVarEnv (innerTyInstImportVarEnv, outerTyInstImportVarEnv) freeEntryPointer  = 
        SEnv.foldli 
            (fn (varName, PE.TopItem (pathVar, index, ty), 
                 (freeEntryPointer, 
                  indexEnv, 
                  outerImportVarEnv)) =>
                (case SEnv.find(innerTyInstImportVarEnv, varName) of
                     SOME (PE.TopItem (pathVar, globalIndex, ty)) =>
                     (* inner resolved *)
                     (freeEntryPointer, 
                      IndexEnv.insert(indexEnv,
                                      (getKeyInIndex index),
                                      globalIndex),
                      outerImportVarEnv)
                   | SOME (PE.CurItem _) => 
                     raise Control.Bug "CurItem occurs at linking phase"
                   | NONE =>
                     (case SEnv.find(outerTyInstImportVarEnv, varName) of
                          (* already imported in previous linkageunits*)
                          SOME (PE.TopItem (pathVar, globalIndex, ty)) =>
                          (freeEntryPointer, 
                           IndexEnv.insert(indexEnv,
                                           (getKeyInIndex index),
                                           globalIndex),
                           outerImportVarEnv)
                        | SOME (PE.CurItem _) => 
                          raise Control.Bug "CurItem occurs at linking phase"
                        (* outer imported *)
                        | NONE =>
                          let
                              val (newFreeEntryPointer, newIndex) =
                                  IndexAllocator.allocateAbstractIndex freeEntryPointer
                              val newIndexEnv = 
                                  IndexEnv.insert(indexEnv,
                                                  (getKeyInIndex index),
                                                  newIndex)
                              val newOuterImportVarEnv =
                                  SEnv.insert (outerImportVarEnv,
                                               varName, 
                                               PE.TopItem(pathVar, newIndex, ty))
                          in
                              (newFreeEntryPointer, 
                               newIndexEnv, 
                               newOuterImportVarEnv)
                          end))
              | (varName, PE.CurItem _, _ ) => 
                raise Control.Bug "CurItem occurs at linking phase")
            (freeEntryPointer, IndexEnv.empty, SEnv.empty)
            importVarEnv
                         
    fun reAllocateAbstractIndexInExportStrEnv 
            exportStrEnv accExportStrEnv freeEntryPointer 
      =
      SEnv.foldli (fn (strName, 
                       PE.PATHAUX (subExportVarEnv, subExportStrEnv),
                       (freeEntryPointer, 
                        indexEnv, 
                        hiddenValIndexList,
                        exportStrEnv)) =>
                      let
                          val (freeEntryPointer1, 
                               indexEnv1:TO.globalIndex IndexEnv.map, 
                               hiddenValIndexList1,
                               newSubExportVarEnv) =
                              reAllocateAbstractIndexInExportVarEnv 
                                  subExportVarEnv 
                                  SEnv.empty
                                  freeEntryPointer 
                          val (freeEntryPointer2, 
                               indexEnv2:TO.globalIndex IndexEnv.map, 
                               hiddenValIndexList2,
                               newSubExportStrEnv)
                            =
                            reAllocateAbstractIndexInExportStrEnv
                                subExportStrEnv 
                                SEnv.empty
                                freeEntryPointer1
                      in
                          case SEnv.find(accExportStrEnv, strName) of
                              NONE =>
                              (freeEntryPointer2,
                               (IndexEnv.unionWithi 
                                    (fn _ => raise exDuplicateElem)
                                    (
                                     (IndexEnv.unionWithi 
                                          (fn _ => raise exDuplicateElem) (indexEnv2, indexEnv1)),
                                     indexEnv)),
                               hiddenValIndexList,
                               SEnv.insert(exportStrEnv,
                                           strName,
                                           PE.PATHAUX (newSubExportVarEnv,
                                                       newSubExportStrEnv)
                                           )
                               )
                            | SOME (PE.PATHAUX (subAccExportVarEnv, subAccExportStrEnv)) =>
                              let
                                  val indices1 = calcValIndexListPathVarEnv subAccExportVarEnv
                                  val indices2 = calcValIndexListPathStrEnv subAccExportStrEnv
                              in
                                  (freeEntryPointer2,
                                   (IndexEnv.unionWithi 
                                        (fn _ => raise exDuplicateElem)
                                        (
                                         (IndexEnv.unionWithi 
                                              (fn _ => raise exDuplicateElem) (indexEnv2, indexEnv1)),
                                         indexEnv)),
                                   hiddenValIndexList @ indices1 @ indices2,
                                   SEnv.insert(exportStrEnv,
                                               strName,
                                               PE.PATHAUX (newSubExportVarEnv,
                                                           newSubExportStrEnv)
                                               )
                                   )
                              end
                              
                      end
                          )
                  (freeEntryPointer, IndexEnv.empty, nil, SEnv.empty)
                  exportStrEnv

    (*
     * 1. inner exported are resolved
     * 2. return import = already outer imported + incremental outer import
     *  already imported is returned for easy merging of outer import value identifier
     *  (import structure merging need not go deep inside)
     *)                    
    fun reAllocateAbstractIndexInImportStrEnv 
            importStrEnv (innerTyInstImportStrEnv, outerTyInstExportStrEnv) freeEntryPointer  
      =
      SEnv.foldli 
          (fn (strName, PE.PATHAUX (subImportVarEnv, subImportStrEnv),
               (freeEntryPointer, 
                indexEnv, 
                outerImportStrEnv)) 
              =>
              case SEnv.find(innerTyInstImportStrEnv, strName) of
                  SOME (PE.PATHAUX (subInnerTyInstImportVarEnv,
                                    subInnerTyInstImportStrEnv)) =>
                  (* inner resolved *)
                  let
                      val (freeEntryPointer1, 
                           indexEnv1, 
                           newSubOuterImportVarEnv) =
                          reAllocateAbstractIndexInImportVarEnv 
                              subImportVarEnv
                              (subInnerTyInstImportVarEnv, SEnv.empty)
                              freeEntryPointer
                      val (freeEntryPointer2,
                           indexEnv2,
                           newSubOuterImportStrEnv) =
                          reAllocateAbstractIndexInImportStrEnv 
                              subImportStrEnv
                              (subInnerTyInstImportStrEnv, SEnv.empty)
                              freeEntryPointer1 
                      val _ = if SEnv.numItems(newSubOuterImportVarEnv) <> 0 then
                                  raise LE.ImportUnExportedValueIdentifier
                                            {name = #1 (ListPair.unzip
                                                            (SEnv.listItemsi newSubOuterImportVarEnv))
                                             }
                              else ()
                      val _ = if SEnv.numItems(newSubOuterImportStrEnv) <> 0 then
                                  raise LE.ImportUnExportedStructureIdentifier
                                        {name = #1(ListPair.unzip
                                                   (SEnv.listItemsi newSubOuterImportStrEnv))
                                         }
                              else ()
                  in
                      (freeEntryPointer2,
                       (IndexEnv.unionWithi
                            (fn _ => raise exDuplicateElem) 
                            ((IndexEnv.unionWithi
                                  (fn _ => raise exDuplicateElem)
                                  (indexEnv1, indexEnv2)), 
                             indexEnv)),
                       outerImportStrEnv
                       )
                  end
                | NONE => (* outer imported *)
                  (case SEnv.find(outerTyInstExportStrEnv, strName) of
                       (* already imported *)
                       SOME (PE.PATHAUX (subOuterTyInstExportVarEnv,
                                         subOuterTyInstExportStrEnv)) =>
                       let
                           val (freeEntryPointer1, 
                                indexEnv1, 
                                newSubOuterImportVarEnv) =
                               reAllocateAbstractIndexInImportVarEnv 
                                   subImportVarEnv
                                   (SEnv.empty, subOuterTyInstExportVarEnv)
                                   freeEntryPointer
                           val (freeEntryPointer2,
                                indexEnv2,
                                newSubOuterImportStrEnv) =
                               reAllocateAbstractIndexInImportStrEnv
                                   subImportStrEnv
                                   (SEnv.empty, subOuterTyInstExportStrEnv)
                                   freeEntryPointer1 
                           val newOuterImportStrEnv =
                               SEnv.insert(outerImportStrEnv,
                                           strName,
                                           PE.PATHAUX (newSubOuterImportVarEnv,
                                                       newSubOuterImportStrEnv))
                       in
                           (freeEntryPointer2,
                            (IndexEnv.unionWithi
                                 (fn _ => raise exDuplicateElem) 
                                 ((IndexEnv.unionWithi
                                       (fn _ => raise exDuplicateElem)
                                       (indexEnv1, indexEnv2)), 
                                  indexEnv)),
                            newOuterImportStrEnv)
                       end
                     | NONE =>
                       (* newly imported *) 
                       let
                           val (freeEntryPointer1, 
                                indexEnv1, 
                                newSubOuterImportVarEnv) =
                               reAllocateAbstractIndexInImportVarEnv subImportVarEnv
                                                                     (SEnv.empty, SEnv.empty)
                                                                     freeEntryPointer
                           val (freeEntryPointer2,
                                indexEnv2,
                                newSubOuterImportStrEnv) =
                               reAllocateAbstractIndexInImportStrEnv subImportStrEnv
                                                                     (SEnv.empty, SEnv.empty)
                                                                     freeEntryPointer1
                           val newOuterImportStrEnv =
                               SEnv.insert(outerImportStrEnv,
                                           strName,
                                           PE.PATHAUX (newSubOuterImportVarEnv,
                                                       newSubOuterImportStrEnv))
                       in
                           (freeEntryPointer2,
                            (IndexEnv.unionWithi
                                 (fn _ => raise exDuplicateElem) 
                                 ((IndexEnv.unionWithi
                                       (fn _ => raise exDuplicateElem)
                                       (indexEnv1, indexEnv2)), 
                                  indexEnv)),
                            newOuterImportStrEnv)
                       end
                       )
                  )
            (freeEntryPointer, IndexEnv.empty, SEnv.empty)
            importStrEnv

    fun reAllocateAbstractIndexInImportModuleEnv
            importModuleEnv (innerTyInstImportModuleEnv, outerTyInstImportModuleEnv) freeEntryPointer 
      =
      let
          val (importFunEnv, (importVarEnv, importStrEnv)) = importModuleEnv
          val (_, (innerTyInstImportVarEnv, innerTyInstImportStrEnv)) 
            = innerTyInstImportModuleEnv
          val (_, (outerTyInstImportVarEnv, outerTyInstImportStrEnv)) 
            = outerTyInstImportModuleEnv
          val (freeEntryPointer1, 
               indexEnv1, 
               newImportVarEnv) =
              reAllocateAbstractIndexInImportVarEnv
                  importVarEnv (innerTyInstImportVarEnv, outerTyInstImportVarEnv) freeEntryPointer 
          val (freeEntryPointer2, 
               indexEnv2, 
               newImportStrEnv) =
              reAllocateAbstractIndexInImportStrEnv
                  importStrEnv (innerTyInstImportStrEnv, outerTyInstImportStrEnv) freeEntryPointer1
      in
          (freeEntryPointer2,
           IndexEnv.unionWithi (fn _ => raise exDuplicateElem) (indexEnv1, indexEnv2),
           (importFunEnv, (newImportVarEnv, newImportStrEnv)))
      end
          
    fun reAllocateAbstractIndexInExportModuleEnv
            exportModuleEnv accExportModuleEnv freeEntryPointer 
      =
      let
          val (exportFunEnv, (exportVarEnv,exportStrEnv)) = exportModuleEnv
          val (accExportFunEnv, (accExportVarEnv, accExportStrEnv)) = accExportModuleEnv
          val (freeEntryPointer1, indexEnv1, hiddenValIndexList1, newExportVarEnv) =
              reAllocateAbstractIndexInExportVarEnv
                  exportVarEnv accExportVarEnv freeEntryPointer
          val (freeEntryPointer2, indexEnv2, hiddenValIndexList2, newExportStrEnv) =
              reAllocateAbstractIndexInExportStrEnv
                  exportStrEnv accExportStrEnv freeEntryPointer1
      in
          (freeEntryPointer2,
           IndexEnv.unionWithi (fn _ => raise exDuplicateElem) (indexEnv1, indexEnv2),
           hiddenValIndexList1 @ hiddenValIndexList2,
           (exportFunEnv,(newExportVarEnv, newExportStrEnv)))
      end
                           
    (* accExportModuleEnv is used for compute hiddenValIndexList *)
    fun reAllocateAbstractIndexInModuleEnv
            (staticModuleEnv: SME.staticModuleEnv) 
            (innerTyInstImportModuleEnv, outerTyInstImportModuleEnv, accExportModuleEnv)
            freeEntryPointer
      =
          let
              val (freeEntryPointer1, 
                   indexEnv1, 
                   newImportModuleEnv : SME.importModuleEnv) =
                  reAllocateAbstractIndexInImportModuleEnv
                      (#importModuleEnv staticModuleEnv)
                      (innerTyInstImportModuleEnv, outerTyInstImportModuleEnv)
                      freeEntryPointer 
              val (freeEntryPointer2,
                   indexEnv2, 
                   hiddenValIndexList,
                   newExportModuleEnv : SME.exportModuleEnv) =
                  reAllocateAbstractIndexInExportModuleEnv
                      (#exportModuleEnv staticModuleEnv)
                      accExportModuleEnv
                      freeEntryPointer1
          in
              (freeEntryPointer2,
               (IndexEnv.unionWithi (fn (key,x,y) => raise exDuplicateElem) 
                                    (indexEnv1, indexEnv2)),
               hiddenValIndexList,
               (newImportModuleEnv, newExportModuleEnv))
          end

    (* link unclosed object files.
     * 1. resolve array index allocation.
     * 2. least generalization type scheme computation
     *)
    fun linkUnClosedLinkageUnits (linkageUnits : linkageUnit list)  =
        foldl (fn (linkageUnit, 
                   (codes,
                    tyConIdSet,
                    freeEntryPointer,
                    accImportTE : STE.importTypeEnv, 
                    accExportTE : STE.exportTypeEnv, 
                    accImportME : SME.importModuleEnv, 
                    accExportME : SME.exportModuleEnv,
                    accGenerativeExnTagSet,
                    accHiddenValIndexList
                    ))
                  =>
                  let
                      val loc = getLocLinkageUnit linkageUnit
                      val importTyConIdSet = #importTyConIdSet (#staticTypeEnv linkageUnit)
                      val importTypeEnv = #importTypeEnv (#staticTypeEnv linkageUnit)
                      val exportTypeEnv = #exportTypeEnv (#staticTypeEnv linkageUnit)

                      val (implAccEnv, unResolvedLUImportEnv) = 
                          constructImplAndUnResolvedEnv (importTypeEnv, accExportTE)
                      val (resolvedLUImportEnv, implEnv) =  
                          (typeEnvToEnv(#1 (constructImplAndUnResolvedEnv (implAccEnv, importTypeEnv))),
                           typeEnvToEnv implAccEnv)

                      (**********************************************************************
                       * Unification of common type components(tySpec and tyCon) of import inteface;
                       * Do not check the equivalence of type parts
                       *)
                      val (commonAccImportEnv, outerUnResolvedLUImportEnv) 
                        = constructImplAndUnResolvedEnv (unResolvedLUImportEnv, accImportTE)
                      (* Note: substTyConEnvAccCommon is not enough for instantiating the
                       * types in the accumulated static information; the exported types 
                       * of current linkage unit may provide implementation type for those 
                       * in the range of substitution substTyConEnvAccCommon. 
                       *)
                      val (substTyConIdEnvLinkageUnit,
                           substTyConEnvLinkageUnit,
                           substTyConEnvAccCommon) =
                          unifyCommonTypeEnv
                              ((#importTyConIdSet (#staticTypeEnv linkageUnit),
                                unResolvedLUImportEnv), 
                               commonAccImportEnv)
                              handle exn => (SU.handleException (exn,loc);
                                             raise ExSigCheckFailure)
                      (**********************************************************************
                       * New linkage unit import interface construction:
                       * unified tyCons(above step) are removed from flexible tyConId set.
                       *)
                      
                      val flexibleImportTyConIdSet =
                          let
                              val fixedTyConIdSet = 
                                  ID.Set.union (domainIDMap substTyConIdEnvLinkageUnit,
                                                domainIDMap substTyConEnvLinkageUnit)
                          in
                              ID.Set.difference (importTyConIdSet, fixedTyConIdSet)
                          end
                      val resolvedLUImportEnvWithCommonTyInst =
                          let
                              val (_, Env1) = 
                                  TCU.substTyConIdInEnv 
                                      ID.Set.empty
                                      substTyConIdEnvLinkageUnit
                                      resolvedLUImportEnv
                              val (_, Env2) =
                                  TCU.substTyConInEnv 
                                      ID.Set.empty 
                                      substTyConEnvLinkageUnit
                                      Env1
                          in Env2 end
                      val implEnvWithCommonTyInst =
                          let
                              val (_, Env) =
                                  TCU.substTyConInEnv 
                                      ID.Set.empty 
                                      substTyConEnvAccCommon
                                      implEnv
                          in
                              Env
                          end
                      val strictEnv = 
                          (SC.checkEnvAndSigma 
                               (implEnvWithCommonTyInst, 
                                (flexibleImportTyConIdSet, resolvedLUImportEnvWithCommonTyInst)))
                          handle exn => (SU.handleException (exn,loc); 
                                         raise ExSigCheckFailure)
                      (*****************************************************************
                       * type instantiation declaration for inner resolved parts
                       *)
                      local
                          val currentModuleEnv as {pathBasis,...} =
                              {freeGlobalArrayIndex = TO.abstractGlobalArrayIndex,
                               freeEntryPointer = freeEntryPointer,
                               pathBasis = accExportME}
                      in
                          val (tyInstCode1, instDeltaModuleEnv1) = 
                              let
                                  val previousState = !Control.doCompileObj
                                  val _ = Control.doCompileObj := true
                              in
                                  genTyInstantiationCode 
                                      (implEnvWithCommonTyInst, strictEnv) 
                                      currentModuleEnv
                                      loc
                                      before (Control.doCompileObj := previousState)
                              end
                          val freeEntryPointer = #freeEntryPointer instDeltaModuleEnv1
                          val innerTyInstValIndexList =
                              (flattenPathBasisToList (#pathBasis instDeltaModuleEnv1))
                      end
                      (*****************************************************************
                       * environments instantiation with the constructed 
                       * tyConId/tyCon substitution
                       *)
                      val substExportTyEnv = SigUtils.substTyEnvFromEnv 
                                           (resolvedLUImportEnvWithCommonTyInst, 
                                            implEnvWithCommonTyInst)

                      (******************************************************************)
                      val mergedSubstTyConEnvLinkageUnit =
                          substEffectKeepingMerge (substExportTyEnv, substTyConEnvLinkageUnit)
                      val mergedSubstTyConEnvAccEnv =
                          substEffectKeepingMerge (substExportTyEnv, substTyConEnvAccCommon)

                      (******************************************************************)
                      val unResolvedLUImportEnvWithTyInst =
                          let
                              val Env1 = 
                                  STE.substTyConIdInTypeEnv substTyConIdEnvLinkageUnit
                                                            unResolvedLUImportEnv
                              val Env2 = 
                                  STE.substTyConInTypeEnv mergedSubstTyConEnvLinkageUnit 
                                                          Env1
                          in
                              Env2
                          end
                      val commonAccImportTypeEnvWithTyInst = 
                          (* Note:
                           * substTyConEnvAccCommon : commonAccImportEnv may depends on
                           * the implementation type given in the import interface of the 
                           * new linkage unit.
                           * substTyEnv : the implementation type above may depends on the 
                           * implementation type given in the export type of accExportTE
                           *)
                          STE.substTyConInTypeEnv mergedSubstTyConEnvAccEnv 
                                                  commonAccImportEnv
                                                  
                      (*****************************************************************
                       * 1. Check common import type parts type compatibility
                       * 2. Generate anti-unified import value parts
                       *)
                      val generalizedCommonLUImportEnv =
                          compatibiltyUnify (commonAccImportTypeEnvWithTyInst,
                                             unResolvedLUImportEnvWithTyInst)
                      val (generalizedCommonLinkageUnitImportME, freeEntryPointer) = 
                          typeEnvToAbstractPathBasis 
                               generalizedCommonLUImportEnv freeEntryPointer
                      (* Current linkageUnit:
                       * generate type instantiation value declarations for 
                       * value identifier 
                       *)
                      local
                          val currentModuleEnv as {pathBasis,...} =
                              {freeGlobalArrayIndex = TO.abstractGlobalArrayIndex,
                               freeEntryPointer = freeEntryPointer,
                               pathBasis = generalizedCommonLinkageUnitImportME}
                      in
                          val (tyInstCode2, instDeltaModuleEnv2) = 
                              let
                                  val previousState = !Control.doCompileObj
                                  val _ = Control.doCompileObj := true
                                  val restrictedUnResolvedLUImportEnv =
                                      pruneUnGeneralizedInLinkageUnitImportTypeEnv
                                          (generalizedCommonLUImportEnv, 
                                           unResolvedLUImportEnvWithTyInst)
                              in
                                  (genTyInstantiationCode
                                       (typeEnvToEnv generalizedCommonLUImportEnv, 
                                        typeEnvToEnv restrictedUnResolvedLUImportEnv)
                                       currentModuleEnv
                                       loc)
                                  before (Control.doCompileObj := previousState)
                              end
                          val freeEntryPointer = #freeEntryPointer instDeltaModuleEnv2
                          val currLinkageUnitImportTyInstValIndexList =
                              (flattenPathBasisToList (#pathBasis instDeltaModuleEnv2))
                      end
                      (* Previous linkageUnits: generate type instantiation value declarations for 
                       * value identifier with type involving least generalized type 
                       *)
                      local
                          val currentModuleEnv =
                              {freeGlobalArrayIndex = TO.abstractGlobalArrayIndex,
                               freeEntryPointer = freeEntryPointer,
                               pathBasis = generalizedCommonLinkageUnitImportME}
                      in
                          val (tyInstCode3, instTyValCommonModuleEnvInAcc) = 
                              let
                                  val previousState = !Control.doCompileObj
                                  val _ = Control.doCompileObj := true
                              in
                                  (genTyInstantiationCode
                                       (typeEnvToEnv generalizedCommonLUImportEnv, 
                                        typeEnvToEnv commonAccImportTypeEnvWithTyInst)
                                       currentModuleEnv
                                       loc)
                                  before (Control.doCompileObj := previousState)
                              end
                          val freeEntryPointer = #freeEntryPointer instTyValCommonModuleEnvInAcc
                          val indexEnv3 = 
                              constructAlreadyImportValIndexEnvInPathBasis
                                  (#pathBasis instTyValCommonModuleEnvInAcc, accImportME)
                          val prevLinkageUnitTyInstValIndexList =
                              (flattenPathBasisToList (#pathBasis instTyValCommonModuleEnvInAcc))
                      end
                      (****************************************************************** 
                       * sizeTag computation. Construct sizetag term substitution which maps
                       * sizetag variable to its implementation. Suppose two object files,
                       *  # link A.smo B.smo
                       * The map invovles three parts:
                       * 1. A.smo exports, B.smo imports.
                       * eg.  A: type t = int   B: import type t end
                       * 2. A.smo imports implemented part, B.smo imports abstract type specification. 
                       * eg.  A: import type t = int  end
                       *      B: import type t end
                       * 3. A.smo import abstract type specification,
                       *    B.smo import implemented part.
                       * eg.  A: import type t end
                       *      B: import type t = int end
                       *)
                      val sizeTagSubstAccEnv = 
                          sizeTagSubstTyConSubst mergedSubstTyConEnvAccEnv
                      val sizeTagSubstLinkageUnit = 
                          sizeTagSubstTyConSubst mergedSubstTyConEnvLinkageUnit
                      (*****************************************************************
                       * exnTag Compuation:
                       * 1. generativity
                       * 2. import
                       *   2.1 resolved import
                       *   2.2 unresolved import 
                       *       2.2.1 already imported by previous linkageUnits
                       *       2.2.2 newly imported
                       *)
                      val (generativeExnTagSubst, freshGenerativeExnTagSet) = 
                          freshExnTagSetSubst (#generativeExnTagSet (#staticTypeEnv linkageUnit))
                      val innerResolvedImportExnSubst = 
                          SU.computeExnTagSubst (resolvedLUImportEnv,implEnv)
                      val innerCommonImportExnSubst = 
                          let
                              val (commonImportTEInLinkageUnit, _) =
                                  constructImplAndUnResolvedEnv 
                                      (commonAccImportTypeEnvWithTyInst,
                                       unResolvedLUImportEnvWithTyInst)
                          in
                              SU.computeExnTagSubst 
                                  (typeEnvToEnv commonImportTEInLinkageUnit, 
                                   typeEnvToEnv commonAccImportTypeEnvWithTyInst)
                          end
                      val (outerUnResolvedImportTEWithFreshExnTag,
                           outerUnResolvedImportExnSubst) = 
                          let
                              val outerUnResolvedLUImportEnvWithTyInst =
                                  let
                                      val Env1 = 
                                          STE.substTyConIdInTypeEnv 
                                              substTyConIdEnvLinkageUnit
                                              outerUnResolvedLUImportEnv
                                      val Env2 =
                                          STE.substTyConInTypeEnv
                                              substTyConEnvLinkageUnit
                                              Env1
                                  in
                                      STE.substTyConInTypeEnv substExportTyEnv
                                                              Env2
                                  end
                          in
                              (* Note: to avoid conflicting with freshExnTagSetSubst *)
                              freshExnTagTypeEnv outerUnResolvedLUImportEnvWithTyInst
                          end
                      val allExnTagSubst =
                          exnTagSubstMergeList
                              [generativeExnTagSubst,
                               innerResolvedImportExnSubst,
                               innerCommonImportExnSubst,
                               outerUnResolvedImportExnSubst
                               ] 
                              IEnv.empty
                      (*****************************************************************)
                      val newAccImportTE =
                          let
                              val accImportTEWithTyInst =
                                  STE.substTyConInTypeEnv 
                                      substExportTyEnv
                                      (STE.substTyConInTypeEnv substTyConEnvAccCommon
                                                               accImportTE)
                          in
                              STE.extendImportTypeEnvWithImportTypeEnv
                                  {newImportTypeEnv = outerUnResolvedImportTEWithFreshExnTag,
                                   oldImportTypeEnv =
                                   (STE.extendImportTypeEnvWithImportTypeEnv
                                        {
                                         newImportTypeEnv = (substExnTagTypeEnv 
                                                                 innerCommonImportExnSubst
                                                                 generalizedCommonLUImportEnv),
                                         oldImportTypeEnv = accImportTEWithTyInst
                                         }
                                        )
                                   }
                          end
                      val newAccExportTE =
                          let
                              val exportTypeEnvWithTyInst =
                                  let
                                      val Env1 = 
                                          STE.substTyConIdInTypeEnv 
                                              substTyConIdEnvLinkageUnit
                                              exportTypeEnv
                                      val Env2 =
                                          STE.substTyConInTypeEnv mergedSubstTyConEnvLinkageUnit
                                                                  Env1 
                                  in
                                      Env2
                                  end
                              val accExportTEWithTyInst =
                                  STE.substTyConInTypeEnv mergedSubstTyConEnvAccEnv
                                                          accExportTE
                          in
                              STE.extendExportTypeEnvWithExportTypeEnv
                                  {newExportTypeEnv = 
                                   substExnTagTypeEnv allExnTagSubst exportTypeEnvWithTyInst,
                                   oldExportTypeEnv = accExportTEWithTyInst}
                          end
                      (****************************************************************
                       * Module Env: 
                       * 1. Reallocate abstract index of value identifier
                       * 2. the same as 2nd point of type context
                       *)
                      val accImportMEWithTyInst =
                          SME.substTyConPathBasis mergedSubstTyConEnvAccEnv
                                                  accImportME
                      val accExportMEWithTyInst =
                          SME.substTyConPathBasis mergedSubstTyConEnvAccEnv
                                                  accExportME
                      val linkageUnitStaticModuleEnv = 
                          SME.substTyConStaticModuleEnv 
                              mergedSubstTyConEnvLinkageUnit
                              (SME.substTyConIdStaticModuleEnv 
                                   substTyConIdEnvLinkageUnit
                                   (#staticModuleEnv linkageUnit))
                              
                      (* only return the incremental moduleEnv *)
                      val (freeEntryPointer1,
                           indexEnv1,
                           hiddenValIndexList,
                           (newImportModuleEnv,newExportModuleEnv)) =
                          reAllocateAbstractIndexInModuleEnv 
                              linkageUnitStaticModuleEnv 
                              (#pathBasis instDeltaModuleEnv1, (* inner import instantiated   *)
                               #pathBasis instDeltaModuleEnv2, (* outer import instantiated   *)
                               accExportMEWithTyInst)(* accumulated export - compute hiddenValIndexList *)
                              freeEntryPointer
                      val newAccImportME =  
                          PE.recursiveExtendPathBasisList
                              [accImportMEWithTyInst, 
                               generalizedCommonLinkageUnitImportME, 
                               newImportModuleEnv]
                      val newAccExportME =
                          SME.extendExportModuleEnv
                              {
                               newExportModuleEnv = newExportModuleEnv,
                               oldExportModuleEnv = accExportMEWithTyInst
                               }
                      
                      (****************************************************************)
                      (* reallocate global index for hiddenValIndexList *)
                      val (freeEntryPointer2,
                           indexEnv2,
                           currLinkageUnitBoundTyInstValIndexList) =
                          allocateAbstractIndexInTyInstValIndexList 
                              (mergedSubstTyConEnvLinkageUnit, substTyConIdEnvLinkageUnit)
                              freeEntryPointer1
                              (#hiddenValIndexList linkageUnit)
                      (* *******************************************************
                       * code update :
                       * 1. array index instantiation
                       * 2. sizeTag instantiation
                       *)
                      val codesWithIndexTyUpdated = 
                          let
                              val substContext =
                                  {indexSubst = indexEnv3,
                                   substTyEnv = mergedSubstTyConEnvAccEnv,
                                   exnTagSubst = IEnv.empty,
                                   tyConIdSubst = ID.Map.empty}
                          in
                              substTldecs substContext codes
                          end
                      val (instCodeWithTyConIdUpdate, bodyCodeWithTyConIdUpdate) =
                          (substTyConIdTldecs
                               substTyConIdEnvLinkageUnit (tyInstCode1 @ tyInstCode2),
                           substTyConIdTldecs 
                               substTyConIdEnvLinkageUnit (#code linkageUnit))
                      val (instCodeWithTyUpdate, bodyCodeWithTyUpdate) =
                          (substTyTldecs 
                               mergedSubstTyConEnvLinkageUnit (tyInstCode1 @ tyInstCode2),
                           substTyTldecs 
                               mergedSubstTyConEnvLinkageUnit (#code linkageUnit))
                      val newCode =
                          let
                              val substContext =
                                  {indexSubst = IndexEnv.unionWith #1 (indexEnv1, indexEnv2),
                                   substTyEnv = mergedSubstTyConEnvLinkageUnit,
                                   exnTagSubst = allExnTagSubst,
                                   tyConIdSubst = substTyConIdEnvLinkageUnit}
                          in
                              (instCodeWithTyUpdate @ substTldecs substContext bodyCodeWithTyUpdate)
                          end
                  in
                      (
                       tyInstCode3 @ codesWithIndexTyUpdated @ newCode,
                       ID.Set.union (tyConIdSet, (#importTyConIdSet (#staticTypeEnv linkageUnit))),
                       freeEntryPointer2,
                       newAccImportTE,
                       newAccExportTE,
                       newAccImportME,
                       newAccExportME,
                       accGenerativeExnTagSet,
                       accHiddenValIndexList @ innerTyInstValIndexList 
                       @ currLinkageUnitImportTyInstValIndexList 
                       @ prevLinkageUnitTyInstValIndexList
                       @ currLinkageUnitBoundTyInstValIndexList
                       @ hiddenValIndexList
                       )
                  end)
              (nil,
               ID.Set.empty,
               TO.initialFreeEntryPointer,
               emptyImportTypeEnv,
               emptyExportTypeEnv,
               emptyImportModuleEnv,
               emptyExportModuleEnv,
               ISet.empty,
               nil
               )
              linkageUnits
              

    fun linkUnClosed newObjName linkageUnits = 
        let
            val (code,
                 tyConIdSet, 
                 freeEntryPointer, 
                 accImportTE,
                 accExportTE, 
                 accImportME,
                 accExportME,
                 accGenerativeExnTagSet,
                 hiddenValIndexList
                 ) =
                linkUnClosedLinkageUnits linkageUnits
        in
            {fileName = newObjName,
             staticTypeEnv = {importTyConIdSet = tyConIdSet,
                              importTypeEnv = accImportTE,
                              exportTypeEnv =  accExportTE,
                              generativeExnTagSet = accGenerativeExnTagSet},
             staticModuleEnv = {importModuleEnv = accImportME,
                                exportModuleEnv = accExportME},
             hiddenValIndexList = hiddenValIndexList,
             code = code}
        end

    (*****************************************************************************)
    fun lookupActualIndexInImportVarEnv importVarEnv instDeltaExportVarEnv =
        SEnv.foldli (fn (varName, 
                         PE.TopItem (pathVar, index, ty), 
                         indexEnv) =>
                        (
                         case SEnv.find(instDeltaExportVarEnv, varName) of
                           SOME (PE.TopItem (pathVar, globalIndex, ty)) =>
                           IndexEnv.insert(indexEnv,
                                           (getKeyInIndex index),
                                           globalIndex)
                         | SOME _ => raise Control.Bug "CurItem occurs at linking phase"
                         | NONE => raise Control.Bug ("unbound import value identifier:"^varName)
                        )
                      | (varName, PE.CurItem _, _ ) => 
                        raise Control.Bug "CurItem occurs at linking phase"
                            )
                    IndexEnv.empty
                    importVarEnv

    fun lookupActualIndexInImportStrEnv importStrEnv instDeltaExportStrEnv =
        SEnv.foldli (fn (strName,
                         PE.PATHAUX (subImportVarEnv, subImportStrEnv),
                         indexEnv) =>
                        case SEnv.find(instDeltaExportStrEnv, strName) of
                          SOME (PE.PATHAUX (subAccExportVarEnv,
                                            subAccExportStrEnv)) =>
                          let
                            val indexEnv1 = 
                                lookupActualIndexInImportVarEnv
                                  subImportVarEnv subAccExportVarEnv
                            val indexEnv2 = 
                                lookupActualIndexInImportStrEnv
                                  subImportStrEnv subAccExportStrEnv
                          in
                              IndexEnv.unionWithi 
                                  (fn _ => raise exDuplicateElem)
                                  ((IndexEnv.unionWithi (fn _ => raise exDuplicateElem)
                                                        (indexEnv1, indexEnv2)),
                                   indexEnv)
                          end
                        | NONE => raise Control.Bug ("non-import structure:"^strName)
                    )
                    IndexEnv.empty
                    importStrEnv

    fun lookupActualIndexInImportModuleEnv
          importModuleEnv instDeltaExportModuleEnv =
        let
          val (importFunEnv, (importVarEnv, importStrEnv)) = 
              importModuleEnv
          val (instDeltaExportFunEnv, (instDeltaExportVarEnv, instDeltaExportStrEnv)) = 
              instDeltaExportModuleEnv
          val indexEnv1 = 
              lookupActualIndexInImportVarEnv
                  importVarEnv instDeltaExportVarEnv
          val indexEnv2 = 
              lookupActualIndexInImportStrEnv
                  importStrEnv instDeltaExportStrEnv 
        in
            IndexEnv.unionWithi (fn _ => raise exDuplicateElem) (indexEnv1, indexEnv2)
        end

    fun allocateActualIndexInExportVarEnv 
            substTyEnv exportVarEnv accExportVarEnv freeGlobalArrayIndex freeEntryPointer 
      =
      SEnv.foldli 
          (fn (varName, 
               PE.TopItem (pathVar, globalIndex, ty), 
               (freeGlobalArrayIndex, 
                freeEntryPointer, 
                newExportVarEnv, 
                indexEnv, 
                arrayHdElemIndices,
                hiddenValIndexList))
              =>
              (case SEnv.find(accExportVarEnv, varName) of
                  NONE =>
                  let
                      val newTy = FAU.instantiateTy substTyEnv ty
                      val (newPageFlag, newFreeGlobalArrayIndex, newFreeEntryPointer, newGlobalIndex) =
                          IndexAllocator.allocateActualIndexAtLinking 
                              (freeGlobalArrayIndex,
                               freeEntryPointer, 
                               {displayName = PE.pathVarToString(pathVar), ty = newTy})
                  in
                      (newFreeGlobalArrayIndex,
                       newFreeEntryPointer,
                       SEnv.insert(newExportVarEnv,
                                   varName,
                                   PE.TopItem (pathVar, newGlobalIndex, newTy)),
                       IndexEnv.insert(indexEnv,
                                       (getKeyInIndex globalIndex),
                                       newGlobalIndex),
                       if newPageFlag then arrayHdElemIndices @ [newGlobalIndex] else arrayHdElemIndices,
                       hiddenValIndexList)
                  end
                | SOME (PE.TopItem accItemInfo) =>
                  let
                      val newTy = FAU.instantiateTy substTyEnv ty
                      val (newPageFlag, newFreeGlobalArrayIndex, newFreeEntryPointer, newGlobalIndex) =
                          IndexAllocator.allocateActualIndexAtLinking 
                              (freeGlobalArrayIndex,
                               freeEntryPointer, 
                               {displayName = PE.pathVarToString(pathVar), ty = newTy})
                  in
                      (newFreeGlobalArrayIndex,
                       newFreeEntryPointer,
                       SEnv.insert(newExportVarEnv,
                                   varName,
                                   PE.TopItem (pathVar, newGlobalIndex, newTy)),
                       IndexEnv.insert(indexEnv,
                                       (getKeyInIndex globalIndex),
                                       newGlobalIndex),
                       if newPageFlag then arrayHdElemIndices @ [newGlobalIndex] else arrayHdElemIndices,
                       hiddenValIndexList @ [accItemInfo])
                  end
                | SOME (PE.CurItem _) => 
                  raise Control.Bug "CurItem occurs at linking phase")
            | (varName, PE.CurItem _ , _) => 
              raise Control.Bug "CurItem occurs at linking phase")
          (freeGlobalArrayIndex, freeEntryPointer, SEnv.empty, IndexEnv.empty, nil, nil)
          exportVarEnv

    fun allocateActualIndexInExportStrEnv 
            substTyEnv exportStrEnv accExportStrEnv freeGlobalArrayIndex freeEntryPointer
      =
        SEnv.foldli
        (fn (strName,
             PE.PATHAUX (subExportVarEnv, subExportStrEnv),
             (freeGlobalArrayIndex, 
              freeEntryPointer, 
              newExportStrEnv, 
              indexEnv, 
              arrayHdElemIndices,
              hiddenValIndexList)) =>
            let
                val (freeGlobalArrayIndex1, 
                     freeEntryPointer1, 
                     newSubExportVarEnv, 
                     indexEnv1, 
                     arrayHdElemIndices1,
                     hiddenValIndexList1) =
                    allocateActualIndexInExportVarEnv
                        substTyEnv subExportVarEnv SEnv.empty freeGlobalArrayIndex freeEntryPointer
                val (freeGlobalArrayIndex2, 
                     freeEntryPointer2, 
                     newSubExportStrEnv, 
                     indexEnv2, 
                     arrayHdElemIndices2,
                     hiddenValIndexList2) =
                    allocateActualIndexInExportStrEnv
                        substTyEnv subExportStrEnv SEnv.empty freeGlobalArrayIndex1 freeEntryPointer1
            in
                case SEnv.find(accExportStrEnv, strName) of
                    NONE =>(freeGlobalArrayIndex2,
                            freeEntryPointer2,
                            SEnv.insert(newExportStrEnv,
                                        strName,
                                        PE.PATHAUX (newSubExportVarEnv,
                                                    newSubExportStrEnv)),
                            (IndexEnv.unionWith (fn _ => raise exDuplicateElem)
                                                (IndexEnv.unionWith (fn _ => raise exDuplicateElem) 
                                                                    (indexEnv1, indexEnv2),
                                                                    indexEnv)),
                            arrayHdElemIndices @ arrayHdElemIndices1 @ arrayHdElemIndices2,
                            hiddenValIndexList)
                  | SOME (PE.PATHAUX (subAccExportVarEnv, subAccExportStrEnv)) =>
                    (* calculate all the indices for removing the setGlobal instruction *)
                    let
                        val indices1 = calcValIndexListPathVarEnv subAccExportVarEnv
                        val indices2 = calcValIndexListPathStrEnv subAccExportStrEnv
                    in
                        (freeGlobalArrayIndex2,
                         freeEntryPointer2,
                         SEnv.insert(newExportStrEnv,
                                     strName,
                                     PE.PATHAUX (newSubExportVarEnv,
                                                 newSubExportStrEnv)),
                         (IndexEnv.unionWith (fn _ => raise exDuplicateElem)
                                             (IndexEnv.unionWith (fn _ => raise exDuplicateElem) 
                                                                 (indexEnv1, indexEnv2),
                                                                 indexEnv)),
                         arrayHdElemIndices @ arrayHdElemIndices1 @ arrayHdElemIndices2,
                         hiddenValIndexList @ indices1 @ indices2)
                    end
            end)
        (freeGlobalArrayIndex, freeEntryPointer, SEnv.empty, IndexEnv.empty, nil, nil)
        exportStrEnv

    fun allocateActualIndexInExportModuleEnv
            substTyEnv (exportModuleEnv:SME.exportModuleEnv) (accExportModuleEnv:SME.exportModuleEnv)
            freeGlobalArrayIndex freeEntryPointer =
        let
          val (exportFunEnv, (exportVarEnv,exportStrEnv)) = 
              exportModuleEnv
          val (accExportFunEnv, (accExportVarEnv, accExportStrEnv)) =
              accExportModuleEnv
          val (freeGlobalArrayIndex1, 
               freeEntryPointer1, 
               newExportVarEnv, 
               indexEnv1, 
               arrayHdElemIndices1,
               hiddenValIndexList1) =
              allocateActualIndexInExportVarEnv
                  substTyEnv exportVarEnv accExportVarEnv
                  freeGlobalArrayIndex freeEntryPointer
          val (freeGlobalArrayIndex2, 
               freeEntryPointer2, 
               newExportStrEnv,
               indexEnv2, 
               arrayHdElemIndices2,
               hiddenValIndexList2) =
              allocateActualIndexInExportStrEnv
                  substTyEnv exportStrEnv accExportStrEnv
                  freeGlobalArrayIndex1 freeEntryPointer1
        in
            (freeGlobalArrayIndex2,
             freeEntryPointer2,
             (exportFunEnv,
              (newExportVarEnv, newExportStrEnv)): SME.exportModuleEnv,
             IndexEnv.unionWithi (fn (key,x,y) => raise exDuplicateElem) (indexEnv1, indexEnv2),
             arrayHdElemIndices1 @ arrayHdElemIndices2,
             hiddenValIndexList1 @ hiddenValIndexList2)
        end

    (* accExportModuleEnv is only used for overriden,
     * thus hiddenValIndex computation
     *)
    fun allocateActualIndexInModuleEnv
            substTyEnv moduleEnv accExportModuleEnv instDeltaExportModuleEnv
            freeGlobalArrayIndex freeEntryPointer =
        let
            val (importModuleEnv, exportModuleEnv) = moduleEnv
            val indexEnv1 = 
                lookupActualIndexInImportModuleEnv
                    importModuleEnv instDeltaExportModuleEnv
            val (freeGlobalArrayIndex1, 
                 freeEntryPointer1, 
                 newExportModuleEnv,
                 indexEnv2, 
                 arrayHdElemIndices,
                 hiddenValIndexList) =
                allocateActualIndexInExportModuleEnv
                    substTyEnv exportModuleEnv accExportModuleEnv
                    freeGlobalArrayIndex freeEntryPointer
        in
            (freeGlobalArrayIndex1,
             freeEntryPointer1,
             newExportModuleEnv,
             IndexEnv.unionWithi (fn _ => raise exDuplicateElem) (indexEnv1, indexEnv2),
             arrayHdElemIndices,
             hiddenValIndexList)
        end
        
    (* 
     * link closed object files.
     * 1. type check and type propagation
     * 2. allocate actual index to 
     *   (1) export value identifier
     *   (2) inner resolved import value identifiers
     *)
    fun linkClosedLinkageUnits (linkageUnits : linkageUnit list)  =
        foldl (fn (linkageUnit : linkageUnit, 
                   (codes : TypedLambda.tldecl list,
                    freeGlobalArrayIndex,
                    freeEntryPointer,
                    accExportTE : STE.exportTypeEnv, 
                    accExportME : SME.exportModuleEnv,
                    accGenerativeExnTagSet,
                    accHiddenValIndexes
                    )) =>
                  let
                      val loc = getLocLinkageUnit linkageUnit
                      (****************************************************************)
                      (* Type Env: *)
                      val importTypeEnv = #importTypeEnv (#staticTypeEnv linkageUnit)
                      val exportTypeEnv = #exportTypeEnv (#staticTypeEnv linkageUnit)
                      (*******************************************************************
                       * import signature check
                       *)
                      val (implTypeEnv, unResolvedImportEnv) = 
                          constructImplAndUnResolvedEnv (importTypeEnv, accExportTE)
                      val (importEnv,implEnv) =  
                          (typeEnvToEnv importTypeEnv, typeEnvToEnv implTypeEnv)
                      val strictEnv = 
                          (SC.checkEnvAndSigma 
                               (implEnv,
                                ((#importTyConIdSet (#staticTypeEnv linkageUnit)), 
                                 importEnv)))
                          handle exn => (SU.handleException (exn,loc);raise ExSigCheckFailure)
                      (****************************************************************** 
                       * compute type spec implementation
                       *)
                      val substTyEnv = SigUtils.substTyEnvFromEnv (importEnv, implEnv)
                      (*****************************************************************
                       * type instantiation term 
                       *)
                      local
                          val currentModuleEnv as {pathBasis,...} =
                              {freeGlobalArrayIndex = freeGlobalArrayIndex,
                               freeEntryPointer = freeEntryPointer,
                               pathBasis = accExportME}
                      in
                          val (tyInstCode, instDeltaModuleEnv) = 
                              genTyInstantiationCode (implEnv, strictEnv) 
                                                     currentModuleEnv
                                                     loc
                          val freeGlobalArrayIndex = #freeGlobalArrayIndex instDeltaModuleEnv
                          val freeEntryPointer = #freeEntryPointer instDeltaModuleEnv
                          val newTyInstValIndexList1 =
                               (flattenPathBasisToList (#pathBasis instDeltaModuleEnv))
                      end
                      (****************************************************************** 
                       * sizeTag computation:
                       * 1.construct sizeTag map from tyConId -> sizeTag, used for
                       * substitution in the target code.
                       * 2.update exported environment of current linkage unit
                       *)
                      val sizeTagSubst = sizeTagSubstEnv (importEnv, implEnv)
                      (******************************************************************
                       * exnTag compuation:
                       * 1. generativity
                       * 2. import
                       *)
                      val (exnTagSubst, freshGenerativeExnTagSet) =
                          let
                              val (generativeExnTagSubst, freshGenerativeExnTagSet) = 
                                  freshExnTagSetSubst (#generativeExnTagSet (#staticTypeEnv linkageUnit))
                              val importExnSubst =
                                  SU.computeExnTagSubst (importEnv, implEnv)
                          in
                              ((IEnv.unionWith (fn _ => raise Control.Bug "duplicate exnTag")
                                               (generativeExnTagSubst, importExnSubst)),
                               freshGenerativeExnTagSet)
                          end
                      val exportTypeEnvWithExnTagFilled =
                          substExnTagTypeEnv exnTagSubst exportTypeEnv
                      (*******************************************************************)
                      val newAccExportTC =
                          let
                              val newExportTypeEnv =
                                  STE.substTyConInTypeEnv substTyEnv exportTypeEnvWithExnTagFilled
                          in
                              STE.extendExportTypeEnvWithExportTypeEnv
                                  {newExportTypeEnv = newExportTypeEnv,
                                   oldExportTypeEnv = accExportTE}
                          end
                      (****************************************************************)
                      (* Module Env: *)
                      val (freeGlobalArrayIndex1, 
                           freeEntryPointer1, 
                           newExportModuleEnv, 
                           indexEnv1, 
                           arrayHdElemIndices1,
                           hiddenValIndexes) =
                          let
                              val linkageUnitStaticModuleEnv = #staticModuleEnv linkageUnit
                          in
                              allocateActualIndexInModuleEnv substTyEnv
                                                             (#importModuleEnv linkageUnitStaticModuleEnv,
                                                              #exportModuleEnv linkageUnitStaticModuleEnv) 
                                                             accExportME
                                                             (#pathBasis instDeltaModuleEnv)
                                                             freeGlobalArrayIndex
                                                             freeEntryPointer 
                          end
                      val newAccExportME : SME.exportModuleEnv =
                          SME.extendExportModuleEnv
                              {newExportModuleEnv = newExportModuleEnv,
                               oldExportModuleEnv = accExportME}
                   
                      (****************************************************************)
                      (* reallocate global index for hiddenValIndexList *)
                      val (freeGlobalArrayIndex2,
                           freeEntryPointer2,
                           indexEnv2,
                           arrayHdElemIndices2,
                           newTyInstValIndexList2) =
                          allocateActualIndexInTyInstValIndexList 
                              substTyEnv
                              freeGlobalArrayIndex1
                              freeEntryPointer1
                              (#hiddenValIndexList linkageUnit)
                      (*************************************************************
                       * update code
                       *)
                      val updatedIndexTldecs =  
                          substIndexTldecs (IndexEnv.unionWith 
                                                (fn (x,y) => raise Control.Bug "duplicate element")
                                                (indexEnv1,indexEnv2))
                                           (#code linkageUnit)
                      val newCode = 
                          substTldecs ({substTyEnv = substTyEnv,
                                        exnTagSubst = exnTagSubst,
                                        tyConIdSubst = ID.Map.empty,
                                        indexSubst = IndexEnv.empty})
                                      (tyInstCode @ updatedIndexTldecs)
                  in
                      (
                       codes @ newCode,
                       freeGlobalArrayIndex1,
                       freeEntryPointer1,
                       newAccExportTC : STE.exportTypeEnv,
                       newAccExportME : SME.exportModuleEnv,
                       ISet.union(accGenerativeExnTagSet, freshGenerativeExnTagSet),
                       accHiddenValIndexes @ hiddenValIndexes
                       @ newTyInstValIndexList1 @ newTyInstValIndexList2
                       )
                  end)
              (*handle exn as (TCU.ExBoxedKindCheckFailure _) =>
                       (SU.handleException (exn, getLocLinkageUnit linkageUnit);
                        raise ExSigCheckFailure))*)
              (nil,
               TO.initialFreeGlobalArrayIndex,
               TO.initialFreeEntryPointer,            
               emptyExportTypeEnv : STE.exportTypeEnv, 
               emptyExportModuleEnv : SME.exportModuleEnv,
               ISet.empty,
               nil)
              linkageUnits
              
    fun linkClosed newObjName linkageUnits = 
        let
            val (code, 
                 freeGlobalArrayIndex,
                 freeEntryPointer, 
                 accExportTE, 
                 accExportME,
                 accGenerativeExnTagSet,
                 hiddenValIndexList
                 ) = linkClosedLinkageUnits linkageUnits
        in
            {fileName = newObjName,
             staticTypeEnv = {importTyConIdSet = ID.Set.empty,
                              importTypeEnv = STE.emptyTypeEnv,
                              exportTypeEnv =  accExportTE,
                              generativeExnTagSet = accGenerativeExnTagSet},
             staticModuleEnv = {importModuleEnv = SME.emptyImportModuleEnv,
                                exportModuleEnv = accExportME},
             hiddenValIndexList = hiddenValIndexList,
             code = code}
        end

    fun link newObjName objNames =
        let
            val _ = Control.doLinking := true
            val _ = E.initializeTypeinfError()
            val _ = LE.initializeLinkError()
            val _ = checkObjectFileNames (newObjName :: objNames)
            val linkageUnits = 
                foldl (fn (objName, linkageUnits) =>
                          let
                              val linkageUnit = unPickle objName LinkageUnitPickler.linkageUnit
                          in
                              linkageUnits @ [linkageUnit]
                          end)
                      nil
                      objNames
            val newLinkageUnit =
                if checkClosed linkageUnits 
                then
                    let
                        val _ = print "\n[linking closed objects ......]\n"
                    in
                        linkClosed newObjName linkageUnits 
                    end
                else
                    let
                        val _ = print "\n[linking unclosed objects ......]\n"
                    in
                        linkUnClosed newObjName linkageUnits 
                    end
            val outfile = BinIO.openOut newObjName
            val outstream =
                Pickle.makeOutstream
                    (fn byte => BinIO.output1 (outfile, byte))
            val _ = print "\n[******** linked object *************] \n"
            val _ = print (Control.prettyPrint (format_linkageUnit nil newLinkageUnit))
            val _ = print "\n[************************************] \n"
            val _ = P.pickle LinkageUnitPickler.linkageUnit newLinkageUnit outstream
        in
            BinIO.closeOut outfile
        end
            handle linkExn as LE.IllegalObjectFileSuffix _ =>
                   (LE.enqueueError(Loc.noloc, linkExn);LE.handleError())
                 | linkExn as LE.UnboundImportValueIdentifier _ =>
                   (LE.enqueueError(Loc.noloc, linkExn);LE.handleError())
                 | linkExn as LE.UnboundImportTypeContructor _ =>
                   (LE.enqueueError(Loc.noloc, linkExn);LE.handleError())
                 | linkExn as LE.UnboundImportStructure _ =>
                   (LE.enqueueError(Loc.noloc, linkExn);LE.handleError())
                 | linkExn as LE.UnEquivalentImportType _ =>
                   (LE.enqueueError(Loc.noloc, linkExn);LE.handleError())
                 | linkExn as IO.Io {name,function,...} => 
                   (LE.enqueueError(Loc.noloc, LE.IOException {name = name, 
                                                               function = function});
                    LE.handleError())
                 | ExSigCheckFailure => LE.handleError()
                 | C.Bug message => (print message;raise C.Bug message)
                 
                 | _ => raise Control.Bug "uncaught exception"
                   

    fun useObj (context as {topTypeContext, moduleEnv:SME.moduleEnv},
                (linkageUnit : linkageUnit)) =
        let
            val _ = Control.doLinking := true
            val loc = getLocLinkageUnit linkageUnit
            (* Type Env: *)
            val importTypeEnv = #importTypeEnv (#staticTypeEnv linkageUnit)
            val exportTypeEnv = #exportTypeEnv (#staticTypeEnv linkageUnit)
            (*****************************************************************
             * signature check
             *)
            val typeContext = 
                ITC.projectTypeContextInTopTypeContext topTypeContext
            val implEnv = 
                constructImplEnvWithTypeContext (importTypeEnv, typeContext)
            val importEnv = typeEnvToEnv importTypeEnv
            val strictEnv = 
                (SC.checkEnvAndSigma 
                     (implEnv,
                      ((#importTyConIdSet (#staticTypeEnv linkageUnit)), 
                       importEnv)))
                handle exn => (SU.handleException (exn,loc); raise ExSigCheckFailure)
            (*****************************************************************
             * import type instantiation
             *)
            val substTyEnv = 
                SigUtils.substTyEnvFromEnv (importEnv, implEnv)
            val substExnTagEnv =
                substExnTag
            val exportTypeEnvWithTyConFilled =
                STE.substTyConInTypeEnv substTyEnv exportTypeEnv
            (*****************************************************************
             * type instantiation term and 
             *)
            val currentModuleEnv = SME.projectTopModuleEnvToCurrentModuleEnv moduleEnv
            val (tyInstCode, instDeltaModuleEnv) = 
                genTyInstantiationCode (implEnv, strictEnv) currentModuleEnv loc
            (****************************************************************** 
             * sizeTag computation.
             *)
            val sizeTagSubst = sizeTagSubstEnv (importEnv, implEnv)
            (******************************************************************
             * exnTag computation:
             * 1. generativity
             * 2. import exn
             *)
            val exnTagSubst =
                let
                    val (generativeExnTagSubst, _) = 
                        freshExnTagSetSubst (#generativeExnTagSet (#staticTypeEnv linkageUnit))
                    val importExnSubst =
                        SU.computeExnTagSubst (importEnv, implEnv)
                in
                    IEnv.unionWith (fn _ => raise Control.Bug "duplicate exnTag")
                                   (generativeExnTagSubst, importExnSubst)
                end
            val exportTypeEnvWithExnTagFilled =
                substExnTagTypeEnv exnTagSubst exportTypeEnvWithTyConFilled
            (**********************************************************************)
            val newTypeContext =
                {funEnv = SEnv.empty,
                 sigEnv = SEnv.empty,
                 tyConEnv = #tyConEnv exportTypeEnvWithExnTagFilled,
                 varEnv = #varEnv exportTypeEnvWithExnTagFilled,
                 strEnv = #strEnv exportTypeEnvWithExnTagFilled}
            (****************************************************************)
            (* Module Env: *)
            local
                val linkageUnitModuleEnv = #staticModuleEnv linkageUnit
            in
                val (freeGlobalArrayIndex1,
                     freeEntryPointer1, 
                     newExportModuleEnv, 
                     indexEnv1, 
                     arrayHdElemIndices1,
                     _) =
                    allocateActualIndexInModuleEnv 
                        substTyEnv
                        (#importModuleEnv linkageUnitModuleEnv,
                         #exportModuleEnv linkageUnitModuleEnv) 
                        (#pathBasis currentModuleEnv)
                        (#pathBasis instDeltaModuleEnv)
                        (#freeGlobalArrayIndex instDeltaModuleEnv)
                        (#freeEntryPointer instDeltaModuleEnv)
            end

            (****************************************************************)
            (* reallocate global index for inner type instantiated value identifier 
             *)
            val (freeGlobalArrayIndex2,
                 freeEntryPointer2,
                 indexEnv2,
                 arrayHdElemIndices2,
                 _) =
                allocateActualIndexInTyInstValIndexList 
                    substTyEnv 
                    freeGlobalArrayIndex1
                    freeEntryPointer1 
                    (#hiddenValIndexList linkageUnit)
                
            (****************************************************************)
            (* generate initialization code for top array containing value *)
            val initializationCode =
                foldl (fn (arrayHdElemIndex, iniArrayCodes) =>
                          let
                              val id = ID.generate()
                          in
                              iniArrayCodes  @ 
                              [TypedLambda.TLVAL
                                   {
                                    boundVar = {id = id, displayName = "S" ^ (ID.toString id), ty = PT.unitty},
                                    boundExp =
                                    TypedLambda.TLINITARRAY
                                        { 
                                         arrayIndex = TO.getPageArrayIndex(arrayHdElemIndex), 
                                         size = TO.getPageSize(),
                                         elementTy = TO.pageKindToType(TO.getPageKind(arrayHdElemIndex)), 
                                         loc = loc
                                        },
                                    loc = loc
                                   }]
                          end)
                      nil
                      (arrayHdElemIndices1 @ arrayHdElemIndices2)

            (****************************************************************)
            (* update code *)
            val updatedIndexTldecs = 
                substIndexTldecs (IndexEnv.unionWith
                                      (fn (x,y) => raise exDuplicateElem)
                                      (indexEnv1, indexEnv2))
                                 (#code linkageUnit)
            val newCode = 
                substTldecs ({substTyEnv = substTyEnv,
                              exnTagSubst = exnTagSubst,
                              tyConIdSubst = ID.Map.empty,
                              indexSubst = IndexEnv.empty})
                            (tyInstCode @ updatedIndexTldecs)
        in
            (newTypeContext,
             {
              freeGlobalArrayIndex = freeGlobalArrayIndex2,
              freeEntryPointer = freeEntryPointer2,
              pathBasis = newExportModuleEnv}:StaticModuleEnv.deltaModuleEnv,
             initializationCode @ newCode)
        end 
            handle ExSigCheckFailure => 
                   raise UE.UserErrors (E.getErrorsAndWarnings () @ LE.getErrorsAndWarnings ())
                 | TCU.ExBoxedKindCheckFailure {tyConName, requiredKind, objectKind} =>
                   (E.enqueueError(getLocLinkageUnit linkageUnit, 
                                   E.KindCheckFailure
                                       {tyConName = tyConName,
                                        requiredKind = requiredKind,
                                        objectKind = objectKind});
                    raise UE.UserErrors (E.getErrorsAndWarnings () 
                                         @ LE.getErrorsAndWarnings ()))
                 | C.Bug message => raise C.Bug message
  end (* end local *)
end (* end structure *)
