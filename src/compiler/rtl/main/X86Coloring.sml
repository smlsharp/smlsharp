(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure X86Coloring =
  RTLColoring(structure Constraint = X86Constraint
              structure Subst = X86Subst
              structure Emit = X86Emit)
