(**
 * @copyright (c) 2006, Tohoku University.
 * @author Yutaka Matsuno
 * @version $Id: STACK_REALLOCATION.sig,v 1.2 2007/12/23 17:11:43 matsu Exp $
 *)

signature STACK_REALLOCATION = sig

    val clusterGraphColoring : SymbolicInstructions.clusterCode  -> SymbolicInstructions.clusterCode
    val clusterGraphColoring2 : SymbolicInstructions.clusterCode  -> SymbolicInstructions.clusterCode
end
