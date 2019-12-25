(**
 * common implementation of Array-like structures
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @copyright 2010, 2011, 2012, 2013, 2019, Tohoku University.
 *)

(*
This file is included by "_use" from *{Vector,Array}.sml.
Before include this file, the following must be defined:

structure Seq =
struct
  type 'a seq = ...           (* the type of the sequence *)
  type 'a elem = ...          (* the type of the element *)
  val castToArray = ...       (* cast the sequence to array *)
  val length = ...            (* length of the sequence *)
  val alloc = ...             (* allocate a seq with size check *)
  val alloc_unsafe = ...      (* allocate a seq with size check *)
  fun empty () = ...          (* empty sequence *)

  type 'a vector = ...        (* the type of the vector *)
  val castVectorToArray = ... (* cast the vector to array *)
  val allocVector_unsafe =    (* allocate a vector without size check *)
  val vectorLength = ...      (* length of the vector *)
end
*)

local
  infix 7 * / div mod
  infix 6 + - ^
  infixr 5 ::
  infix 4 = <> > >= < <=
  val op + = SMLSharp_Builtin.Int32.add_unsafe
  val op - = SMLSharp_Builtin.Int32.sub_unsafe
  val op > = SMLSharp_Builtin.Int32.lt
  val op >= = SMLSharp_Builtin.Int32.gteq
  val op < = SMLSharp_Builtin.Int32.lt
  structure Int32 = SMLSharp_Builtin.Int32
  structure Array = SMLSharp_Builtin.Array
in

