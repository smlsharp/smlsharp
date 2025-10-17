(**
 * interactive program execution
 *
 * @copyright (C) 2021 SML# Development Team.
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
                           handle IO.Io _ => ()  (* user may close stdOut *)
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
      Parser.setup {read = read,
                    source = Loc.INTERACTIVE,
                    initialLineno = !lineCount}

  fun handleError ({errorOutput, ...}:options) e =
      let
        fun puts s =
            TextIO.output (errorOutput, s ^ "\n")
            handle IO.Io _ => ()  (* user may close errorOutput *)
        fun isSIGINT e =
            case e of
              IO.Io {cause, ...} => isSIGINT cause
            | SignalHandler.Signal [SignalHandler.SIGINT] => true
            | _ => false
        fun isIntr e =
            case e of
              OS.SysErr (_, SOME s) => OS.errorName s = "intr"
            | IO.Io {cause, ...} => isIntr cause
            | SignalHandler.Signal [SignalHandler.SIGINT] => true
            | Interactive.LinkError e => isIntr e
            | Interactive.UncaughtException e => isSIGINT e
            | _ => false
      in
        if isIntr e then puts "Interrupt" else
        case e of
          UserError.UserErrors nil =>
          puts "[BUG] empty UserErrors"
        | UserError.UserErrors errs =>
          app (fn e => puts (userErrorToString e)) errs
        | Bug.Bug _ => 
          puts (exnMessage e)
        | Interactive.UncaughtException e =>
          puts ("uncaught exception " ^ exnMessage e)
        | Interactive.LinkError (ShellUtils.Fail {command, status, output}) =>
          (puts "link failed:";
           CoreUtils.cat [#stderr output] errorOutput)
        | Interactive.LinkError (DynamicLink.Error msg) =>
          puts ("dynamic link failed: " ^ msg)
        | _ => raise e
      end

  datatype 'a try = RET of 'a | ERR of exn

  val run = Interactive.run

  fun interactive options context preload =
      let
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
