(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: InteractiveSessionFactory_General.sml,v 1.1 2007/02/23 12:36:11 kiyoshiy Exp $
 *)
structure InteractiveSessionFactory =
struct


  (***************************************************************************)

  structure BT = BasicTypes
  structure SD = SystemDef
  structure SDT = SystemDefTypes

  (***************************************************************************)

  type InitialParameter =
       {
         terminalInputChannel : ChannelTypes.InputChannel,
         terminalOutputChannel : ChannelTypes.OutputChannel,
         terminalErrorChannel : ChannelTypes.OutputChannel,
         arguments : string list
       }

  (***************************************************************************)

  val port = 12345

  fun openSession (params : InitialParameter) =
      let
        val proxy =
            NetworkRuntimeProxy.initialize
                {
                  runtimePath = !Control.runtimePath,
                  arguments = #arguments params,
                  port = port
                }
        val sessionParameter = 
            {
              terminalInputChannel = #terminalInputChannel params,
              terminalOutputChannel = #terminalOutputChannel params,
              terminalErrorChannel = #terminalErrorChannel params,
              runtimeProxy = proxy
            }
        val session = InteractiveSession.openSession sessionParameter
      in
        {
          execute = #execute session,
          close = fn () => (#close session (); #release proxy ())
        }
      end

end
