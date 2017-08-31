(**
 * interactive program execution
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure RunLoop =
struct

  val isatty = _import "isatty" : int -> int

  type options =
      {options : Interactive.options, errorOutput : TextIO.outstream}

  fun userErrorToString e =
      Bug.prettyPrint (UserError.format_errorInfo e)

  fun initInteractive () =
      let
        val lineCount = ref 1
        val isTTY = isatty 0 <> 0
        fun read (isFirst, _:int) =
            let
              val prompt = if isFirst then "# " else "> "
              val _ = if isTTY
                      then (TextIO.output (TextIO.stdOut, prompt);
                            TextIO.flushOut TextIO.stdOut)
                      else ()
              val line = TextIO.inputLine TextIO.stdIn
              val _ = lineCount := !lineCount + 1
            in
              case line of NONE => "" | SOME s => s
            end
      in
        {lineCount = lineCount, read = read}
      end

  fun interactiveInput {lineCount, read} =
      Parser.setup {sourceName = "(interactive)",
                    read = read,
                    mode = Parser.Interactive,
                    initialLineno = !lineCount}

  fun handleError ({errorOutput, ...}:options) e =
      let
        fun puts s = TextIO.output (errorOutput, s ^ "\n")
      in
        case e of
          UserError.UserErrors nil =>
          puts "[BUG] empty UserErrors"
        | UserError.UserErrors errs =>
          app (fn e => puts (userErrorToString e)) errs
        | Bug.Bug _ =>
          puts (exnMessage e)
        | Interactive.LinkError (e as OS.SysErr (msg, _)) =>
          (puts ("Link error : " ^ exnMessage e);
           puts "Perhaps incorrect name in _import declaration.")
        | Interactive.UncaughtException e =>
          puts ("uncaught exception " ^ exnMessage e)
        | CoreUtils.Failed {command, message} =>
          (puts ("command failed: " ^ command); puts message)
        | _ => raise e
      end

  datatype 'a try = RET of 'a | ERR of exn

  val run = Interactive.run

  fun interactive options context preload =
      let
        val _ = Control.interactiveMode := true
        val session = Interactive.start (#options options)
        val _ = Interactive.loadObjectFiles session preload
        val state = initInteractive ()
        fun error context e =
            (handleError options e;
             loop context (interactiveInput state))
        and loop context input =
            case RET (Parser.isEOF input) handle e => ERR e of
              RET true => ()
            | ERR e => error context e
            | RET false =>
              case RET (run session context input) handle e => ERR e of
                ERR e => error context e
              | RET newContext =>
                (if !Control.doProfile
                 then (print "Time Profile:\n"; print (Counter.dump ()))
                 else ();
(*
                 InteractiveEnv.setCurrentEnv (#topEnv context);
*)
                 loop (Top.extendContext (context, newContext)) input)
      in
        (
(*
         InteractiveEnv.setCurrentEnv (#topEnv context);
*)
         loop context (interactiveInput state)
        )
      end

end
