(**
 * This module abstracts a session with a runtime.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: SESSION_MAKER.sig,v 1.1 2005/06/15 03:10:22 kiyoshiy Exp $
 *)
signature SESSION_MAKER =
sig

  (***************************************************************************)

  val openSession
      : {
          STDIN : ChannelTypes.InputChannel,
          STDOUT : ChannelTypes.OutputChannel,
          STDERR : ChannelTypes.OutputChannel
        } -> SessionTypes.Session

  (***************************************************************************)

end;
