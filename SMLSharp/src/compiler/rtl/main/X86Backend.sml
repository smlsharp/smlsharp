(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure X86Backend =
  RTLBackend(structure Select = X86Select
             structure Stabilize = X86Stabilize
             structure Coloring = X86Coloring
             structure Frame = X86Frame
             structure Emit = X86Emit
             structure AsmGen = X86AsmGen
             structure Target = X86Asm)
