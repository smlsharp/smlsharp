(**
 * a wrapper module which translates between string I/O and binary I/O.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CharacterStreamWrapper.sml,v 1.5 2007/02/19 14:11:55 kiyoshiy Exp $
 *)
structure CharacterStreamWrapper :
sig

  (***************************************************************************)

  (** string input operation on a channel *)
  type InputStream =
       {
         (** read input from the channel until encounter a newline. *)
         getLine : unit -> string
       }

  (** string output operation on a channel *)
  type OutputStream =
       {
         (** output a string to the channel. *)
         print : string -> unit
       }

  (***************************************************************************)

  (** wrap an input channel. *)
  val wrapIn : ChannelTypes.InputChannel -> InputStream

  (** wrap an output channel. *)
  val wrapOut : ChannelTypes.OutputChannel -> OutputStream

  (***************************************************************************)

end =
struct

  (***************************************************************************)

  type InputStream = {getLine : unit -> string}

  type OutputStream = {print : string -> unit}

  (***************************************************************************)

  local structure BT = BasicTypes
  in
  fun wrapIn (inputChannel : ChannelTypes.InputChannel) =
      let
        fun getUntilEOL characters =
            case #receive inputChannel () of
              NONE => List.rev characters
            | SOME byte =>
              (case Char.chr(BT.UInt8ToInt byte) of
                 #"\n" => List.rev (#"\n" :: characters)
               | char => getUntilEOL (char :: characters))
        fun getLine () = String.implode(getUntilEOL [])
      in
        {getLine = getLine} : InputStream
      end

  fun wrapOut (outputChannel : ChannelTypes.OutputChannel) =
      let
        fun print string =
            let val (array, length) = BT.StringToUInt8Array string
            in #sendArray outputChannel array end
      in
        {print = print} : OutputStream
      end
  end

  (***************************************************************************)

end
