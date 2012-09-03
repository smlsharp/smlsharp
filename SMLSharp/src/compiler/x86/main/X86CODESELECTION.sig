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
        -> AbstractInstruction2.program
        -> X86Mnemonic.program

end
