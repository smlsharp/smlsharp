(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: YAInteractiveSessionFactory_General.sml,v 1.1 2008/01/10 04:43:12 katsu Exp $
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
      raise Control.Bug "not implemented"

end
