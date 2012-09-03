(**
 * utility functions for channels.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ChannelUtility.sml,v 1.6 2007/12/04 06:35:46 kiyoshiy Exp $
 *)
structure ChannelUtility
          : sig
              val getAll : ChannelTypes.InputChannel -> Word8Vector.vector
              val copy
                  : ChannelTypes.InputChannel
                    * ChannelTypes.OutputChannel -> unit
              val mkGetLine : (unit -> Word8.word option) -> (unit -> string)
              val mkPrint : (Word8Array.array -> unit) -> (string -> unit)
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
        let val vec = #receiveVector source CHUNK_SIZE
        in
          if 0 = Word8Vector.length vec
          then ()
          else (#sendVector destination vec; copy (source, destination))
        end

  local structure BT = BasicTypes
  in
  fun mkGetLine receive =
      let
        fun getUntilEOL characters =
            case receive () of
              NONE => List.rev characters
            | SOME byte =>
              (case Char.chr(BT.UInt8ToInt byte) of
                 #"\n" => List.rev (#"\n" :: characters)
               | char => getUntilEOL (char :: characters))
        fun getLine () = String.implode(getUntilEOL [])
      in
        getLine
      end

  fun mkPrint sendArray =
      let
        fun print string =
            let val (array, length) = BT.StringToUInt8Array string
            in sendArray array end
      in
        print
      end
  end

end;
