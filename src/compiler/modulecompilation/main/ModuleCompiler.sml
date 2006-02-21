(**
 * Copyright (c) 2006, Tohoku University.
 * Module compiler flattens structure.
 * @author Liu Bochao
 * @version $Id: ModuleCompiler.sml,v 1.116 2006/02/18 11:06:34 duchuu Exp $
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

   type moduleEnv = {
                     freeEntryPointer : TO.freeEntryPointer,
                     topPathBasis : PathEnv.topPathBasis
                    } 

   type deltaModuleEnv = 
        {
         freeEntryPointer : TO.freeEntryPointer,
         pathBasis : PathEnv.pathBasis
        }

   fun extendModuleEnvWithDeltaModuleEnv 
         {
          deltaModuleEnv = {freeEntryPointer = freeEntryPointer1,
                            pathBasis = liftedPathBasis : PE.pathBasis},
          moduleEnv = {freeEntryPointer = freeEntryPointer2,
                       topPathBasis = topPathBasis : PE.topPathBasis}
          }
       =
       {
        freeEntryPointer = freeEntryPointer1,
        topPathBasis = 
        PE.extendTopPathBasisWithPathBasis 
          {topPathBasis = topPathBasis,
           pathBasis = liftedPathBasis}
       }

   fun modulecompile {freeEntryPointer, topPathBasis} tptopdecs =
       let
         val prefix = P.NilPath             
         val (newFreeEntryPointer, liftedPathBasis, tfpdecs) = 
             MCM.tptopdecsToTfpdecs freeEntryPointer topPathBasis prefix tptopdecs
(*         val deltaTopPathBasis = 
             PE.extendTopPathBasisWithPathBasis 
               {
                topPathBasis = PE.emptyTopPathBasis,
                pathBasis = liftedPathBasis
                }
*)
       in
         (
          {
           freeEntryPointer = newFreeEntryPointer,
           pathBasis = liftedPathBasis
(*           topPathBasis = deltaTopPathBasis *)
           },
          tfpdecs
         )
       end
end
end
