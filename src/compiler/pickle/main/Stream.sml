(**
 * Copyright (c) 2006, Tohoku University.
 *
 * serialize library based on
 * "Type-Specialized Serialization with Sharing", Martin Elsman
 * @author YAMATODANI Kiyoshi
 * @version $Id: Stream.sml,v 1.2 2006/02/18 04:59:25 ohori Exp $
 *)
structure Stream =
struct

  (***************************************************************************)

  structure BTS = BasicTypeSerializer

  (***************************************************************************)

  type reader = unit -> Word8.word
  type writer = Word8.word -> unit
  type loc = Word32.word
  type 'k stream = 'k * loc ref

  (***************************************************************************)

  fun openStream channel = (channel, ref 0w0) : 'a stream
  fun getLoc (_, ref loc) = loc
  fun outw (word, stream as (writer, locRef) : writer stream) =
      (
        locRef := !locRef + 0w4;
(*
        print ("outw: " ^ LargeWord.toString word ^ "\n");
*)
        BTS.serializeUInt32 word writer
(*
        app
            (writer o Word8.fromLargeWord)
            [
              LargeWord.andb(word, 0wxFF),
              LargeWord.andb(LargeWord.>>(word, 0w8), 0wxFF),
              LargeWord.andb(LargeWord.>>(word, 0w16), 0wxFF),
              LargeWord.andb(LargeWord.>>(word, 0w24), 0wxFF)
            ]
*)
      )
  fun outb (byte, (writer, locRef) : writer stream) =
      (
        locRef := !locRef + 0w1;
(*
        print ("outb: " ^ Word8.toString byte ^ "\n");
*)
        writer byte
      )
  fun getw ((reader, locRef) : reader stream) =
      let
        val word = 
            BTS.deserializeUInt32 reader
(*
            List.foldr
                (fn (v, accum) =>
                    LargeWord.orb (v, LargeWord.<<(accum, 0w8)))
                0w0
                (List.tabulate
                     (
                       4,
                       fn _ => Word8.toLargeWord(reader ())
                     ))
*)
      in
(*
        print ("getw: " ^ LargeWord.toString word ^ "\n");
*)
        locRef := !locRef + 0w4;
        word
      end
  fun getb ((reader, locRef) : reader stream) =
      let
        val byte = reader ()
      in
(*
        print ("getb: " ^ Word8.toString byte ^ "\n");
*)
        locRef := !locRef + 0w1;
        byte
      end
  val outcw = outw
  val getcw = getw

  (***************************************************************************)

end
