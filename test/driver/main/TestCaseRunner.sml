(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestCaseRunner.sml,v 1.21 2007/02/19 14:11:56 kiyoshiy Exp $
 *)
functor TestCaseRunner(SessionMaker : SESSION_MAKER) : TEST_CASE_RUNNER =
struct

  (***************************************************************************)

  structure PU = PathUtility

  (***************************************************************************)

  fun getDirectory path = case PU.splitDirFile path of {dir, ...} => dir

  fun compilePrelude
          (parameter : Top.contextParameter) preludePath preludeChannel = 
      let
        val context = Top.initialize parameter

        val preludeDir = getDirectory preludePath

        val currentSwitchTrace = !Control.switchTrace
        val currentPrintBinds = !Control.printBinds
      in
        Control.switchTrace := false;
        Control.printBinds := false;
        Top.run
            context
            {
              interactionMode = Top.Prelude,
              initialSource = preludeChannel,
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

        Control.switchTrace := currentSwitchTrace;
        Control.printBinds := currentPrintBinds;

        context
      end

  fun resumePrelude
          (parameter : Top.contextParameter) preludePath preludeChannel = 
      let
        fun reader () =
            case #receive preludeChannel () of
              SOME byte => byte
            | NONE => raise Fail "unexpected EOF of library"
        val _ = print "restoring static environment..."
        val context =
            Top.unpickle parameter (Pickle.makeInstream reader)
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
        context
      end

  fun runCase
      {
        preludeFileName,
        preludeChannel,
        isCompiledPrelude,
        sourceFileName,
        sourceChannel,
        resultChannel
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
          val context =
              (if isCompiledPrelude then resumePrelude else compilePrelude)
                  initializeParameter preludeFileName preludeChannel
        in
          Control.printBinds := true;
          ignoreOutput := false;
          Top.run
              context
              {
                interactionMode = Top.NonInteractive {stopOnError = false},
                initialSource = sourceChannel,
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