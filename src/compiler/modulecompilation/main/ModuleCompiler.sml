(**
 * Module compiler flattens structure.
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: ModuleCompiler.sml,v 1.119 2006/03/02 12:46:47 bochao Exp $
 *)
structure ModuleCompiler : MODULECOMPILER  = 
struct
local

  structure T = Types
  structure P = Path
  structure SE = StaticEnv
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
