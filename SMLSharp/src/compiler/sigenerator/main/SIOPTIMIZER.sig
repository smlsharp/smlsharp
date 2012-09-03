(** symbolic code optimization
 * @copyright (c) 2006, Tohoku University.
 * @author Nguyen Huu-Duc
 * @version $Id: SIOPTIMIZER.sig,v 1.4 2008/08/06 17:23:40 ohori Exp $
 *)
signature SIOPTIMIZER = 
sig
    val initialize_ALWAYS_Entry : LocalVarID.id -> unit
    val optimizeInstruction : SIGContext.context -> SymbolicInstructions.instruction -> SymbolicInstructions.instruction
    val deadCodeEliminate : SymbolicInstructions.clusterCode -> SymbolicInstructions.clusterCode
end
