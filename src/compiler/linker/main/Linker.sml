(**
 * Linker
 *
 * @copyright (c) 2006, Tohoku University. 
 * @author Liu Bochao
 * @version $Id: Linker.sml,v 1.1 2006/03/02 12:46:19 bochao Exp $
 *)
structure Linker:
          sig
              val linkClosed : string -> string list -> unit
              val linkUnClosed : string -> string list -> unit
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
      structure IMC = InitialModuleContext
      structure TO = TopObject
      structure PE = PathEnv
      structure SC = SigCheck
      structure FAU = FunctorApplyUtils
      structure P = Pickle
      structure SE = StaticEnv
      structure E = TypeInferenceError
      structure UE = UserError 
      open LinkageUnit
      open LinkerUtils
      val debug = ref true
      fun printDebug x = if !debug then print x else ()

      exception sigCheckFail 
  in
    (*************************************************************)  

    val emptyImportTypeEnv = TC.emptyTypeEnv
    val emptyExportTypeEnv = TC.emptyTypeEnv
    val emptyImportModuleEnv = PathEnv.emptyPathBasis
    val emptyExportModuleEnv = PathEnv.emptyPathBasis

    (*************************************************************)
    (* dupcliate index *)
    exception exDuplicateElem 

    (*
     * merge object files,
     * allocate abstract index to exported value identifier
     *)
    fun reAllocateAbstractIndexInExportVarEnv 
            exportVarEnv substTyEnv freeGlobalArrayIndex freeEntryPointer  =
        SEnv.foldli (fn (varName,
                         PE.TopItem (pathVar, index, ty),
                         (freeGlobalArrayIndex, 
                          freeEntryPointer, 
                          indexEnv, 
                          exportVarEnv)) =>
                        let
                          val (newFreeGlobalArrayIndex, newFreeEntryPointer, newIndex) =
                              IndexAllocator.allocateAbstractIndex 
                                  freeGlobalArrayIndex freeEntryPointer
                          val newIndexEnv = 
                              IndexEnv.insert(indexEnv,
                                              (getKeyInIndex index),
                                              newIndex)
                          val newTy = substTy (injectSubstTyEnvInSubstContext substTyEnv) ty
                          val newExportVarEnv =
                              SEnv.insert (exportVarEnv,
                                           varName, 
                                           PE.TopItem(pathVar, newIndex, newTy))
                        in
                          (newFreeGlobalArrayIndex,
                           newFreeEntryPointer, 
                           newIndexEnv, 
                           newExportVarEnv)
                        end
                      | (varName, PE.CurItem _, _) => 
                        raise Control.Bug "CurItem occurs at linking phase"
                          )
                    (freeGlobalArrayIndex, freeEntryPointer, IndexEnv.empty, SEnv.empty)
                    exportVarEnv        
    (* 
     * allocate abstract index
     * 1. inner imported value identifier are resolved
     * 2. outer imported value identifier are still kept their imported status
     *)
    fun reAllocateAbstractIndexInImportVarEnv 
            importVarEnv freeGlobalArrayIndex freeEntryPointer innerAccExportVarEnv = 
        SEnv.foldli (fn (varName, PE.TopItem (pathVar, index, ty), 
                         (freeGlobalArrayIndex,
                          freeEntryPointer, 
                          indexEnv, 
                          outerImportVarEnv)) =>
                        (
                         case SEnv.find(innerAccExportVarEnv, varName) of
                             SOME (PE.TopItem (pathVar, globalIndex, ty)) =>
                             (* inner resolved *)
                             (freeGlobalArrayIndex,
                              freeEntryPointer, 
                              IndexEnv.insert(indexEnv,
                                              (getKeyInIndex index),
                                              globalIndex),
                              outerImportVarEnv)
                        | SOME _ => raise Control.Bug "CurItem occurs at linking phase"
                        | NONE =>
                          (* outer imported *)
                          let
                              val (newFreeGlobalArrayIndex, newFreeEntryPointer, newIndex) =
                                  IndexAllocator.allocateAbstractIndex freeGlobalArrayIndex 
                                                                       freeEntryPointer
                            val newIndexEnv = 
                                IndexEnv.insert(indexEnv,
                                                (getKeyInIndex index),
                                                newIndex)
                            val newOuterImportVarEnv =
                                SEnv.insert (outerImportVarEnv,
                                             varName, 
                                             PE.TopItem(pathVar, newIndex, ty))
                          in
                              (newFreeGlobalArrayIndex,
                               newFreeEntryPointer, 
                               newIndexEnv, 
                               newOuterImportVarEnv)
                          end)
                      | (varName, PE.CurItem _, _ ) => 
                        raise Control.Bug "CurItem occurs at linking phase")
                    (freeGlobalArrayIndex, freeEntryPointer, IndexEnv.empty, SEnv.empty)
                    importVarEnv
                    
    fun reAllocateAbstractIndexInExportStrEnv 
            exportStrEnv substTyEnv freeGlobalArrayIndex freeEntryPointer =
        SEnv.foldli (fn (strName, 
                         PE.PATHAUX (subExportVarEnv, subExportStrEnv),
                         (freeGlobalArrayIndex,
                          freeEntryPointer, 
                          indexEnv, 
                          exportStrEnv)) =>
                        let
                          val (freeGlobalArrayIndex1,
                               freeEntryPointer1, 
                               indexEnv1:TO.globalIndex IndexEnv.map, 
                               newSubExportVarEnv) =
                              reAllocateAbstractIndexInExportVarEnv 
                                subExportVarEnv 
                                substTyEnv
                                freeGlobalArrayIndex
                                freeEntryPointer 
                          val (freeGlobalArrayIndex2,
                               freeEntryPointer2, 
                               indexEnv2:TO.globalIndex IndexEnv.map, 
                               newSubExportStrEnv)
                                =
                              reAllocateAbstractIndexInExportStrEnv
                                subExportStrEnv 
                                substTyEnv
                                freeGlobalArrayIndex1
                                freeEntryPointer1
                        in
                          (freeGlobalArrayIndex2,
                           freeEntryPointer2,
                           (IndexEnv.unionWithi 
                              (fn _ => raise exDuplicateElem)
                              (
                               (IndexEnv.unionWithi 
                                  (fn _ => raise exDuplicateElem) (indexEnv2, indexEnv1)),
                                 indexEnv)),
                           SEnv.insert(exportStrEnv,
                                       strName,
                                       PE.PATHAUX (newSubExportVarEnv,
                                                   newSubExportStrEnv)
                                       )
                           )
                        end
                    )
                    (freeGlobalArrayIndex, freeEntryPointer, IndexEnv.empty, SEnv.empty)
                    exportStrEnv

    fun reAllocateAbstractIndexInImportStrEnv 
            importStrEnv freeGlobalArrayIndex freeEntryPointer innerAccExportStrEnv =
        SEnv.foldli 
            (fn (strName, PE.PATHAUX (subImportVarEnv, subImportStrEnv),
                 (freeGlobalArrayIndex,
                  freeEntryPointer, 
                  indexEnv, 
                  outerImportStrEnv)) 
                =>
                case SEnv.find(innerAccExportStrEnv, strName) of
                    SOME (PE.PATHAUX (subInnerAccExportVarEnv,
                                      subInnerAccExportStrEnv)) =>
                    (* inner resolved *)
                    let
                        val (freeGlobalArrayIndex1,
                             freeEntryPointer1, 
                             indexEnv1, 
                             newSubOuterImportVarEnv) =
                            reAllocateAbstractIndexInImportVarEnv
                                subImportVarEnv
                                freeGlobalArrayIndex 
                                freeEntryPointer
                                subInnerAccExportVarEnv
                        val _ = 
                            if SEnv.numItems(newSubOuterImportVarEnv) = 0 
                            then ()
                            else 
                                raise Control.Bug
                                          ("imported structure does not match" ^
                                           " signature(should be checked by signature matching(1)")
                        val (freeGlobalArrayIndex2,
                             freeEntryPointer2,
                             indexEnv2,
                             newSubOuterImportStrEnv) =
                            reAllocateAbstractIndexInImportStrEnv
                                subImportStrEnv
                                freeGlobalArrayIndex1
                                freeEntryPointer1 
                                subInnerAccExportStrEnv
                        val _ = 
                            if SEnv.numItems(newSubOuterImportStrEnv) = 0 
                            then ()
                            else 
                                raise Control.Bug
                                          ("imported structure does not match" ^
                                           " signature(should be checked by signature matching(2)")
                    in
                        (freeGlobalArrayIndex2,
                         freeEntryPointer2,
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
                    (freeGlobalArrayIndex,
                     freeEntryPointer,
                     indexEnv,
                     SEnv.insert(outerImportStrEnv,
                                 strName,
                                 PE.PATHAUX (subImportVarEnv,subImportStrEnv))))
            (freeGlobalArrayIndex, freeEntryPointer, IndexEnv.empty, SEnv.empty)
            importStrEnv

    fun reAllocateAbstractIndexInImportModuleEnv
            importModuleEnv freeGlobalArrayIndex freeEntryPointer innerAccExportModuleEnv 
      =
      let
          val (importFunEnv, (importVarEnv, importStrEnv)) = importModuleEnv
          val (innerAccExportFunEnv,
               (innerAccExportVarEnv,innerAccExportStrEnv)) = innerAccExportModuleEnv
          val (freeGlobalArrayIndex1,
               freeEntryPointer1, 
               indexEnv1, 
               newImportVarEnv) =
              reAllocateAbstractIndexInImportVarEnv
                  importVarEnv freeGlobalArrayIndex freeEntryPointer innerAccExportVarEnv
          val (freeGlobalArrayIndex2,
               freeEntryPointer2, 
               indexEnv2, 
               newImportStrEnv) =
              reAllocateAbstractIndexInImportStrEnv
                  importStrEnv freeGlobalArrayIndex1 freeEntryPointer1 innerAccExportStrEnv
      in
          (freeGlobalArrayIndex2,
           freeEntryPointer2,
           IndexEnv.unionWithi (fn _ => raise exDuplicateElem) (indexEnv1, indexEnv2),
           (importFunEnv, (newImportVarEnv, newImportStrEnv)))
      end
          
    fun reAllocateAbstractIndexInExportModuleEnv
            exportModuleEnv substTyEnv freeGlobalArrayIndex freeEntryPointer =
            let
                val (exportFunEnv, (exportVarEnv,exportStrEnv)) = exportModuleEnv
                val (freeGlobalArrayIndex1, freeEntryPointer1, indexEnv1, newExportVarEnv) =
                    reAllocateAbstractIndexInExportVarEnv
                        exportVarEnv substTyEnv freeGlobalArrayIndex freeEntryPointer
                val (freeGlobalArrayIndex2, freeEntryPointer2, indexEnv2, newExportStrEnv) =
                    reAllocateAbstractIndexInExportStrEnv
                        exportStrEnv substTyEnv freeGlobalArrayIndex1 freeEntryPointer1
            in
                (freeGlobalArrayIndex2,
                 freeEntryPointer2,
                 IndexEnv.unionWithi (fn _ => raise exDuplicateElem) (indexEnv1, indexEnv2),
                 (exportFunEnv,(newExportVarEnv, newExportStrEnv)))
            end
                           
    fun reAllocateAbstractIndexInModuleEnv
            (staticModuleEnv: SME.staticModuleEnv) 
            substTyEnv 
            freeGlobalArrayIndex 
            freeEntryPointer
            (innerAccExportModuleEnv : SME.exportModuleEnv)
      =
          let
              val (innerAccImportFunEnv,
                   (innerAccImportVarEnv,
                    innerAccImportStrEnv)) = innerAccExportModuleEnv
              val (freeGlobalArrayIndex1,
                   freeEntryPointer1, 
                   indexEnv1, 
                   newImportModuleEnv : SME.importModuleEnv) =
                  reAllocateAbstractIndexInImportModuleEnv
                      (#importModuleEnv staticModuleEnv)
                      freeGlobalArrayIndex
                      freeEntryPointer 
                      innerAccExportModuleEnv
              val (freeGlobalArrayIndex2,
                   freeEntryPointer2,
                   indexEnv2, 
                   newExportModuleEnv : SME.exportModuleEnv) =
                  reAllocateAbstractIndexInExportModuleEnv
                      (#exportModuleEnv staticModuleEnv)
                      substTyEnv
                      freeGlobalArrayIndex1
                      freeEntryPointer1
          in
              (
               freeGlobalArrayIndex,
               freeEntryPointer2,
               IndexEnv.unionWithi (fn (key,x,y) => raise exDuplicateElem) 
                                   (indexEnv1, indexEnv2),
               (newImportModuleEnv, newExportModuleEnv)
               )
          end

    (* link unclosed object files.
     * only resolve array index allocation.
     *)
    fun linkUnClosedLinkageUnits (linkageUnits : linkageUnit list)  =
        foldl (fn (linkageUnit, 
                   (codes,
                    tyConIdSet,
                    freeGlobalArrayIndex,
                    freeEntryPointer,
                    accImportTE : TC.importTypeEnv, 
                    accExportTE : TC.exportTypeEnv, 
                    accImportME : SME.importModuleEnv, 
                    accExportME : SME.exportModuleEnv)) =>
                  let
                      (*************************************************************)
                      (*
                       * Type Context:
                       * 1. type check
                       * 2. Merge import and export enviornment; inner resolved
                       * imported value identifiers are not imported in the new 
                       * linked object. 
                       *)
                      val importTypeEnv = #importTypeEnv (#staticTypeEnv linkageUnit)
                      val exportTypeEnv = #exportTypeEnv (#staticTypeEnv linkageUnit)
                      (************************************************************ 
                       * import signature check 
                       *)
                      val (implTypeEnv, unResolvedImportEnv) = 
                          constructImplEnv (importTypeEnv, accExportTE)
                      local
                          val importPureTypeEnv = stripSizeTagTypeEnv importTypeEnv
                          val implPureTypeEnv = stripSizeTagTypeEnv implTypeEnv
                      in
                          val _ = 
                              let
                                  val defaultErrorValue = SE.emptyE
                                  val loc = getLocLinkageUnit linkageUnit
                              in
                                  (SC.checkEnvAndSigma 
                                       (implPureTypeEnv,
                                        ((#importTyConIdSet (#staticTypeEnv linkageUnit)), 
                                         importPureTypeEnv)))
                                  handle exn => (handleException (exn, loc); defaultErrorValue)
                              end
                          val substTyEnv = 
                              FAU.substTyEnvFromEnv (importPureTypeEnv, implPureTypeEnv)
                      end
                      (****************************************************************** 
                       * sizeTag computation:
                       * 1.construct sizeTag map from tyConId -> sizeTag, used for
                       * substitution in the target code.
                       * 2.update exported environment of current linkage unit
                       *)
                      val sizeTagSubst = 
                          TCU.sizeTagSubstFromEnv (importTypeEnv, implTypeEnv)
                      val updatedExportTypeEnv =
                          TCU.substSizeTagTypeEnv sizeTagSubst exportTypeEnv
                          
                      val newAccImportTE =
                          TC.extendImportTypeEnvWithImportTypeEnv
                              {newImportTypeEnv = unResolvedImportEnv,
                               oldImportTypeEnv = accImportTE}
                      val newAccExportTE =
                          let
                              val newExportTypeEnv =
                                  TCU.substTyConInTypeEnv substTyEnv updatedExportTypeEnv
                          in
                              TC.extendExportTypeEnvWithExportTypeEnv
                                  {newExportTypeEnv = newExportTypeEnv,
                                   oldExportTypeEnv = accExportTE}
                          end
                            
                      (****************************************************************
                       * Module Context: 
                       * 1. Reallocate abstract index to value identifier
                       * 2. the same as 2nd point of type context
                       *)
                      val staticModuleEnv = 
                          (*substTyConIdStaticModuleEnv substTyConIdEnv*) (#staticModuleEnv linkageUnit)
                      val (freeGlobalArrayIndex1,
                           freeEntryPointer1,
                           indexEnv1, 
                           (newImportModuleEnv,newExportModuleEnv)) =
                          reAllocateAbstractIndexInModuleEnv
                              staticModuleEnv substTyEnv freeGlobalArrayIndex freeEntryPointer accExportME
                      val newAccImportME =
                          SME.extendImportModuleEnv
                              {newImportModuleEnv = newImportModuleEnv,
                               oldImportModuleEnv = accImportME}
                      val newAccExportME =
                          let
                              val newExportModuleEnv =
                                  instantiateTyExportModuleEnv
                                      substTyEnv
                                      newExportModuleEnv
                          in
                              SME.extendExportModuleEnv
                                  {newExportModuleEnv = newExportModuleEnv,
                                   oldExportModuleEnv = accExportME}
                          end
                      (* *******************************************************
                       * code update :
                       * 1. type instantiation
                       * 2. array index instantiation
                       * 3. sizeTag instantiation
                       *)
                      val newCode1 = 
                          (*substTyConIdTldecs substTyConIdEnv*) (#code linkageUnit)
                      val newCode2 =  substTyTldecs substTyEnv newCode1
                      val newCode3 = substIndexTldecs indexEnv1 newCode2
                  in
                      (
                       codes @ newCode3,
                       ID.Set.union (tyConIdSet, (#importTyConIdSet (#staticTypeEnv linkageUnit))),
                       freeGlobalArrayIndex1,
                       freeEntryPointer1,
                       newAccImportTE,
                       newAccExportTE,
                       newAccImportME,
                       newAccExportME
                       )
                  end
                      )
              (nil,
               ID.Set.empty,
               TO.initialFreeGlobalArrayIndex,
               TO.initialFreeEntryPointer,
               emptyImportTypeEnv,
               emptyExportTypeEnv,
               emptyImportModuleEnv,
               emptyExportModuleEnv)
              linkageUnits
              

    (*****************************************************************************)
    fun lookupActualIndexInImportVarEnv importVarEnv accExportVarEnv =
        SEnv.foldli (fn (varName, 
                         PE.TopItem (pathVar, index, ty), 
                         indexEnv) =>
                        (
                         case SEnv.find(accExportVarEnv, varName) of
                           SOME (PE.TopItem (pathVar, globalIndex, ty)) =>
                           IndexEnv.insert(indexEnv,
                                           (getKeyInIndex index),
                                           globalIndex)
                         | SOME _ => raise Control.Bug "CurItem occurs at linking phase"
                         | NONE => raise E.UnboundImportValueIdentifier {name=varName}
                        )
                      | (varName, PE.CurItem _, _ ) => 
                        raise Control.Bug "CurItem occurs at linking phase"
                            )
                    IndexEnv.empty
                    importVarEnv

    fun lookupActualIndexInImportStrEnv importStrEnv accExportStrEnv =
        SEnv.foldli (fn (strName,
                         PE.PATHAUX (subImportVarEnv, subImportStrEnv),
                         indexEnv) =>
                        case SEnv.find(accExportStrEnv, strName) of
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
                        | NONE => raise E.UnboundImportStructure {name=strName}
                    )
                    IndexEnv.empty
                    importStrEnv

    fun lookupActualIndexInImportModuleEnv
          importModuleContext accExportModuleContext =
        let
          val (importFunEnv, (importVarEnv, importStrEnv)) = 
              importModuleContext
          val (accExportFunEnv, (accExportVarEnv, accExportStrEnv)) = 
              accExportModuleContext
          val indexEnv1 = lookupActualIndexInImportVarEnv
                            importVarEnv accExportVarEnv
          val indexEnv2 = lookupActualIndexInImportStrEnv
                            importStrEnv accExportStrEnv
        in
            IndexEnv.unionWithi (fn _ => raise exDuplicateElem) (indexEnv1, indexEnv2)
        end

    fun allocateActualIndexInExportVarEnv 
        substTyEnv exportVarEnv freeGlobalArrayIndex freeEntryPointer =
        SEnv.foldli 
        (fn (varName, 
             PE.TopItem (pathVar, index, ty), 
             (freeGlobalArrayIndex, freeEntryPointer, indexEnv, newExportVarEnv, arrayIndices)
             ) =>
            let
              val newTy = FAU.instantiateTy substTyEnv ty
              val (newPageFlag, newFreeGlobalArrayIndex, newFreeEntryPointer, newIndex) =
                  IndexAllocator.allocateActualIndexAtLinking 
                    (freeGlobalArrayIndex,
                     freeEntryPointer, 
                     {displayName = PE.pathVarToString(pathVar), ty = newTy})
            in
              (newFreeGlobalArrayIndex,
               newFreeEntryPointer,
               IndexEnv.insert(indexEnv,
                               (getKeyInIndex index),
                               newIndex),
               SEnv.insert(newExportVarEnv,
                           varName,
                           PE.TopItem (pathVar, newIndex, newTy)),
               if newPageFlag then arrayIndices @ [newIndex] else arrayIndices)
            end
          | (varName, PE.CurItem _ , _) => 
            raise Control.Bug "CurItem occurs at linking phase")
        (freeGlobalArrayIndex, freeEntryPointer, IndexEnv.empty, SEnv.empty, nil)
        exportVarEnv

    fun allocateActualIndexInExportStrEnv 
        substTyEnv exportStrEnv freeGlobalArrayIndex freeEntryPointer =
        SEnv.foldli
        (fn (strName,
             PE.PATHAUX (subExportVarEnv, subExportStrEnv),
             (freeGlobalArrayIndex, freeEntryPointer, indexEnv, newExportStrEnv, arrayIndices)) =>
            let
              val (freeGlobalArrayIndex1, 
                   freeEntryPointer1, 
                   indexEnv1, 
                   newSubExportVarEnv, 
                   arrayIndices1) =
                  allocateActualIndexInExportVarEnv
                      substTyEnv subExportVarEnv freeGlobalArrayIndex freeEntryPointer
              val (freeGlobalArrayIndex2, 
                   freeEntryPointer2, 
                   indexEnv2, 
                   newSubExportStrEnv, 
                   arrayIndices2) =
                  allocateActualIndexInExportStrEnv
                      substTyEnv subExportStrEnv freeGlobalArrayIndex1 freeEntryPointer1
            in
              (freeGlobalArrayIndex2,
               freeEntryPointer2,
               (IndexEnv.unionWith (fn _ => raise exDuplicateElem)
                                   (IndexEnv.unionWith (fn _ => raise exDuplicateElem) 
                                                       (indexEnv1, indexEnv2),
                                    indexEnv)),
               SEnv.insert(newExportStrEnv,
                           strName,
                           PE.PATHAUX (newSubExportVarEnv,
                                       newSubExportStrEnv)),
               arrayIndices @ arrayIndices1 @ arrayIndices2)
            end)
        (freeGlobalArrayIndex, freeEntryPointer, IndexEnv.empty, SEnv.empty, nil)
        exportStrEnv

    fun allocateActualIndexInExportModuleEnv
          substTyEnv (exportModuleEnv:SME.exportModuleEnv) freeGlobalArrayIndex freeEntryPointer =
        let
          val (exportFunEnv, (exportVarEnv,exportStrEnv)) = 
              exportModuleEnv
          val (freeGlobalArrayIndex1, 
               freeEntryPointer1, 
               indexEnv1, 
               newExportVarEnv, 
               arrayIndices1) =
              allocateActualIndexInExportVarEnv
                  substTyEnv exportVarEnv freeGlobalArrayIndex freeEntryPointer
          val (freeGlobalArrayIndex2, 
               freeEntryPointer2, 
               indexEnv2, 
               newExportStrEnv, 
               arrayIndices2) =
              allocateActualIndexInExportStrEnv
                  substTyEnv exportStrEnv freeGlobalArrayIndex1 freeEntryPointer1
        in
          (freeGlobalArrayIndex2,
           freeEntryPointer2,
           IndexEnv.unionWithi (fn (key,x,y) => raise exDuplicateElem) (indexEnv1, indexEnv2),
           (exportFunEnv,
            (newExportVarEnv, newExportStrEnv)): SME.exportModuleEnv,
           arrayIndices1 @ arrayIndices2
          )
        end

    fun allocateActualIndexInModuleEnv
          substTyEnv moduleEnv accExportModuleEnv freeGlobalArrayIndex freeEntryPointer =
        let
            val (importModuleEnv, exportModuleEnv) = moduleEnv
            val indexEnv1 = 
                lookupActualIndexInImportModuleEnv
                    importModuleEnv accExportModuleEnv
            val (freeGlobalArrayIndex1, freeEntryPointer1, indexEnv2, newExportModuleEnv, arrayIndices) =
                allocateActualIndexInExportModuleEnv
                    substTyEnv exportModuleEnv freeGlobalArrayIndex freeEntryPointer
        in
            (freeGlobalArrayIndex1,
             freeEntryPointer1,
             IndexEnv.unionWithi (fn _ => raise exDuplicateElem) (indexEnv1, indexEnv2),
             newExportModuleEnv,
             arrayIndices)
        end
           
    (* 
     * link closed object files.
     * 1. type check and type propagation
     * 2. allocate actual index to 
     *   (1) export value identifier
     *   (2) inner resolved import value identifiers
     *)
    fun linkClosedCompUnits (linkageUnits : linkageUnit list)  =
        foldl (fn (linkageUnit : linkageUnit, 
                   (codes : TypedLambda.tldecl list,
                    freeGlobalArrayIndex,
                    freeEntryPointer,
                    accExportTE : TC.exportTypeEnv, 
                    accExportME : SME.exportModuleEnv)) =>
                  let
                      (****************************************************************)
                      (* Type Env: *)
                      val importTypeEnv = #importTypeEnv (#staticTypeEnv linkageUnit)
                      val exportTypeEnv = #exportTypeEnv (#staticTypeEnv linkageUnit)
                      (*******************************************************************
                       * import signature check
                       *)
                      val (implTypeEnv, unResolvedImportEnv) = 
                          constructImplEnv (importTypeEnv, accExportTE)
                      val importPureTypeEnv = 
                          stripSizeTagTypeEnv importTypeEnv
                      val implPureTypeEnv = 
                          stripSizeTagTypeEnv implTypeEnv
                      val _ = 
                          let
                              val defaultErrorValue = SE.emptyE
                              val loc = getLocLinkageUnit linkageUnit
                          in
                              (SC.checkEnvAndSigma 
                                   (implPureTypeEnv,
                                    ((#importTyConIdSet (#staticTypeEnv linkageUnit)), importPureTypeEnv)))
                              handle exn => (handleException (exn,loc);defaultErrorValue)
                        end
                    val substTyEnv = 
                        FAU.substTyEnvFromEnv (importPureTypeEnv, implPureTypeEnv)

                    (****************************************************************** 
                     * sizeTag computation:
                     * 1.construct sizeTag map from tyConId -> sizeTag, used for
                     * substitution in the target code.
                     * 2.update exported environment of current linkage unit
                     *)
                    val sizeTagSubst = 
                        TCU.sizeTagSubstFromEnv (importTypeEnv, implTypeEnv)
                    val updatedExportTypeEnv =
                        TCU.substSizeTagTypeEnv sizeTagSubst exportTypeEnv

                    val newAccExportTC =
                        let
                          val newExportTypeEnv =
                              TCU.substTyConInTypeEnv substTyEnv updatedExportTypeEnv
                        in
                          TC.extendExportTypeEnvWithExportTypeEnv
                            {newExportTypeEnv = newExportTypeEnv,
                             oldExportTypeEnv = accExportTE}
                        end

                    (****************************************************************)
                    (* Module Env: *)
                    local
                        val staticModuleEnv = 
                            (*substTyConIdStaticModuleEnv substTyConIdEnv*) (#staticModuleEnv linkageUnit)
                    in
                        val (freeGlobalArrayIndex1, 
                             freeEntryPointer1, 
                             indexEnv1, 
                             newExportModuleEnv, 
                             arrayIndices1) =
                            allocateActualIndexInModuleEnv substTyEnv
                                                           (#importModuleEnv staticModuleEnv,
                                                            #exportModuleEnv staticModuleEnv) 
                                                           accExportME
                                                           freeGlobalArrayIndex
                                                           freeEntryPointer
                                                           
                        val newAccExportME : SME.exportModuleEnv =
                            SME.extendExportModuleEnv
                                {newExportModuleEnv = newExportModuleEnv,
                                 oldExportModuleEnv = accExportME}
                    end
                    (*************************************************************
                     * update code
                     *)
                    val newCode1 = 
                        (*substTyConIdTldecs substTyConIdEnv*) (#code linkageUnit)
                    val newCode2 =  
                        substTyTldecs substTyEnv newCode1
                    val newCode3 =  
                        substIndexTldecs indexEnv1 newCode2
                  in
                    (
                     codes @ newCode3,
                     freeGlobalArrayIndex1,
                     freeEntryPointer1,
                     newAccExportTC : TC.exportTypeEnv,
                     newAccExportME : SME.exportModuleEnv 
                     )
                  end
              )
              (nil,
               TO.initialFreeGlobalArrayIndex,
               TO.initialFreeEntryPointer,            
               emptyExportTypeEnv : TC.exportTypeEnv, 
               emptyExportModuleEnv : SME.exportModuleEnv)
              linkageUnits

    fun linkClosed newObjName objNames = 
        let
            val _ = E.initializeTypeinfError()
            val compUnits = 
                foldl (fn (objName, compUnits) =>
                          let
                              val compUnit = unPickle objName LinkageUnitPickler.linkageUnit
                          in
                              compUnits @ [compUnit]
                          end)
                      nil
                      objNames
            val (code, 
                 freeGlobalArrayIndex,
                 freeEntryPointer, 
                 accExportTE, 
                 accExportME) = linkClosedCompUnits compUnits
            val newCompUnit =
                {fileName = newObjName,
                 staticTypeEnv = {importTyConIdSet = ID.Set.empty,
                                  importTypeEnv = TC.emptyTypeEnv,
                                  exportTypeEnv =  accExportTE},
                 staticModuleEnv = {importModuleEnv = SME.emptyImportModuleEnv,
                                    exportModuleEnv = accExportME},
                 code = code}
            val outfile = BinIO.openOut newObjName
            val outstream =
                Pickle.makeOutstream
                    (fn byte => BinIO.output1 (outfile, byte))
            val _ = P.pickle LinkageUnitPickler.linkageUnit newCompUnit outstream
        in
            BinIO.closeOut outfile
        end
            handle sigCheckFail => handleSigCheckFail ()


    fun linkUnClosed newObjName objNames = 
        let
            val _ = E.initializeTypeinfError()
            val compUnits = 
                foldl (fn (objName, compUnits) =>
                          let
                              val compUnit = unPickle objName LinkageUnitPickler.linkageUnit
                          in
                              compUnits @ [compUnit]
                          end)
                      nil
                      objNames
            val (code,
                 tyConIdSet, 
                 freeGlobalArrayIndex,
                 freeEntryPointer, 
                 accImportTE,
                 accExportTE, 
                 accImportME,
                 accExportME) = linkUnClosedLinkageUnits compUnits
            val newCompUnit =
                {fileName = newObjName,
                 staticTypeEnv = {importTyConIdSet = tyConIdSet,
                                  importTypeEnv = accImportTE,
                                  exportTypeEnv =  accExportTE},
                 staticModuleEnv = {importModuleEnv = accImportME,
                                    exportModuleEnv = accExportME},
                 code = code}
            val outfile = BinIO.openOut newObjName
            val outstream =
                Pickle.makeOutstream
                    (fn byte => BinIO.output1 (outfile, byte))
            val _ = P.pickle LinkageUnitPickler.linkageUnit newCompUnit outstream
            val _ = BinIO.closeOut outfile
        in
            ()
        end
            handle sigCheckFail => handleSigCheckFail ()

    fun useObj (context as {topTypeContext, moduleEnv:StaticModuleEnv.moduleEnv},
                (linkageUnit : linkageUnit)) =
        let
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
            val importPureTypeEnv = 
                stripSizeTagTypeEnv importTypeEnv
            val _ = 
                let
                    val defaultErrorValue = SE.emptyE
                in
                    (SC.checkEnvAndSigma 
                         (implEnv,
                          ((#importTyConIdSet (#staticTypeEnv linkageUnit)), 
                           importPureTypeEnv)))
                    handle exn => 
                           (handleException (exn,loc); raise sigCheckFail)
                end
            val substTyEnv = 
                FAU.substTyEnvFromEnv (importPureTypeEnv, implEnv)
            val updatedExportTypeEnv =
                TCU.substTyConInTypeEnv substTyEnv exportTypeEnv
            (****************************************************************** 
             * sizeTag computation:
             * 1.construct sizeTag map from tyConId -> sizeTag, used for
             * substitution in the target code.
             * 2.update exported environment of current linkage unit
             *)
            val sizeTagSubst = 
                TCU.sizeTagSubstFromEnv (importTypeEnv, TC.EnvToTypeEnv(implEnv))
            val updatedExportTypeEnv =
                TCU.substSizeTagTypeEnv sizeTagSubst updatedExportTypeEnv

            local 
                val newPureExportTypeEnv =
                    stripSizeTagTypeEnv updatedExportTypeEnv
            in
                val newTypeContext =
                    {funEnv = SEnv.empty,
                     sigEnv = SEnv.empty,
                     tyConEnv = #1 newPureExportTypeEnv,
                     varEnv = #2 newPureExportTypeEnv,
                     strEnv = #3 newPureExportTypeEnv}
            end
            (****************************************************************)
            (* Module Env: *)
            local
                val staticModuleEnv = #staticModuleEnv linkageUnit
            in
                val (freeGlobalArrayIndex1,
                     freeEntryPointer1, 
                     indexEnv1, 
                     newExportModuleEnv, 
                     arrayIndices1) =
                    allocateActualIndexInModuleEnv 
                        substTyEnv
                        (#importModuleEnv staticModuleEnv,
                         #exportModuleEnv staticModuleEnv) 
                        (PE.projectPathBasisInTop (#topPathBasis moduleEnv))
                        (#freeGlobalArrayIndex moduleEnv)
                        (#freeEntryPointer moduleEnv)
            end

            (* generate initialization code for top array containing value *)
            val initializationCode =
                foldl (fn (arrayIndex, iniArrayCodes) =>
                          let
                              open TypedLambda
                          in
                              iniArrayCodes  @ 
                              [TLVAL
                                  {
                                   bindList =
                                   [{
                                     boundValIdent = Types.VALIDENTWILD StaticEnv.unitty,
                                     boundExp = 
                                     TLINITARRAY
                                         { 
                                          arrayIndex = TO.getPageArrayIndex(arrayIndex), 
                                          size = TO.getPageSize(),
                                          elemTy = TO.pageKindToType(TO.getPageKind(arrayIndex)), 
                                          loc = Loc.noloc
                                          }
                                         }],
                                   loc = Loc.noloc
                                   }]
                          end)
                      nil
                      arrayIndices1

            (****************************************************************)
            val newCode1 = substTyTldecs substTyEnv (#code linkageUnit)
            val newCode2 =  substIndexTldecs indexEnv1  newCode1
        in
            (newTypeContext,
             {
              freeGlobalArrayIndex = freeGlobalArrayIndex1,
              freeEntryPointer = freeEntryPointer1,
              pathBasis = newExportModuleEnv}:StaticModuleEnv.deltaModuleEnv,
             initializationCode @ newCode2)
        end 
            handle sigCheckFail => raise UE.UserErrors (E.getErrorsAndWarnings ())
                                         
  end (* end local *)
end (* end structure *)