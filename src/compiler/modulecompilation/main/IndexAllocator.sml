(**
 * Assign global index to val declarations
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: IndexAllocator.sml,v 1.14 2006/03/02 12:46:47 bochao Exp $
 *)
structure IndexAllocator =
struct
local
    structure T = Types
    structure SE = StaticEnv
    structure TO = TopObject
    structure TFCU = TypedFlatCalcUtils
    structure PE = PathEnv
    structure BT = BasicTypes
    open TypedFlatCalc 
in
   fun allocateIndex (freeGlobalArrayIndex,
                      freeEntryPointer, 
                      varIdInfo as {id,displayName,ty}:varIdInfo,
                      loc) =
       let
         val pageTy = TO.convertTyToPageKind ty
         val (allocatedPageArrayIndex, allocatedOffset) = 
             case IEnv.find(freeEntryPointer, pageTy) of
               SOME x => x
             | NONE => raise Control.BugWithLoc ("invalid page type:"
                                                 ^displayName,loc)
         val newPageFlag = allocatedOffset = 0
         val deltaIndexMap = 
             ID.Map.singleton (
                               id,
                               (
                                displayName,
                                (pageTy, allocatedPageArrayIndex, allocatedOffset)
                                )
                               )
         val freeOffset = allocatedOffset + 1
         val (freePageArrayIndex, newFreeGlobalArrayIndex, freeOffset) =
             if freeOffset = TO.getPageSize() then
                 (freeGlobalArrayIndex, freeGlobalArrayIndex + 0w1:BT.UInt32, 0)
             else (allocatedPageArrayIndex, freeGlobalArrayIndex, freeOffset)
         val newFreeEntryPointer = 
             IEnv.insert(
                         freeEntryPointer,
                         pageTy,
                         (freePageArrayIndex,freeOffset)
                         )
       in
         (
          newPageFlag,
          newFreeGlobalArrayIndex,
          newFreeEntryPointer,
          deltaIndexMap,
          (pageTy,allocatedPageArrayIndex,allocatedOffset)
          )
       end

   fun allocateAbstractIndex freeGlobalArrayIndex freeEntryPointer =
       let
         val (allocatedPageArrayIndex, allocatedOffset) = 
             case IEnv.find(freeEntryPointer, TO.ABSTRACT_PAGE_KIND) of
               SOME x => x
             | NONE => raise Control. Bug("abstract page non exist")
         val newPageFlag = allocatedOffset = 0
         val freeOffset = allocatedOffset + 1
         val (freePageArrayIndex, newFreeGlobalArrayIndex, freeOffset) =
             if freeOffset = TO.getPageSize() then
                 (freeGlobalArrayIndex, freeGlobalArrayIndex + 0w1:BT.UInt32, 0)
             else (allocatedPageArrayIndex, freeGlobalArrayIndex, freeOffset)
         val newFreeEntryPointer = 
             IEnv.insert(
                         freeEntryPointer,
                         TO.ABSTRACT_PAGE_KIND,
                         (freePageArrayIndex, freeOffset)
                         )
       in
         (
          newFreeGlobalArrayIndex,
          newFreeEntryPointer,
          (TO.ABSTRACT_PAGE_KIND, allocatedPageArrayIndex, allocatedOffset))
       end

   fun makePreludeAndFinaleDec 
         (globalArrayIndex, freeEntryPointer, (varIdInfo:varIdInfo,loc)) =
       let
         val (newPageFlag, 
              newFreeGlobalArrayIndex,
              newFreeEntryPointer, 
              deltaIndexMap,
              allocatedIndex) =
             allocateIndex(globalArrayIndex, freeEntryPointer, varIdInfo, loc)
         val elemTy = TO.pageKindToType (TO.getPageKind allocatedIndex) 
         val setGlobalValueDec =
             TFPSETGLOBALVALUE
               (
                TO.getPageArrayIndex allocatedIndex,
                TO.getOffset allocatedIndex,
                TFPCAST(TFPVAR({id = #id varIdInfo, 
                                displayName = #displayName varIdInfo,
                                ty = #ty varIdInfo}, 
                               loc),
                        elemTy,
                        loc),
                elemTy,
                Loc.noloc
                )
         val initializedPageDecs =
             if !Control.doSeparateCompilation then
               nil
             else
               if newPageFlag then
                 [TFPINITARRAY 
                    (
                     TO.getPageArrayIndex allocatedIndex,
                     TO.getPageSize(),
                     elemTy,
                     Loc.noloc
                     )]
               else nil
       in
         (
          newFreeGlobalArrayIndex,
          newFreeEntryPointer,
          deltaIndexMap,
          setGlobalValueDec,
          initializedPageDecs
          )
       end
             
   fun visibleVarsInPathVarEnv pathVarEnv =
       SEnv.foldl (fn (item, visibleVars) =>
                      case item of
                        PE.CurItem (pathVar, id, ty, loc) =>
                        ({id = id, 
                         displayName = PE.pathVarToString pathVar,
                         ty = ty},
                         loc) :: visibleVars
                      | PE.TopItem _ => visibleVars
                  )
                  nil
                  pathVarEnv

   fun visibleVarsInPathStrEnv pathStrEnv =
       SEnv.foldl (fn (PE.PATHAUX (pathVarEnv, pathStrEnv), visibleVars) =>
                      let
                        val visibleVars1 = visibleVarsInPathVarEnv pathVarEnv
                        val visibleVars2 = visibleVarsInPathStrEnv pathStrEnv
                      in
                        visibleVars1 @ visibleVars2 @ visibleVars
                      end)
                  nil
                  pathStrEnv

   fun visibleVarsInPathEnv (pathEnv as (pathVarEnv, pathStrEnv)) =
       visibleVarsInPathVarEnv pathVarEnv @ 
       visibleVarsInPathStrEnv pathStrEnv

   fun visibleVarsInPathBasis (pathBasis as (pathFunEnv, pathEnv)) =
       visibleVarsInPathEnv pathEnv

   fun makePreludeAndFinaleDecs(freeGlobalArrayIndex, freeEntryPointer, pathBasis) =
       let
         val visibleVars = visibleVarsInPathBasis pathBasis 
         val (freeGlobalArrayIndex, freeEntryPointer, deltaIndexMap, preludeDecs, finaleDecs) =
             foldl
               (fn (varIdInfoLoc,
                    (freeGlobalArrayIndex, 
                     freeEntryPointer, 
                     accIndexMap, 
                     accPreludeDecs, 
                     accFinaleDecs)) =>
                   let
                     val (
                          newFreeGlobalArrayIndex,
                          newFreeEntryPointer, 
                          deltaIndexMap, 
                          setGlobalValueDec, 
                          initializedPageDecs) =
                         makePreludeAndFinaleDec (freeGlobalArrayIndex, freeEntryPointer, varIdInfoLoc)
                   in
                     (
                      newFreeGlobalArrayIndex,
                      newFreeEntryPointer,
                      ID.Map.unionWith #1 (deltaIndexMap, accIndexMap),
                      accPreludeDecs @ initializedPageDecs,
                      accFinaleDecs @  [setGlobalValueDec]
                      )
                   end
                     )
               (
                freeGlobalArrayIndex,
                freeEntryPointer, 
                TO.emptyIndexMap, 
                nil,
                nil)
               visibleVars
       in
         (freeGlobalArrayIndex, freeEntryPointer, deltaIndexMap, preludeDecs, finaleDecs) 
       end

   fun makePreludeAndFinaleDecs_ObjFile (freeGlobalArrayIndex, freeEntryPointer, pathBasis) =
       let
           val (freeGlobalArrayIndex, freeEntryPointer, deltaIndexMap, preludeDecs, finaleDecs) =
               makePreludeAndFinaleDecs (freeGlobalArrayIndex, freeEntryPointer, pathBasis)
       in
           (freeGlobalArrayIndex, freeEntryPointer, deltaIndexMap, nil, finaleDecs)
       end

   (* for Linker *)
   fun allocateActualIndexAtLinking (freeGlobalArrayIndex, freeEntryPointer, {displayName,ty}) =
       let
         val pageKind = TO.convertTyToPageKind ty
         val (allocatedPageArrayIndex, allocatedOffset) = 
             case IEnv.find(freeEntryPointer, pageKind) of
               SOME x => x
             | NONE => raise Control.Bug ("invalid page type:" ^displayName)
         val newPageFlag = allocatedOffset = 0
         val freeOffset = allocatedOffset + 1
         val (freePageArrayIndex, newFreeGlobalArrayIndex, freeOffset) =
             if freeOffset = TO.getPageSize() then
                 (freeGlobalArrayIndex, freeGlobalArrayIndex + 0w1:BT.UInt32, 0)
             else (allocatedPageArrayIndex, freeGlobalArrayIndex, freeOffset)
         val newFreeEntryPointer = 
             IEnv.insert(
                         freeEntryPointer,
                         pageKind,
                         (freePageArrayIndex,freeOffset)
                         )
       in
         (
          newPageFlag,
          newFreeGlobalArrayIndex,
          newFreeEntryPointer,
          (pageKind, allocatedPageArrayIndex, allocatedOffset)
          )
       end

end
end
