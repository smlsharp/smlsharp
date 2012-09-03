(**
 * a pretty printer for the symbolic instructions.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SymbolicInstructionsFormatter.sml,v 1.6 2007/06/07 00:52:00 matsu Exp $
 *)
structure SymbolicInstructionsFormatter =
struct

  (***************************************************************************)

  fun clusterCodeToString (exp : SymbolicInstructions.clusterCode) =
      Control.prettyPrint (SymbolicInstructions.format_clusterCode exp)

  fun functionCodeToString (exp : SymbolicInstructions.functionCode) =
      Control.prettyPrint (SymbolicInstructions.format_functionCode exp)

  fun instructionToString (instruction : SymbolicInstructions.instruction) =
      Control.prettyPrint (SymbolicInstructions.format_instruction instruction)
  
  fun allocMapToString (allocMap : SymbolicInstructions.allocateMap) = 
      Control.prettyPrint (SymbolicInstructions.format_allocateMap allocMap)

  
  fun varAllocToString (varAlloc : SymbolicInstructions.varAlloc) = 
      Control.prettyPrint (SymbolicInstructions.format_varAlloc varAlloc)  

  fun cfgToString (cfg : SymbolicInstructions.clusterCFGs) =
      Control.prettyPrint (SymbolicInstructions.format_clusterCFGs cfg)  

  fun livesProgToString (lvProg : SymbolicInstructions.clusterLivesProg) = 
      Control.prettyPrint (SymbolicInstructions.format_clusterLivesProg lvProg)  
      
(***************************************************************************)

end
