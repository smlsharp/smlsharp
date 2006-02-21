(**
 * Copyright (c) 2006, Tohoku University.
 * Assign global index to val declarations
 * @author Liu Bochao
 * @version $Id: IndexAllocator.sml,v 1.10 2006/02/18 11:06:33 duchuu Exp $
 *)
structure IndexAllocator =
struct
local
    structure T = Types
    structure SE = StaticEnv
    structure TO = TopObject
    structure TFCU = TypedFlatCalcUtils
    structure PE = PathEnv
    open TypedFlatCalc 
in
   fun allocateIndex (freeEntryPointer, 
                      varIdInfo as {id,displayName,ty}:varIdInfo,
                      loc) =
       let
         val pageTy = TO.convertTyToPagetype ty
         val (allocatedPageArrayIndex, allocatedOffset) = 
             case IEnv.find(freeEntryPointer,pageTy) of
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
         val (freePageArrayIndex,freeOffset) =
             if freeOffset = TO.pageSize then
               (
                (TO.globalPageArrayIndex := !TO.globalPageArrayIndex + 0w1;
                 !TO.globalPageArrayIndex), 
                0)
             else (allocatedPageArrayIndex, freeOffset)
         val newFreeEntryPointer = 
             IEnv.insert(
                         freeEntryPointer,
                         pageTy,
                         (freePageArrayIndex,freeOffset)
                         )
       in
         (
          newPageFlag,
          newFreeEntryPointer,
          deltaIndexMap,
          (pageTy,allocatedPageArrayIndex,allocatedOffset)
          )
       end


   fun makePreludeAndFinaleDec 
         (freeEntryPointer, (varIdInfo:varIdInfo,loc)) =
       let
         val (newPageFlag, newFreeEntryPointer, deltaIndexMap, allocatedIndex) =
             allocateIndex(freeEntryPointer, varIdInfo, loc)
         val elemTy = TO.pageElemTy allocatedIndex 
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
             if newPageFlag then
               let
                 val pageArrayDec =
                     TFPINITARRAY (
                                   TO.getPageArrayIndex allocatedIndex,
                                   TO.pageSize,
                                   elemTy,
                                   Loc.noloc
                                  )
               in
                 [pageArrayDec]
               end
             else nil
       in
         (
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

   fun makePreludeAndFinaleDecs(freeEntryPointer, pathBasis) =
       let
         val visibleVars = visibleVarsInPathBasis pathBasis 
         val (freeEntryPointer, deltaIndexMap, preludeDecs, finaleDecs) =
             foldl
               (fn (varIdInfoLoc,
                    (freeEntryPointer, accIndexMap, accPreludeDecs, accFinaleDecs)) =>
                   let
                     val (newFreeEntryPointer, 
                          deltaIndexMap, 
                          setGlobalValueDec, 
                          initializedPageDecs) =
                         makePreludeAndFinaleDec (freeEntryPointer, varIdInfoLoc)
                   in
                     (
                      newFreeEntryPointer,
                      ID.Map.unionWith #1 (deltaIndexMap, accIndexMap),
                      accPreludeDecs @ initializedPageDecs,
                      accFinaleDecs @  [setGlobalValueDec]
                      )
                   end
                     )
               (freeEntryPointer, 
                TO.emptyIndexMap, 
                nil,
                nil)
               visibleVars
       in
         (freeEntryPointer, deltaIndexMap, preludeDecs, finaleDecs) 
       end
end
end
