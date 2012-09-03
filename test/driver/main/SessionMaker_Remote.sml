(**
 * This module abstracts a session with a runtime executed in a remote process.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: SessionMaker_Remote.sml,v 1.2 2005/06/17 01:30:20 kiyoshiy Exp $
 *)
structure SessionMaker_Remote : SESSION_MAKER =
struct

  (***************************************************************************)

  fun openSession {STDIN, STDOUT, STDERR} =
      let
        val proxy = RuntimeProxyFactory.createInstance ()
        val sessionParameter = 
            {
              terminalInputChannel = STDIN,
              terminalOutputChannel = STDOUT,
              terminalErrorChannel = STDERR,
              runtimeProxy = proxy
            }

        val session = InteractiveSession.openSession sessionParameter
      in
        {
          execute = #execute session,
          close = fn arg => (#close session arg; #release proxy ())
        } : SessionTypes.Session
      end

  (***************************************************************************)

end