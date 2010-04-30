(**
 * x86 instruction selection.
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)
signature X86CODESELECTION =
sig

  val select
      : int option                      (* compile unit count *)
        -> Counters.stamp
        -> AbstractInstruction2.program
        -> Counters.stamp
           * X86Mnemonic.program

end
