(* export-lex.sml
 *
 * Revision 1.2  2000/03/07 04:01:05  blume
 * - build script now use new ml-build mechanism
 *)
structure ExportLexGen : sig
    val lexGen : (string * string list) -> OS.Process.status
end = struct

    exception Interrupt

  (* This function applies operation to ().  If it handles an interrupt
   * signal (Control-C), it raises the exception Interrupt.  Example:
   * (handleInterrupt foo) handle Interrupt => print "Bang!\n"
   *)
    fun handleInterrupt (operation : unit -> unit) =
(* Ueno (2011-11-25): SML# does not have Signals and callcc. *)
      operation ()

    fun err msg = TextIO.output(TextIO.stdErr, String.concat msg)

    fun lexGen (name, args) = let
(* Ueno (2019-04-29): allow users to specify output file name *)
	fun die msg = (err msg; OS.Process.exit OS.Process.failure)
	fun die' msg = die (name :: ": " :: msg)
	fun getopt r nil nil = (r, nil)
	  | getopt r nil ("--" :: t) = (r, t)
	  | getopt r nil (h :: t) =
	    if String.isPrefix "-" h andalso size h > 1
	    then getopt r (tl (String.explode h)) t else (r, h :: t)
	  | getopt r (#"o" :: nil) nil = die' ["-o requires an argument\n"]
	  | getopt r (#"o" :: nil) (h :: t) = getopt (SOME h) nil t
	  | getopt r (#"o" :: t) l = getopt (SOME (String.implode t)) nil l
	  | getopt r (c :: t) _ = die' ["illegal option -", str c, "\n"]
	fun lex_gen () =
	    case getopt NONE nil args of
		(_, nil) => die ["usage: ", name, " [-o output] input ...\n"]
	      | (out, file::files) =>
		(LexGen.lexGen out file; List.app (LexGen.lexGen NONE) files)
    in
	(handleInterrupt lex_gen; OS.Process.success)
	handle Interrupt => (err [name, ": Interrupt\n"]; OS.Process.failure)
	     | any => (err [name, ": uncaught exception ",
			    General.exnMessage any, "\n"];
		       OS.Process.failure)
    end
end
