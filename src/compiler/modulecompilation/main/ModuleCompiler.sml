(**
 * Module compiler flattens structure.
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: ModuleCompiler.sml,v 1.121 2007/01/21 13:41:32 kiyoshiy Exp $
 *)
structure ModuleCompiler : MODULECOMPILER  = 
struct
local

  structure T = Types
  structure P = Path
  structure TO = TopObject
  structure MCM = ModuleCompileMod
  structure TFCU = TypedFlatCalcUtils
  structure PE = PathEnv
  open TypedCalc TypedFlatCalc 
in
 
   fun moduleCompile {freeGlobalArrayIndex, freeEntryPointer, topPathBasis} tptopdecs =
       let
         val prefix = P.NilPath             
         val tptopGroups = MCM.tptopdecsToTpTopGroups tptopdecs
         val (newFreeGlobalArrayIndex, newFreeEntryPointer, liftedPathBasis, tfpdecs) = 
             MCM.tptopGroupsToTfpdecs freeGlobalArrayIndex 
                                      freeEntryPointer
                                      topPathBasis
                                      PE.emptyPathBasis
                                      prefix
                                      tptopGroups
       in
         (
          {
           freeGlobalArrayIndex = newFreeGlobalArrayIndex,
           freeEntryPointer = newFreeEntryPointer,
           pathBasis = liftedPathBasis
           },
          tfpdecs
         )
       end

   (* No initialization of global array code is constructed,
    * used in linking for compiling type instantiation value identfier
    *)
   fun moduleCompileCodeFragmentWithPathBasis
           {freeGlobalArrayIndex, freeEntryPointer, pathBasis} tpstrdecs =
       let
         val prefix = P.NilPath             
         val (newFreeGlobalArrayIndex,
              newFreeEntryPointer,
              deltaPathBasis,
              deltaLiftedPathBasis,
              (prelude, body, finale)) =
             MCM.STRDECGroupToTopdecs tpstrdecs
                                      freeGlobalArrayIndex 
                                      freeEntryPointer
                                      prefix
                                      PE.emptyTopPathBasis
                                      pathBasis

       in
         (
          {
           freeGlobalArrayIndex = newFreeGlobalArrayIndex,
           freeEntryPointer = newFreeEntryPointer,
           pathBasis = deltaLiftedPathBasis
           },
          body @ finale
         )
       end

   fun compileLinkageUnit tptopdecs =
       let
         val {freeGlobalArrayIndex, 
              freeEntryPointer, 
              topPathBasis} = InitialModuleContext.initialModuleContext
         val prefix = P.NilPath             
         val tptopGroups = MCM.tptopdecsToTpTopGroups tptopdecs
         val (newFreeGlobalArrayIndex, newFreeEntryPointer, liftedPathBasis, importPathBasis, tfpdecs) = 
             MCM.tptopGroupdecsToTfpdecs' freeGlobalArrayIndex 
                                          freeEntryPointer
                                          topPathBasis
                                          prefix
                                          tptopGroups
         val moduleEnv =
             {importModuleEnv = importPathBasis,
              exportModuleEnv = liftedPathBasis}
       in
         (moduleEnv, tfpdecs)
       end
end
end
