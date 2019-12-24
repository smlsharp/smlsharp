(* Modified by Katsuhiro Ueno on 2011-Nov-25 to port ml-yacc to SML#. *)
(* export-yacc.sml
 *
 * ML-Yacc Parser Generator (c) 1991 Andrew W. Appel, David R. Tarditi
 *)
(* 2012-8-19 ohori. Type annotation added to parseGen *) 

structure ExportParseGen : sig
    val parseGen : (string * string list) -> OS.Process.status
end = struct
    fun err msg = TextIO.output (TextIO.stdErr, msg)

    exception Interrupt;

    (* This function applies operation to ().  If it handles an interrupt
       signal (Control-C), it raises the exception Interrupt. Example:
       (handleInterrupt foo) handle Interrupt => print "Bang!\n" *)

    fun handleInterrupt (operation : unit -> unit) =
(*
(* Ueno (2011-11-25): SML# does not have Signals and callcc. *)
      let exception Done
          val old'handler = Signals.inqHandler(Signals.sigINT)
          fun reset'handler () =
            Signals.setHandler(Signals.sigINT, old'handler)
      in (SMLofNJ.Cont.callcc (fn k =>
             (Signals.setHandler(Signals.sigINT, Signals.HANDLER(fn _ => k));
               operation ();
               raise Done));
           err ("\n--- Interrupt ml-yacc ---\n");
           raise Interrupt)
          handle Done => (reset'handler ())
               | exn  => (reset'handler (); raise exn)
      end
*)
      operation ()

    val exit = OS.Process.exit

(* 2019-07-06: Ueno: add -s and -p prefix command line options
    fun parseGen (_, argv) = let
	fun parse_gen () =
	    case argv of
		[file] => (ParseGen.parseGen file; exit OS.Process.success)
	      | _ => (err("Usage: ml-yacc filename\n");
		      exit OS.Process.failure)
*)
    fun parseGen (name, argv) = let
        fun die msg = (err (concat msg); OS.Process.exit OS.Process.failure)
        fun die' msg = die (name :: ": " :: msg)
        fun getopt r nil nil = (r, nil)
          | getopt r nil ("--"::t) = (r, t)
          | getopt r nil (h::t) =
            if String.isPrefix "-" h andalso size h > 1
            then getopt r (tl (String.explode h)) t else (r, h :: t)
          | getopt r (#"p"::nil) nil = die' ["-p requires an argument\n"]
          | getopt r (#"p"::nil) (h::t) = getopt (SOME h, #2 r) nil t
          | getopt r (#"p"::t) l = getopt (SOME (String.implode t), #2 r) nil l
          | getopt r (#"s"::t) l = getopt (#1 r, true) t l
          | getopt r (c::t) _ = die' ["invalid option -" ^ str c]
        fun parse_gen () =
            case getopt (NONE, false) nil argv of
              ((p, s), [file]) =>
              (ParseGen.parseGen file {p=p, s=s}; exit OS.Process.success)
            | _ => die ["usage: ", name, " [-s] [-p output_prefix] input\n"]
    in
	(handleInterrupt parse_gen; OS.Process.success)
	handle Interrupt => OS.Process.failure
	     | ex => (err (String.concat ["? ml-yacc: uncaught exception ",
					  General.exnMessage ex, "\n"]);
		      OS.Process.failure)
    end
end
