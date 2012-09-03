(**
 * utility functions for channels.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ChannelUtility.sml,v 1.4 2007/02/19 14:11:55 kiyoshiy Exp $
 *)
structure ChannelUtility
          : sig
              val getAll : ChannelTypes.InputChannel -> Word8Vector.vector
              val copy
                  : ChannelTypes.InputChannel
                    * ChannelTypes.OutputChannel -> unit
            end =
struct

  val CHUNK_SIZE = 1048576
  fun getAll (source : ChannelTypes.InputChannel) =
      let
        fun untilEOF contents =
            if #isEOF source ()
            then List.rev contents
            else
              let val vector = #receiveVector source CHUNK_SIZE
              in
                if 0 = Word8Vector.length vector
                then List.rev contents
                else untilEOF (vector :: contents)
              end
      in
        Word8Vector.concat (untilEOF [])
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
