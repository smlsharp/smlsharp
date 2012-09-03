(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: YAInteractiveSessionFactory_Unix.sml,v 1.1 2008/01/10 04:43:12 katsu Exp $
 *)
structure YAInteractiveSessionFactory =
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

  fun openSession (params : InitialParameter) =
      let
        val proxy =
            YAUnixProcessRuntimeProxy.initialize
                {
                  runtimePath = !Control.runtimePath,
                  arguments = #arguments params
                }
        val sessionParameter = 
            {
              terminalInputChannel = #terminalInputChannel params,
              terminalOutputChannel = #terminalOutputChannel params,
              terminalErrorChannel = #terminalErrorChannel params,
              runtimeProxy = proxy
            }
        val session = YAInteractiveSession.openSession sessionParameter
      in
        {
          execute = #execute session,
          close = fn () => (#close session (); #release proxy ())
        }
      end

end
