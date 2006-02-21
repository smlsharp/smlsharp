(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: TEST_CASE_RUNNER.sig,v 1.1 2005/03/24 14:58:35 kiyoshiy Exp $
 *)
signature TEST_CASE_RUNNER =
sig

  (***************************************************************************)

  val runCase
      : {
          preludesFileName : string,
          preludesChannel : ChannelTypes.InputChannel,
          sourceFileName : string,
          sourceChannel : ChannelTypes.InputChannel,
          resultChannel : ChannelTypes.OutputChannel
        } -> unit

  (***************************************************************************)

end
