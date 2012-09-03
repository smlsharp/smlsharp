(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestCaseRunner.sml,v 1.27 2008/03/11 08:53:57 katsu Exp $
 *)
functor TestCaseRunner(SessionMaker : SESSION_MAKER) : TEST_CASE_RUNNER =
struct

  (***************************************************************************)

  structure PU = PathUtility

  (***************************************************************************)

  fun getDirectory path = case PU.splitDirFile path of {dir, ...} => dir

  fun compilePrelude
          (parameter : Top.sysParam) preludePath preludeChannel = 
      let
(*      
        val (context, stamps) = Top.initialize ()
*)
        val (context, stamps) = Top.initializeContextAndStamps ()
        val preludeDir = getDirectory preludePath

        val currentSwitchTrace = !Control.switchTrace
        val currentPrintBinds = !Control.printBinds
        val _ = Control.switchTrace := false;
        val _ = Control.printBinds := false;

        val (success, newContextAndStamps) =
            Top.run
                context
                stamps
                parameter
                {
                 interactionMode = Top.Prelude,
                 initialSourceChannel = preludeChannel,
                 initialSourceName = preludePath,
                 getBaseDirectory = fn () => preludeDir
                }
            handle e =>
                   (
                    #close preludeChannel ();
                    Control.switchTrace := currentSwitchTrace;
                    Control.printBinds := currentPrintBinds;
                    raise e
                   );
        val _ = Control.switchTrace := currentSwitchTrace;
        val _ = Control.printBinds := currentPrintBinds;
      in
          newContextAndStamps
      end

  fun resumePrelude
          (parameter : Top.sysParam) preludePath preludeChannel = 
      let
        val reader =
            {
              getByte =
              fn () =>
                 case #receive preludeChannel () of
                   SOME byte => byte
                 | NONE => raise Fail "unexpected EOF of library",
              getPos = #getPos preludeChannel,
              seek = #seek preludeChannel
            }
        val _ = print "restoring static environment..."
        val contextAndStamps =
            Top.unpickle (Pickle.makeInstream reader)
            handle exn =>
                   raise Fail ("malformed compiled code:" ^ exnMessage exn)
        val _ = print "done\n"

        val session = #session parameter
        fun execute () =
            case StandAloneSession.loadExecutable preludeChannel of
              SOME executable => (#execute session executable; execute ())
            | NONE => ()
        val _ = print "restoring dynamic environment..."
        val _ = execute ()
        val _ = print "done\n"
      in
          contextAndStamps
      end

  fun runCase
      {
        preludeFileName,
        preludeChannel,
        isCompiledPrelude,
        sourceFileName,
        sourceChannel,
        resultChannel : ChannelTypes.OutputChannel
      } =
      let
val _ = print ("source = [" ^ sourceFileName ^ "]\n");
        val ignoreOutput = ref true
        fun switchFun selector channel arg =
            if !ignoreOutput then () else (selector channel) arg
        val switchOutputChannel =
            {
              send = switchFun #send resultChannel,
              sendArray = switchFun #sendArray resultChannel,
              sendVector = switchFun #sendVector resultChannel,
              getPos = if !ignoreOutput then NONE else (#getPos resultChannel),
              seek = if !ignoreOutput then NONE else (#seek resultChannel),
              print = switchFun #print resultChannel,
              flush = switchFun #flush resultChannel,
              close = switchFun #close resultChannel
            } : ChannelTypes.OutputChannel

        val session =
            SessionMaker.openSession
                {
                  STDIN = TextIOChannel.openIn{inStream = TextIO.stdIn},
                  STDOUT = switchOutputChannel,
                  STDERR = switchOutputChannel
                }
        val initializeParameter = 
            {
              session = session,
              standardOutput = resultChannel, (* no output expected. *)
              standardError =  resultChannel,
              loadPathList = ["."],
              getVariable = OS.Process.getEnv
            }
      in
        let
            val (context, stamps) =
                (if isCompiledPrelude then resumePrelude else compilePrelude)
                    initializeParameter preludeFileName preludeChannel
        in
          Control.printBinds := true;
          ignoreOutput := false;
          Top.run
              context
              stamps
              initializeParameter
              {
                interactionMode = Top.NonInteractive {stopOnError = false},
                initialSourceChannel = sourceChannel,
                initialSourceName = sourceFileName,
                getBaseDirectory = fn () => getDirectory sourceFileName
              };
          #close session ();
          ()
        end
          handle exn => (#close session (); raise exn)
      end

  (***************************************************************************)

end
