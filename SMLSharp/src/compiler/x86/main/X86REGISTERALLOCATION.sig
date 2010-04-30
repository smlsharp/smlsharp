(**
 * x86 register allocation.
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)
signature X86REGISTERALLOCATION =
sig

  val allocate
      : Counters.stamp ->
        X86Mnemonic.program ->
        Counters.stamp * X86Mnemonic.program

end
