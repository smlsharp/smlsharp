(**
 * Initial module context for module compilation
 * 
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: InitialModuleContext.sml,v 1.29 2007/01/21 13:41:32 kiyoshiy Exp $
 *)
structure InitialModuleContext:INITIALMODULECONTEXT =
struct
  local 
    open PathEnv TopObject
    structure ITC = InitialTypeContext
  in

    val initialPathVarEnv : pathVarEnv = emptyPathVarEnv
                    
    val initialPathStrEnv : pathStrEnv = emptyPathStrEnv

    val initialPathEnv = (initialPathVarEnv,initialPathStrEnv)
                         
    val initialTopPathEnv = 
        extendTopPathEnvWithPathEnv {topPathEnv = SEnv.empty, pathEnv = initialPathEnv}
        
    val initialTopPathBasis = (SEnv.empty,initialTopPathEnv)

    val initialModuleContext = { 
                                freeGlobalArrayIndex = initialFreeGlobalArrayIndex,
                                freeEntryPointer = initialFreeEntryPointer,
                                topPathBasis = initialTopPathBasis 
                                } 
  end
end