structure Array_common =
struct

  val length = Seq.length
  val sub = Array.sub
  val copy = Array.copy

  fun array (len, elem : 'a Seq.elem) =
      let
        val buf = Seq.alloc len
        fun loop i =
            if i >= len then ()
            else (Array.update_unsafe (Seq.castToArray buf, i, elem);
                  loop (i + 1))
      in
        loop 0;
        buf
      end

  fun vector (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        val buf = Seq.allocVector_unsafe len
      in
        Array.copy_unsafe (Seq.castToArray seq, 0,
                           Seq.castVectorToArray buf, 0, len);
        buf
      end

  fun copyVec {src : 'a Seq.vector, dst : 'a Seq.seq, di} =
      let
        val slen = Seq.vectorLength src
        val dlen = Seq.length dst
      in
        if di >= 0 andalso dlen >= di andalso dlen - di >= slen
        then Array.copy_unsafe (Seq.castVectorToArray src, 0,
                                Seq.castToArray dst, di, slen)
        else raise Subscript
      end

  fun foldli foldFn z (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop (i, z) =
            if i >= len then z
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in loop (i + 1, foldFn (i, x, z))
                 end
      in
        loop (0, z)
      end

  fun foldl foldFn z (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop (i, z) =
            if i >= len then z
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in loop (i + 1, foldFn (x, z))
                 end
      in
        loop (0, z)
      end

  fun foldri foldFn z (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop (i, z) =
            if i < 0 then z
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in loop (i - 1, foldFn (i, x, z))
                 end
      in
        loop (len - 1, z)
      end

  fun foldr foldFn z (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop (i, z) =
            if i < 0 then z
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in loop (i - 1, foldFn (x, z))
                 end
      in
        loop (len - 1, z)
      end

  fun appi appFn (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop i =
            if i >= len then ()
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in appFn (i, x) : unit; loop (i + 1)
                 end
      in
        loop 0
      end

  fun app appFn (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop i =
            if i >= len then ()
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in appFn x : unit; loop (i + 1)
                 end
      in
        loop 0
      end

  fun mapi mapFn (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        val buf = Seq.alloc_unsafe len
        fun loop i =
            if i >= len then ()
            else
              let val x = Array.sub_unsafe (Seq.castToArray seq, i)
              in Array.update_unsafe (Seq.castToArray buf, i, mapFn (i, x));
                 loop (i + 1)
              end
      in
        loop 0;
        buf
      end

  fun map mapFn (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        val buf = Seq.alloc_unsafe len
        fun loop i =
            if i >= len then ()
            else
              let val x = Array.sub_unsafe (Seq.castToArray seq, i)
              in Array.update_unsafe (Seq.castToArray buf, i, mapFn x);
                 loop (i + 1)
              end
      in
        loop 0;
        buf
      end

  fun modifyi mapFn (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop i =
            if i >= len then ()
            else
              let val x = Array.sub_unsafe (Seq.castToArray seq, i)
              in Array.update_unsafe (Seq.castToArray seq, i, mapFn (i, x));
                 loop (i + 1)
              end
      in
        loop 0
      end

  fun modify mapFn (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop i =
            if i >= len then ()
            else
              let val x = Array.sub_unsafe (Seq.castToArray seq, i)
              in Array.update_unsafe (Seq.castToArray seq, i, mapFn x);
                 loop (i + 1)
              end
      in
        loop 0
      end

  fun findi predicate (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop i =
            if i >= len then NONE
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in if predicate (i, x) then SOME (i, x) else loop (i + 1)
                 end
      in
        loop 0
      end

  fun find predicate (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop i =
            if i >= len then NONE
            else let val x = Array.sub_unsafe (Seq.castToArray seq, i)
                 in if predicate x then SOME x else loop (i + 1)
                 end
      in
        loop 0
      end

  fun exists predicate (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop i =
            if i >= len then false
            else predicate (Array.sub_unsafe (Seq.castToArray seq, i))
                 orelse loop (i + 1)
      in
        loop 0
      end

  fun existsi predicate (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop i =
            if i >= len then false
            else predicate (i, Array.sub_unsafe (Seq.castToArray seq, i))
                 orelse loop (i + 1)
      in
        loop 0
      end

  fun all predicate (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop i =
            if i >= len then true
            else predicate (Array.sub_unsafe (Seq.castToArray seq, i))
                 andalso loop (i + 1)
      in
        loop 0
      end

  fun alli predicate (seq : 'a Seq.seq) =
      let
        val len = Seq.length seq
        fun loop i =
            if i >= len then true
            else predicate (i, Array.sub_unsafe (Seq.castToArray seq, i))
                 andalso loop (i + 1)
      in
        loop 0
      end

  fun collate cmpFn (seq1 : 'a Seq.seq, seq2 : 'a Seq.seq) =
      let
        fun loop (i, 0, 0) = General.EQUAL
          | loop (i, 0, _) = General.LESS
          | loop (i, _, 0) = General.GREATER
          | loop (i, rest1, rest2) =
            let
              val c1 = Array.sub_unsafe (Seq.castToArray seq1, i)
              val c2 = Array.sub_unsafe (Seq.castToArray seq2, i)
            in
              case cmpFn (c1, c2) of
                General.EQUAL => loop (i + 1, rest1 - 1, rest2 - 1)
              | order => order
            end
      in
        loop (0, Seq.length seq1, Seq.length seq2)
      end

  fun fromList (elems : 'a Seq.elem list) =
      let
        fun length (nil : 'a Seq.elem list, z) = z
          | length (h::t, z) = length (t, Int32.add (z, 1))
        val len = length (elems, 0) handle Overflow => raise Size
        val buf = Seq.alloc len
        fun fill (i, nil) = ()
          | fill (i, h::t) =
            (Array.update_unsafe (Seq.castToArray buf, i, h);
             fill (i + 1, t))
      in
        fill (0, elems);
        buf
      end

  fun tabulate (len, elemFn : int -> 'a Seq.elem) =
      let
        val buf = Seq.alloc len
        fun fill i =
            if i >= len then ()
            else (Array.update_unsafe (Seq.castToArray buf, i, elemFn i);
                  fill (i + 1))
      in
        fill 0;
        buf
      end

  fun update (seq : 'a Seq.seq, index, value) =
      let
        val len = Seq.length seq
      in
        if index < 0 orelse index >= len then raise Subscript else ();
        let
          val buf = Seq.alloc_unsafe len
        in
          Array.copy_unsafe (Seq.castToArray seq, 0,
                             Seq.castToArray buf, 0, len);
          Array.update_unsafe (Seq.castToArray buf, index, value);
          buf
        end
      end

  fun concat nil = Seq.empty () : 'a Seq.seq
    | concat [x : 'a Seq.seq] = x
    | concat sequences =
      let
        fun totalLength (nil : 'a Seq.seq list, z) = z
          | totalLength (h::t, z) = totalLength (t, Int32.add (Seq.length h, z))
        val len = totalLength (sequences, 0) handle Overflow => raise Size
        val buf = Seq.alloc len
        fun loop (i, nil) = ()
          | loop (i, h::t) =
            let val len = Seq.length h
            in Array.copy_unsafe (Seq.castToArray h, 0,
                                  Seq.castToArray buf, i, len);
               loop (i + len, t)
            end
      in
        loop (0, sequences);
        buf
      end

end

end (* local *)
