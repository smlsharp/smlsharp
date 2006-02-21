(**
 * Copyright (c) 2006, Tohoku University.
 *
 * @author Liu Bochao
 * @version $Id: InitialModuleContext.sml,v 1.25 2006/02/18 16:04:06 duchuu Exp $
 *)
structure InitialModuleContext:INITIALMODULECONTEXT =
struct
  local 
    open  Types PathEnv TopObject
    structure TU = TypesUtils
    structure ITC = InitialTypeContext
    structure SE = StaticEnv
  in

    val initialPathVarEnv : pathVarEnv = emptyPathVarEnv
                    
    val initialPathStrEnv : pathStrEnv = emptyPathStrEnv

    val initialPathEnv = (initialPathVarEnv,initialPathStrEnv)
                         
    val initialTopPathEnv = 
        extendTopPathEnvWithPathEnv {topPathEnv = SEnv.empty, pathEnv = initialPathEnv}
        
    val initialTopPathBasis = (SEnv.empty,initialTopPathEnv)

    val initialModuleContext = { 
                                freeEntryPointer = initialFreeEntryPointer,
                                topPathBasis = initialTopPathBasis 
                                } 
  end
end
