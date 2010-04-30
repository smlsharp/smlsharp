(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: TEST_CASE_RUNNER.sig,v 1.2 2007/01/26 09:33:15 kiyoshiy Exp $
 *)
signature TEST_CASE_RUNNER =
sig

  (***************************************************************************)

  val runCase
      : {
          preludeFileName : string,
          preludeChannel : ChannelTypes.InputChannel,
          isCompiledPrelude : bool,
          sourceFileName : string,
          sourceChannel : ChannelTypes.InputChannel,
          resultChannel : ChannelTypes.OutputChannel
        } -> unit

  (***************************************************************************)

end
