(**
 * Copyright (c) 2006, Tohoku University.
 *
 * utility functions for channels.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ChannelUtility.sml,v 1.2 2006/02/18 04:59:27 ohori Exp $
 *)
structure ChannelUtility
          : sig
              val getAll : ChannelTypes.InputChannel -> Word8Array.array
              val copy
                  : ChannelTypes.InputChannel
                    * ChannelTypes.OutputChannel -> unit
            end =
struct

  fun getAll (source : ChannelTypes.InputChannel) =
      let
        fun untilEOF contents =
            if #isEOF source ()
            then List.rev contents
            else
              case #receive source () of
                NONE => List.rev contents
              | SOME byte => untilEOF (byte :: contents)
      in
        Word8Array.fromList (untilEOF [])
      end

  fun copy
          (
            source : ChannelTypes.InputChannel,
            destination : ChannelTypes.OutputChannel
          ) =
      if #isEOF source ()
      then ()
      else
        case #receive source () of
          NONE => ()
        | SOME byte => (#send destination byte; copy (source, destination))

end;
