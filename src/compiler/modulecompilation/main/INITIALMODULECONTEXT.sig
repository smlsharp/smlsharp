(**
 * Initial module context for module compilation
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Liu Bochao
 * @version $Id: INITIALMODULECONTEXT.sig,v 1.5 2006/03/02 12:46:46 bochao Exp $
 *)
signature INITIALMODULECONTEXT =
sig
    val initialModuleContext : StaticModuleEnv.moduleEnv
end
