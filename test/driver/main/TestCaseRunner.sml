(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: TestCaseRunner.sml,v 1.18 2006/02/02 12:59:19 kiyoshiy Exp $
 *)
functor TestCaseRunner(SessionMaker : SESSION_MAKER) : TEST_CASE_RUNNER =
struct

  (***************************************************************************)

  structure PU = PathUtility

  (***************************************************************************)

  fun getDirectory path = case PU.splitDirFile path of {dir, ...} => dir

  fun runCase
      {
        preludesFileName,
        preludesChannel,
        sourceFileName,
        sourceChannel,
        resultChannel
      } =
      let
        val ignoreOutput = ref true
        fun switchFun selector channel arg =
            if !ignoreOutput then () else (selector channel) arg
        val switchOutputChannel =
            {
              send = switchFun #send resultChannel,
              sendArray = switchFun #sendArray resultChannel,
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
      in
        let
          val context =
              Top.initialize
              {
                session = session,
                standardOutput = resultChannel, (* no output expected. *)
                standardError =  resultChannel,
                loadPathList = ["."],
                getVariable = OS.Process.getEnv
              }
        in
          Control.checkType := false;
          ignoreOutput := true;
          if
            Top.run
              context
              {
                interactionMode = Top.NonInteractive {stopOnError = true},
                initialSource = preludesChannel,
                initialSourceName = preludesFileName,
                getBaseDirectory = fn () => getDirectory preludesFileName
              }
          then ()
          else raise Fail "cannot compile prelude.";

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