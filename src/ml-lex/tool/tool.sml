(*
 * Running ML-Lex from CM.
 *
 *   (C) 1999 Lucent Technologies, Bell Laboratories
 *
 * Author: Matthias Blume (blume@kurims.kyoto-u.ac.jp)
 *)
structure LexTool = struct
    val _ = Tools.registerStdShellCmdTool
	{ tool = "ML-Lex",
	  class = "mllex",
	  cmdStdPath = fn () => ("ml-lex", []),
	  template = NONE,
	  extensionStyle = Tools.EXTEND [("sml", SOME "sml", fn too => too)],
	  dflopts = [] }
end
