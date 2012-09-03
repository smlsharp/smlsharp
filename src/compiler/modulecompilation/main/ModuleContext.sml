(**
 * Module Compilation Context 
 * 
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: ModuleContext.sml,v 1.6 2006/02/27 06:23:02 bochao Exp $
 *)

structure ModuleContext =
struct
local
  structure PE = PathEnv
  structure TO = TopObject
 
in
   type context = 
        {
         topPathBasis : PE.topPathBasis,
         pathBasis : PE.pathBasis,
         prefix : Path.path
        }
        
   fun extendContextWithPathEnv
         ({topPathBasis, pathBasis, prefix},
          newPathEnv) 
     =
     {
      topPathBasis = topPathBasis,
      pathBasis = PE.extendPathBasisWithPathEnv 
                    {
                     pathBasis = pathBasis,
                     pathEnv = newPathEnv
                     },
      prefix = prefix
      }

   fun updateContextWithPrefix
       ({topPathBasis, pathBasis, prefix}, newPrefix)
     = 
     {
      topPathBasis = topPathBasis,
      pathBasis =  pathBasis,
      prefix = newPrefix
      }

   fun lookupStructureInContext 
         ({topPathBasis, pathBasis,...}:context, path)
     = PE.lookupPathStrEnv (topPathBasis,pathBasis,path)

   fun lookupFunctorInContext
         ({topPathBasis, pathBasis,...}:context, funcName)
     = PE.lookupFunctor (topPathBasis, pathBasis, funcName)
       
end       
end
