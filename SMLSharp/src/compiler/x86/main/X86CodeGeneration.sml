(**
 * x86 code genearation
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

structure X86CodeGeneration : sig

  val codeGen : X86Mnemonic.program -> string

end =
struct

  fun codeGen program =
      case #ossys (Control.targetInfo ()) of
        "darwin" => Control.prettyPrint (X86Mnemonic.darwin_program program)
      | "linux" => Control.prettyPrint (X86Mnemonic.att_program program)
      | "freebsd" => Control.prettyPrint (X86Mnemonic.att_program program)
      | "openbsd" => Control.prettyPrint (X86Mnemonic.att_program program)
      | "netbsd" => Control.prettyPrint (X86Mnemonic.att_program program)
      | x => raise Control.Bug ("unknown target os: " ^ x)

end
