(**
 * Vector
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *
 * @author Atsushi Ohori (refactored from ArrayStructures)
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "Vector.smi"

local
  infix 7 * / div mod
  infix 6 + -
  infixr 5 ::
  infix 4 = <> > >= < <=
  val op + = SMLSharp.Int.add
  val op - = SMLSharp.Int.sub
  val op > = SMLSharp.Int.gt
  val op < = SMLSharp.Int.lt
  val op <= = SMLSharp.Int.lteq
  val op >= = SMLSharp.Int.gteq
in
structure Vector : sig
    (* same as VECTOR signature except that vector is opaque. *)
    type 'a vector = 'a vector
    val maxLen : int
    val fromList : 'a list -> 'a vector
    val tabulate : int * (int -> 'a) -> 'a vector
    val length : 'a vector -> int
    val sub : 'a vector * int -> 'a
    val foldli : (int * 'a * 'b -> 'b) -> 'b -> 'a vector -> 'b
    val foldl : ('a * 'b -> 'b) -> 'b -> 'a vector -> 'b
    val foldri : (int * 'a * 'b -> 'b) -> 'b -> 'a vector -> 'b
    val foldr : ('a * 'b -> 'b) -> 'b -> 'a vector -> 'b
    val appi : (int * 'a -> unit) -> 'a vector -> unit
    val app : ('a -> unit) -> 'a vector -> unit
    val findi : (int * 'a -> bool) -> 'a vector -> (int * 'a) option
    val find : ('a -> bool) -> 'a vector -> 'a option
    val exists : ('a -> bool) -> 'a vector -> bool
    val all : ('a -> bool) -> 'a vector -> bool
    val collate : ('a * 'a -> order) -> 'a vector * 'a vector -> order
    val update : 'a vector * int * 'a -> 'a vector
    val concat : 'a vector list -> 'a vector
    val mapi : (int * 'a -> 'b) -> 'a vector -> 'b vector
    val map : ('a -> 'b) -> 'a vector -> 'b vector
  end =
struct
    type 'a vector = 'a vector

  (* object size occupies 28 bits of 32-bit object header,
   * and the size of the maximum value is 16 bytes.
   * so we take 2^24 for maxLen. *)
  val maxLen = 0x00ffffff

  fun fromList elems =
      let
        val len = List.length elems
        val buf = SMLSharp.PrimArray.allocVector len
        fun loop (i, nil) = ()
          | loop (i, h::t) =
            (SMLSharp.PrimArray.update_vector (buf, i, h); loop (i + 1, t))
      in
        loop (0, elems);
        buf
      end

  fun tabulate (size, elemFn) =
      let
        val buf = SMLSharp.PrimArray.allocVector size
        fun loop i =
            if i >= size then ()
            else (SMLSharp.PrimArray.update_vector (buf, i, elemFn i); loop (i + 1))
      in
        loop 0;
        buf
      end

    val length = SMLSharp.PrimArray.length_vector
    val sub = SMLSharp.PrimArray.sub_vector

    fun foldli foldFn z ary =
        let
          val len = SMLSharp.PrimArray.length_vector ary
          fun loop (i, z) =
              if i >= len then z
              else let val x = SMLSharp.PrimArray.sub_vector (ary, i)
                   in loop (i + 1, foldFn (i, x, z))
                   end
        in
          loop (0, z)
        end

    fun foldl foldFn z ary =
        foldli (fn (i,x,z) => foldFn (x,z)) z ary

    fun foldri foldFn z ary =
        let
          val len = SMLSharp.PrimArray.length_vector ary
          fun loop (i, z) =
              if i < 0 then z
              else let val x = SMLSharp.PrimArray.sub_vector (ary, i)
                   in loop (i - 1, foldFn (i, x, z))
                   end
        in
          loop (len - 1, z)
        end

    fun foldr foldFn z ary =
        foldri (fn (i,x,z) => foldFn (x,z)) z ary

    fun appi appFn ary =
        foldli (fn (i,x,()) => appFn (i,x)) () ary

    fun app appFn ary =
        foldli (fn (i,x,()) => appFn x) () ary

    fun findi predicate ary =
        let
          val len = SMLSharp.PrimArray.length_vector ary
          fun loop i =
              if i >= len then NONE
              else let val x = SMLSharp.PrimArray.sub_vector (ary, i)
                   in if predicate (i, x) then SOME (i, x) else loop (i + 1)
                   end
        in
          loop 0
        end

    fun find predicate ary =
        case findi (fn (i,x) => predicate x) ary of
          SOME (i,x) => SOME x
        | NONE => NONE

    fun exists predicate ary =
        case find predicate ary of
          SOME _ => true
        | NONE => false

    fun all predicate ary =
        let
          val len = SMLSharp.PrimArray.length_vector ary
          fun loop i =
              if i >= len then true
              else predicate (SMLSharp.PrimArray.sub_vector (ary, i))
                   andalso loop (i + 1)
        in
          loop 0
        end

    fun collate cmpFn (ary1, ary2) =
        let
          val len1 = SMLSharp.PrimArray.length_vector ary1
          val len2 = SMLSharp.PrimArray.length_vector ary2
          fun loop (i, 0, 0) = EQUAL
            | loop (i, 0, _) = LESS
            | loop (i, _, 0) = GREATER
            | loop (i, rest1, rest2) =
              let
                val c1 = SMLSharp.PrimArray.sub_vector (ary1, i)
                val c2 = SMLSharp.PrimArray.sub_vector (ary2, i)
              in
                case cmpFn (c1, c2) of
                  EQUAL => loop (i + 1, rest1 - 1, rest2 - 1)
                | order => order
              end
        in
          loop (0, len1, len2)
        end


    fun update (vec, index, value) =
        let
          val len = SMLSharp.PrimArray.length_vector vec
        in
          if index < 0 orelse len <= index
          then raise Subscript
          else
            let
              val buf = SMLSharp.PrimArray.allocVector len
            in
              SMLSharp.PrimArray.copy_unsafe_vector_to_vector (vec, 0, buf, 0, len);
              SMLSharp.PrimArray.update_vector (buf, index, value);
              buf
            end
        end

    fun concat vectors =
        let
          fun totalLength (nil, z) = z
            | totalLength (h::t, z) =
              let val len = SMLSharp.PrimArray.length_vector h
                  val z = len + z
              in if z > maxLen then raise Size else totalLength (t, z)
              end
          val len = totalLength (vectors, 0)
          val buf = SMLSharp.PrimArray.allocVector len
          fun loop (i, nil) = ()
            | loop (i, h::t) =
              let val len = SMLSharp.PrimArray.length_vector h
              in SMLSharp.PrimArray.copy_unsafe_vector_to_vector (h, 0, buf, i, len);
              loop (i + len, t)
              end
        in
          loop (0, vectors);
          buf
        end

    fun mapi mapFn vec =
        let
          val len = SMLSharp.PrimArray.length_vector vec
          val buf = SMLSharp.PrimArray.allocVector len
          fun loop i =
              if i >= len then ()
              else let val x = SMLSharp.PrimArray.sub_vector (vec, i)
                   in SMLSharp.PrimArray.update_vector (buf, i, mapFn (i, x));
                      loop (i + 1)
                   end
        in
          loop 0;
          buf
        end

    fun map mapFn vec =
        mapi (fn (i,x) => mapFn x) vec
  end
end (* local *)
