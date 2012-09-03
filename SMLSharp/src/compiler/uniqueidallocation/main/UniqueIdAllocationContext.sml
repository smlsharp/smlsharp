(**
 * Module Compilation Context 
 * 
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: UniqueIdAllocationContext.sml,v 1.8 2008/01/31 03:07:22 bochao Exp $
 *)

structure UniqueIdAllocationContext =
struct
local
    structure NPEnv = NameMap.NPEnv 
    structure VIC = VarIDContext
in

   type context = 
        {
         topVarExternalVarIDBasis : VIC.topExternalVarIDBasis,
         varIDBasis : VIC.varIDBasis
        }

   val emptyTopExternalVarIDBasis = (SEnv.empty, SEnv.empty) : VIC.topExternalVarIDBasis
   val initialTopExternalVarIDBasis
 = (SEnv.empty, #topVarIDEnv BuiltinContext.builtinContext) : VIC.topExternalVarIDBasis

   fun extendContextWithVarIDEnv
           ({topVarExternalVarIDBasis, varIDBasis:VIC.varIDBasis}, newVarIDEnv) 
     =
     {
      topVarExternalVarIDBasis = topVarExternalVarIDBasis,
      varIDBasis = (#1 varIDBasis, NPEnv.unionWith #1 (newVarIDEnv, #2 varIDBasis))
      }: context

   fun lookupFunctorInContext
         ({topVarExternalVarIDBasis, varIDBasis,...}:context, funcName)
     = VIC.lookupFunctor (topVarExternalVarIDBasis, varIDBasis, funcName)

   
       
end       
end
