(**
 * Copyright (c) 2006, Tohoku University.
 *
 * Initial module context for module compilation
 * @author Liu Bochao
 * @version $Id: INITIALMODULECONTEXT.sig,v 1.3 2006/02/18 04:59:23 ohori Exp $
 *)
signature INITIALMODULECONTEXT =
sig
    val initialModuleContext : ModuleCompiler.moduleEnv
end
