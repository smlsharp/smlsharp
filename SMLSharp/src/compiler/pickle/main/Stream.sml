(**
 * serialize library based on
 * "Type-Specialized Serialization with Sharing", Martin Elsman
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Stream.sml,v 1.8 2007/09/12 01:56:46 kiyoshiy Exp $
 *)
structure Stream =
struct

  (***************************************************************************)

  (** word is pickled in portable format. *)
  structure BTS = BasicTypeSerializerForNetworkByteOrder

  (***************************************************************************)
(*
  type pos = ChannelTypes.pos
*)
  type pos = Word32.word
  type loc = Word32.word

  type reader =
       {
         getByte : unit -> Word8.word,
         getPos : (unit -> pos) option,
         seek : (pos * int -> unit) option
       }
  type writer =
       {
         putByte : Word8.word -> unit, 
         getPos : (unit -> pos) option,
         seek : (pos * int -> unit) option
       }
  type 'k stream = 'k * loc ref * pos option

  (***************************************************************************)

  fun openInStream (channel : reader) =
      let val pos = case #getPos channel of NONE => NONE | SOME f => SOME (f())
      in (channel, ref 0w0, pos) : reader stream
      end
  fun openOutStream (channel : writer) =
      let val pos = case #getPos channel of NONE => NONE | SOME f => SOME (f())
      in (channel, ref 0w0, pos) : writer stream
      end
  fun getLoc (_, ref loc, _) = loc
  fun outw (word, stream as (writer, locRef, _) : writer stream) =
      (
        locRef := !locRef + 0w4;
(*
        print ("outw: " ^ LargeWord.toString word ^ "\n");
*)
        BTS.serializeUInt32 word (#putByte writer)
      )
  fun outb (byte, (writer, locRef, _) : writer stream) =
      (
        locRef := !locRef + 0w1;
(*
        print ("outb: " ^ Word8.toString byte ^ "\n");
*)
        #putByte writer byte
      )
  fun getw ((reader, locRef, _) : reader stream) =
      let
        val word = BTS.deserializeUInt32 (#getByte reader)
      in
(*
        print ("getw: " ^ LargeWord.toString word ^ "\n");
*)
        locRef := !locRef + 0w4;
        word
      end
  fun getb ((reader, locRef, _) : reader stream) =
      let
        val byte = #getByte reader ()
      in
(*
        print ("getb: " ^ Word8.toString byte ^ "\n");
*)
        locRef := !locRef + 0w1;
        byte
      end
  fun seekIn ((reader, locRef, start) : reader stream, offset) =
      case (#seek reader, start)
       of (NONE, _) => false
        | (SOME f, SOME pos) =>
          (
(*
print ("seekRelativeIn:locRef=" ^ Word32.toString (!locRef) ^
       ",pos=" ^ Word32.toString pos ^
       ",offset=" ^ Int.toString offset ^
       "\n");
*)
            locRef := offset;
            f (pos, Word32.toIntX (!locRef));
            true
          )
        | (SOME _, NONE) => false (* ToDo : error ? *)
  fun seekOut ((writer, locRef, start) : writer stream, offset) =
      case (#seek writer, start)
       of (NONE, _) => false
        | (SOME f, SOME pos) =>
          (
            locRef := offset;
            f (pos, Word32.toIntX (!locRef));
            true
          )
        | (SOME _, NONE) => false (* ToDo : error ? *)

  (***************************************************************************)

end
