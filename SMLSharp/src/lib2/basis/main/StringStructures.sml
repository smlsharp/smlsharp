(**
 * String related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)
_interface "StringStructures.smi"

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

infix 6 ++ --
val op ++ = SMLSharp.Word.add
val op -- = SMLSharp.Word.sub
fun toWord c = SMLSharp.Word.fromInt (SMLSharp.Char.ord c)

structure StringStructures :> sig

  structure CharVector : MONO_VECTOR
    where type vector = string
    where type elem = char
  structure CharArray : MONO_ARRAY
    where type vector = CharVector.vector
   where type elem = char
  structure CharVectorSlice : MONO_VECTOR_SLICE
    where type vector = string
    where type elem = char
  structure CharArraySlice : MONO_ARRAY_SLICE
    where type vector = CharVector.vector
    where type vector_slice = CharVectorSlice.slice
    where type array = CharArray.array
    where type elem = char
  structure String : STRING
    where type string = string
    where type char = char
  structure Substring : SUBSTRING
    where type substring = CharVectorSlice.slice
    where type string = string
    where type char = char
  structure Word8Vector : MONO_VECTOR
    where type elem = SMLSharp.Word8.word
  structure Word8Array : MONO_ARRAY
    where type vector = Word8Vector.vector
    where type elem = SMLSharp.Word8.word
  structure Word8VectorSlice : MONO_VECTOR_SLICE
    where type vector = Word8Vector.vector
    where type elem = SMLSharp.Word8.word
  structure Word8ArraySlice : MONO_ARRAY_SLICE
    where type vector = Word8Vector.vector
    where type vector_slice = Word8VectorSlice.slice
    where type array = Word8Array.array
    where type elem = SMLSharp.Word8.word
  structure Byte : sig
    (* same as BYTE *)
    val byteToChar : SMLSharp.Word8.word -> char
    val charToByte : char -> SMLSharp.Word8.word
    val bytesToString : Word8Vector.vector -> string
    val stringToBytes : string -> Word8Vector.vector
    val unpackStringVec : Word8VectorSlice.slice -> string
    val unpackString : Word8ArraySlice.slice -> string
    val packString : Word8Array.array * int * Substring.substring -> unit
  end

end
=
struct

  structure ArrayBase =
  struct

    type array = string
    type vector = string
    type elem = char

    (* object size occupies 28 bits of 32-bit object header. *)
    val maxLen = 0x0fffffff

    (* monomorphic version for efficiency *)
    fun List_length l =
        let
          fun loop (nil : char list, z) = z
            | loop (h::t, z) = loop (t, z + 1)
        in
          loop (l, 0)
        end

    (* for Array.array *)
    fun fill (buf, len, elem) =
        let
          fun loop i =
              if i >= len then ()
              else (SMLSharp.PrimString.update_unsafe (buf, i, elem);
                    loop (i + 1))
        in
          loop 0;
          buf
        end

    (* for fromList *)
    fun fillWithList (buf, elems) =
        let
          fun loop (i, nil) = ()
            | loop (i, h::t) =
              (SMLSharp.PrimString.update_unsafe (buf, i, h); loop (i + 1, t))
        in
          loop (0, elems);
          buf
        end

    (* for tabulate *)
    fun fillWithFn (buf, len, elemFn) =
        let
          fun loop i =
              if i >= len then ()
              else (SMLSharp.PrimString.update_unsafe (buf, i, elemFn i);
                    loop (i + 1))
        in
          loop 0;
          buf
        end

    val length = SMLSharp.PrimString.size

    fun sub (ary, index) =
        if index < 0 orelse SMLSharp.PrimString.size ary <= index
        then raise Subscript
        else SMLSharp.PrimString.sub_unsafe (ary, index)

    fun foldli foldFn z ary =
        let
          val len = SMLSharp.PrimString.size ary
          fun loop (i, z) =
              if i >= len then z
              else let val x = SMLSharp.PrimString.sub_unsafe (ary, i)
                   in loop (i + 1, foldFn (i, x, z))
                   end
        in
          loop (0, z)
        end

    fun foldl foldFn z ary =
        foldli (fn (i,x,z) => foldFn (x,z)) z ary

    fun appi appFn ary =
        foldli (fn (i,x,()) => appFn (i,x)) () ary

    fun app appFn ary =
        foldli (fn (i,x,()) => appFn x) () ary

    fun foldri foldFn z ary =
        let
          val len = SMLSharp.PrimString.size ary
          fun loop (i, z) =
              if i < 0 then z
              else let val x = SMLSharp.PrimString.sub_unsafe (ary, i)
                   in loop (i - 1, foldFn (i, x, z))
                   end
        in
          loop (len - 1, z)
        end

    fun foldr foldFn z ary =
        foldri (fn (i,x,z) => foldFn (x,z)) z ary

    fun findi predicate ary =
        let
          val len = SMLSharp.PrimString.size ary
          fun loop i =
              if i >= len then NONE
              else let val x = SMLSharp.PrimString.sub_unsafe (ary, i)
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
          val len = SMLSharp.PrimString.size ary
          fun loop i =
              if i >= len then true
              else predicate (SMLSharp.PrimString.sub_unsafe (ary, i))
                   andalso loop (i + 1)
        in
          loop 0
        end

    fun collate cmpFn (ary1, ary2) =
        let
          val len1 = SMLSharp.PrimString.size ary1
          val len2 = SMLSharp.PrimString.size ary2
          fun loop (i, 0, 0) = EQUAL
            | loop (i, 0, _) = LESS
            | loop (i, _, 0) = GREATER
            | loop (i, rest1, rest2) =
              let
                val c1 = SMLSharp.PrimString.sub_unsafe (ary1, i)
                val c2 = SMLSharp.PrimString.sub_unsafe (ary2, i)
              in
                case cmpFn (c1, c2) of
                  EQUAL => loop (i + 1, rest1 - 1, rest2 - 1)
                | order => order
              end
        in
          loop (0, len1, len2)
        end

  end (* ArrayBase *)

  structure CharVector =
  struct
    open ArrayBase

    fun fromList elems =
        let
          val len = List_length elems
          val buf = SMLSharp.PrimString.allocVector len
        in
          fillWithList (buf, elems)
        end

    fun tabulate (size, elemFn) =
        let
          val buf = SMLSharp.PrimString.allocVector size
        in
          fillWithFn (buf, size, elemFn)
        end

    fun update (vec, index, value) =
        let
          val len = SMLSharp.PrimString.size vec
        in
          if index < 0 orelse len <= index
          then raise Subscript
          else
            let
              val buf = SMLSharp.PrimString.allocVector len
            in
              SMLSharp.PrimString.copy_unsafe (vec, 0, buf, 0, len);
              SMLSharp.PrimString.update_unsafe (buf, index, value);
              buf
            end
        end

    fun concat vectors =
        let
          fun totalLength (nil, z) = z
            | totalLength (h::t, z) =
              let val len = SMLSharp.PrimString.size h
                  val z = len + z
              in if z > maxLen then raise Size else totalLength (t, z)
              end
          val len = totalLength (vectors, 0)
          val buf = SMLSharp.PrimString.allocVector len
          fun loop (i, nil) = ()
            | loop (i, h::t) =
              let val len = SMLSharp.PrimString.size h
              in SMLSharp.PrimString.copy_unsafe (h, 0, buf, i, len);
              loop (i + len, t)
              end
        in
          loop (0, vectors);
          buf
        end

    fun mapi mapFn vec =
        let
          val len = SMLSharp.PrimString.size vec
          val buf = SMLSharp.PrimString.allocVector len
          fun loop i =
              if i >= len then ()
              else
                let val x = SMLSharp.PrimString.sub_unsafe (vec, i)
                in SMLSharp.PrimString.update_unsafe (buf, i, mapFn (i, x));
                loop (i + 1)
                end
        in
          loop 0;
          buf
        end

    fun map mapFn vec =
        mapi (fn (i,x) => mapFn x) vec

  end (* CharVector *)

  structure CharArray =
  struct
    open ArrayBase

    fun array (len, elem) =
        let
          val buf = SMLSharp.PrimString.allocArray len
        in
          fill (buf, len, elem)
        end

    fun fromList elems =
        let
          val len = List_length elems
          val buf = SMLSharp.PrimString.allocArray len
        in
          fillWithList (buf, elems)
        end

    fun tabulate (len, elemFn) =
        let
          val buf = SMLSharp.PrimString.allocArray len
        in
          fillWithFn (buf, len, elemFn)
        end

    fun update (ary, index, elem) =
        if index < 0 orelse SMLSharp.PrimString.size ary <= index
        then raise Subscript
        else SMLSharp.PrimString.update_unsafe (ary, index, elem)

    fun vector ary =
        let
          val len = SMLSharp.PrimString.size ary
          val buf = SMLSharp.PrimString.allocVector len
        in
          SMLSharp.PrimString.copy_unsafe (ary, 0, buf, 0, len);
          buf
        end

    fun copy {src, dst, di} =
        let
          val srclen = SMLSharp.PrimString.size src
          val dstlen = SMLSharp.PrimString.size dst
        in
          if di < 0 orelse dstlen < di orelse dstlen - di < srclen
          then raise Subscript
          else SMLSharp.PrimString.copy_unsafe (src, 0, dst, di, srclen)
        end

    val copyVec = copy

    fun modifyi mapFn ary =
        let
          val len = SMLSharp.PrimString.size ary
          fun loop i =
              if i >= len then ()
              else let val x = SMLSharp.PrimString.sub_unsafe (ary, i)
                   in SMLSharp.PrimString.update_unsafe (ary, i, mapFn (i, x));
                      loop (i + 1)
                   end
        in
          loop 0
        end

    fun modify mapFn ary =
        modifyi (fn (i,x) => mapFn x) ary

  end (* CharArray *)

  structure ArraySliceBase =
  struct

    type slice = string * int * int  (* array * start * length *)

    type array = string
    type vector = string
    type vector_slice = slice
    type elem = char

    fun length ((ary, start, length):slice) = length

    fun sub ((ary, start, length):slice, index) =
        if index < 0 orelse length <= index then raise Subscript
        else SMLSharp.PrimString.sub_unsafe (ary, start + index)

    fun full ary =
        (ary, 0, SMLSharp.PrimString.size ary) : slice

    fun slice (ary, start, lengthOpt) =
        let
          val length = SMLSharp.PrimString.size ary
          val _ = if start < 0 orelse length < start
                  then raise Subscript else ()
          val length =
              case lengthOpt of
                NONE => length - start
              | SOME len =>
                if len < 0 orelse length - start < len then raise Subscript
                else len
        in
          (ary, start, length) : slice
        end

    fun subslice ((ary, start, length):slice, start2, lengthOpt) =
        let
          val _ = if start2 < 0 orelse length < start2
                  then raise Subscript else ()
          val length =
              case lengthOpt of
                NONE => length - start2
              | SOME len =>
                if len < 0 orelse length - start2 < len then raise Subscript
                else len
        in
          (ary, start + start2, length) : slice
        end

    fun base (x:slice) = x

    fun vector ((ary, start, length):slice) =
        let
          val buf = SMLSharp.PrimString.allocVector length
        in
          SMLSharp.PrimString.copy_unsafe (ary, start, buf, 0, length);
          buf
        end

    fun isEmpty ((ary, start, length):slice) = length = 0

    fun getItem ((ary, start, length):slice) =
        if length <= 0 then NONE
        else SOME (SMLSharp.PrimString.sub_unsafe (ary, start),
                   (ary, start + 1, length - 1) : slice)

    fun foldli foldFn z ((ary, start, length):slice) =
        let
          val max = start + length
          fun loop (i, z) =
              if i >= max then z
              else let val x = SMLSharp.PrimString.sub_unsafe (ary, i)
                   in loop (i + 1, foldFn (i - start, x, z))
                   end
        in
          loop (start, z)
        end

    fun foldl foldFn z slice =
        foldli (fn (i,x,z) => foldFn (x,z)) z slice

    fun appi appFn slice =
        foldli (fn (i,x,()) => appFn (i,x)) () slice

    fun app appFn slice =
        foldli (fn (i,x,()) => appFn x) () slice

    fun foldri foldFn z ((ary, start, length):slice) =
        let
          fun loop (i, z) =
              if i < start then z
              else let val x = SMLSharp.PrimString.sub_unsafe (ary, i)
                   in loop (i - 1, foldFn (i - start, x, z))
                   end
        in
          loop (start + length - 1, z)
        end

    fun foldr foldFn z slice =
        foldri (fn (i,x,z) => foldFn (x,z)) z slice

    fun findi predicate ((ary, start, length):slice) =
        let
          val max = start + length
          fun loop i =
              if i >= max then NONE
              else let val x = SMLSharp.PrimString.sub_unsafe (ary, i)
                   in if predicate (i - start, x)
                      then SOME (i, x) else loop (i + 1)
                   end
        in
          loop start
        end

    fun find predicate slice =
        case findi (fn (i,x) => predicate x) slice of
          NONE => NONE
        | SOME (i,x) => SOME x

    fun exists predicate ary =
        case find predicate ary of
          SOME _ => true
        | NONE => false

    fun all predicate ((ary, start, length):slice) =
        let
          val max = start + length
          fun loop i =
              if i >= max then true
              else predicate (SMLSharp.PrimString.sub_unsafe (ary, i))
                   andalso loop (i + 1)
        in
          loop start
        end

    fun collate cmpFn ((ary1, start1, length1):slice,
                       (ary2, start2, length2):slice) =
        let
          fun loop (i, 0, j, 0) = EQUAL
            | loop (i, 0, j, _) = LESS
            | loop (i, _, j, 0) = GREATER
            | loop (i, rest1, j, rest2) =
              let
                val c1 = SMLSharp.PrimString.sub_unsafe (ary1, i)
                val c2 = SMLSharp.PrimString.sub_unsafe (ary2, j)
              in
                case cmpFn (c1, c2) of
                  EQUAL => loop (i + 1, rest1 - 1, j + 1, rest2 - 1)
                | order => order
              end
        in
          loop (start1, length1, start2, length2)
        end

  end (* ArraySliceBase *)

  structure CharVectorSlice =
  struct
    open ArraySliceBase

    fun concat slices =
        let
          fun totalLength (nil, z) = z
            | totalLength (((vec, start, length):slice)::t, z) =
              let val z = length + z
              in if z > CharVector.maxLen then raise Size
                 else totalLength (t, z)
              end
          val len = totalLength (slices, 0)
          val buf = SMLSharp.PrimString.allocVector len
          fun loop (i, nil) = ()
            | loop (i, (vec, start, len)::t) =
              (SMLSharp.PrimString.copy_unsafe (vec, start, buf, i, len);
               loop (i + len, t))
        in
            loop (0, slices);
            buf
          end

    fun mapi mapFn ((vec, start, length):slice) =
          let
            val buf = SMLSharp.PrimString.allocVector length
            val max = start + length
            fun loop i =
                if i >= max then ()
                else
                  let val x = SMLSharp.PrimString.sub_unsafe (vec, i)
                      val x = mapFn (i - start, x)
                  in SMLSharp.PrimString.update_unsafe (buf, i, x);
                     loop (i + 1)
                  end
          in
            loop start;
            buf
          end

    fun map mapFn slice =
        mapi (fn (i,x) => mapFn x) slice

  end (* CharVectorSlice *)

  structure CharArraySlice =
  struct
    open ArraySliceBase

    fun update ((ary, start, length):slice, index, elem) =
        if index < 0 orelse length <= index
        then raise Subscript
        else SMLSharp.PrimString.update_unsafe (ary, start + index, elem)

    fun copy {src = (srcary, srcstart, srclen):slice, dst, di} =
        let
          val dstlen = SMLSharp.PrimString.size dst
        in
          if di < 0 orelse dstlen < di orelse dstlen - di < srclen
          then raise Subscript
          else SMLSharp.PrimString.copy_unsafe
                 (srcary, srcstart, dst, di, srclen)
        end

    val copyVec = copy

    fun modifyi mapFn ((ary, start, length):slice) =
        let
          val max = start + length
          fun loop i =
              if i >= max then ()
              else
                let val x = SMLSharp.PrimString.sub_unsafe (ary, i)
                    val x = mapFn (i - start, x)
                in SMLSharp.PrimString.update_unsafe (ary, i, x);
                   loop (i + 1)
                end
        in
          loop start
        end

    fun modify mapFn slice =
        modifyi (fn (i,x) => mapFn x) slice

  end (* CharArraySlice *)

  structure StringBase =
  struct

    fun explode (str, beg, len) =
        let
          fun loop (i, z) =
              if i < beg then z
              else loop (i - 1, SMLSharp.PrimString.sub_unsafe (str, i) :: z)
        in
          loop (beg + len - 1, nil)
        end

    fun substring_unsafe (str, beg, len) =
        let
          val buf = SMLSharp.PrimString.allocVector len
          val _ = SMLSharp.PrimString.copy_unsafe (str, beg, buf, 0, len)
        in
          buf
        end

    fun concatWith sep [] = ""
      | concatWith sep [x] = substring_unsafe x
      | concatWith sep slices =
        let
          val sepLen = SMLSharp.PrimString.size sep
          fun totalLength (nil, z) = z
            | totalLength ([(_,_,len)], z) = z + len
            | totalLength ((_,_,len)::t, z) =
              let val z = z + len + sepLen
              in if z > CharVector.maxLen then raise Size
                 else totalLength (t, z)
              end
          val len = totalLength (slices, 0)
          val buf = SMLSharp.PrimString.allocVector len
          fun loop (i, nil) = ()
            | loop (i, (str, beg, len)::t) =
              (SMLSharp.PrimString.copy_unsafe (str, beg, buf, i, len);
               case t of
                 nil => ()
               | _::_ =>
                 let val i = i + len
                 in SMLSharp.PrimString.copy_unsafe (sep, 0, buf, i, sepLen);
                 loop (i + sepLen, t)
                 end)
        in
          loop (0, slices);
          buf
        end

    local
      fun equal (s1, i, s2, j, len) =
          if len <= 0 then true
          else SMLSharp.PrimString.sub_unsafe (s1, i)
               = SMLSharp.PrimString.sub_unsafe (s2, j)
               andalso equal (s1, i+1, s2, j+1, len-1)
    in

    fun isPrefix prefix (str, beg, len) =
        let
          val prefixLen = SMLSharp.PrimString.size prefix
        in
          prefixLen <= len andalso equal (prefix, 0, str, beg, prefixLen)
        end

    fun isSuffix suffix (str, beg, len) =
        let
          val suffixLen = SMLSharp.PrimString.size suffix
        in
          suffixLen <= len
          andalso equal (suffix, 0, str, len - suffixLen, suffixLen)
        end

    fun substringIndex str1 (str2, beg, len2) =
        let
          val len1 = SMLSharp.PrimString.size str1
        in
          if len1 > len2 then NONE else
          let
            (* Rabin-Karp algorithm with a native hashing *)
            val max = len2 - len1
            fun loop1 (i, hash1, hash2, eq) =
                if i < len1 then
                  let
                    val c1 = toWord (SMLSharp.PrimString.sub_unsafe (str1, i))
                    val c2 = toWord (SMLSharp.PrimString.sub_unsafe (str2, i))
                  in
                    loop1 (i+1, hash1 ++ c1, hash2 ++ c2, eq andalso c1 = c2)
                  end
                else if eq then SOME beg
                else loop2 (beg, hash1, hash2)
            and loop2 (i, hash1, hash2) =
                if i >= max then NONE else
                let
                  val cl = SMLSharp.PrimString.sub_unsafe (str2, i)
                  val cr = SMLSharp.PrimString.sub_unsafe (str2, i + len1)
                  val hash2 = hash2 -- toWord cl ++ toWord cr
                  val i = i + 1
                in
                  if hash1 = hash2 andalso equal (str1, 0, str2, i, len1)
                  then SOME i else loop2 (i, hash1, hash2)
                end
          in
            loop1 (beg, 0w0, 0w0, true)
          end
        end

    fun isSubstring str1 slice =
        case substringIndex str1 slice of
          NONE => false
        | SOME _ => true

    end (* local *)

    fun translate transFn (str, beg, len) =
        let
          (* use array instead of list for efficiency *)
          val buf = SMLSharp.PrimArray.allocArray len
          fun loop (i, size) =
              if i < len then
                let
                  val x = SMLSharp.PrimString.sub_unsafe (str, beg + i)
                  val x = transFn x
                  val n = SMLSharp.PrimString.size x
                in
                  if size + n > CharVector.maxLen then raise Size else ();
                  SMLSharp.PrimArray.update (buf, i, x);
                  loop (i + 1, size + n)
                end
              else loop2 (0, 0, SMLSharp.PrimString.allocVector size)
          and loop2 (i, j, dst) =
              if i < len then
                let
                  val x = SMLSharp.PrimArray.sub (buf, i)
                  val n = SMLSharp.PrimString.size x
                in
                  SMLSharp.PrimString.copy_unsafe (x, 0, dst, j, n);
                  loop2 (i + 1, j + n, dst)
                end
              else dst
        in
          loop (0, 0)
        end

  end (* StringBase *)

  structure String =
  struct
    open CharVector

    type string = string
    type char = char

    val maxSize = maxLen
    val size = SMLSharp.PrimString.size
    fun extract x = CharVectorSlice.vector (CharVectorSlice.slice x)
    fun substring (str, start, len) = extract (str, start, SOME len)

    fun op ^ (str1, str2) =
        let
          val len1 = SMLSharp.PrimString.size str1
          val len2 = SMLSharp.PrimString.size str2
          val buf = SMLSharp.PrimString.allocVector (len1 + len2)
        in
          SMLSharp.PrimString.copy_unsafe (str1, 0, buf, 0, len1);
          SMLSharp.PrimString.copy_unsafe (str2, 0, buf, len1, len2);
          buf
        end

    fun concatWith sep nil = ""
      | concatWith sep [x] = x
      | concatWith sep strings =
        StringBase.concatWith
          sep
          (List.map (fn str => (str, 0, SMLSharp.PrimString.size str)) strings)

    fun str c =
        let
          val buf = SMLSharp.PrimString.allocVector 1
        in
          SMLSharp.PrimString.update_unsafe (buf, 0, c);
          buf
        end

    val implode = fromList

    fun explode str =
        StringBase.explode (str, 0, SMLSharp.PrimString.size str)

    fun translate transFn str =
        StringBase.translate transFn (str, 0, SMLSharp.PrimString.size str)

    fun tokens isDelimiter str =
        let
          val len = SMLSharp.PrimString.size str
          fun add (b, e, z) =
              if b = e then z
              else StringBase.substring_unsafe (str, b, e - b) :: z
          fun loop (beg, i, z) =
              if i >= len then rev (add (beg, i, z))
              else if isDelimiter (SMLSharp.PrimString.sub_unsafe (str, i))
              then loop (i + 1, i + 1, add (beg, i, z))
              else loop (beg, i + 1, z)
        in
          loop (0, 0, nil)
        end

    fun fields isDelimiter str =
        let
          val len = SMLSharp.PrimString.size str
          fun add (b, e, z) = StringBase.substring_unsafe (str, b, e - b) :: z
          fun loop (beg, i, z) =
              if i >= len then rev (add (beg, i, z))
              else if isDelimiter (SMLSharp.PrimString.sub_unsafe (str, i))
              then loop (i + 1, i + 1, add (beg, i, z))
              else loop (beg, i + 1, z)
        in
          loop (0, 0, nil)
        end

    fun isPrefix prefix str =
        StringBase.isPrefix prefix (str, 0, SMLSharp.PrimString.size str)

    fun isSuffix suffix str =
        StringBase.isSuffix suffix (str, 0, SMLSharp.PrimString.size str)

    fun isSubstring str1 str2 =
        StringBase.isSubstring str1 (str2, 0, SMLSharp.PrimString.size str2)

    val strcmp = _import "strcmp" : (string, string) -> int

    fun compare (x, y) =
        if SMLSharp.identityEqual (SMLSharp.PrimString.toBoxed x,
                                   SMLSharp.PrimString.toBoxed y)
        then EQUAL
        else case strcmp (x, y) of
               0 => EQUAL
             | n => if n < 0 then LESS else GREATER

    val collate = CharVector.collate

    fun op < (x, y) = SMLSharp.Int.lt (strcmp (x, y), 0)
    fun op <= (x, y) = SMLSharp.Int.lteq (strcmp (x, y), 0)
    fun op > (x, y) = SMLSharp.Int.gt (strcmp (x, y), 0)
    fun op >= (x, y) = SMLSharp.Int.gteq (strcmp (x, y), 0)

    fun toString s =
        translate Char.toString s
    fun toCString s =
        translate Char.toCString s

    fun scan getc strm =
        let
          val (zero, strm) =
              case SMLSharpScanChar.scanEscapeSpaces getc strm of
                NONE => (false, strm)
              | SOME (_, strm) => (true, strm)
        in
          case SMLSharpScanChar.scanRepeat1 SMLSharpScanChar.scanChar
                                            getc strm of
            NONE => if zero then SOME ("", strm) else NONE
          | SOME (chars, strm) => SOME (implode chars, strm)
        end

    fun fromString s =
        StringCvt.scanString scan s

    fun fromCString s =
        let
          fun scan getc strm =
              case SMLSharpScanChar.scanRepeat1 SMLSharpScanChar.scanCChar
                                                getc strm of
                NONE => NONE
              | SOME (chars, strm) => SOME (implode chars, strm)
        in
          StringCvt.scanString scan s
        end

  end (* String *)

  structure Substring =
  struct
    open CharVectorSlice

    type substring = CharVectorSlice.slice
    type char = char
    type string = string

    val size = length
    val extract = slice
    fun substring (str, start, len) = extract (str, start, SOME len)
    val string = vector
    val getc = getItem

    fun first ((str, start, length):slice) =
        if length = 0 then NONE
        else SOME (SMLSharp.PrimString.sub_unsafe (str, start))

    fun triml size =
        if size < 0 then raise Subscript
        else fn (str, start, length):slice =>
                if size < length
                then (str, start + size, length - size) : slice
                else (str, start + length, 0) : slice

    fun trimr size =
        if size < 0 then raise Subscript
        else fn (str, start, length):slice =>
                (str, start, if size < length then length - size else 0) : slice

    val slice = subslice

    val concatWith = StringBase.concatWith
    val explode = StringBase.explode
    val isPrefix = StringBase.isPrefix
    val isSubstring = StringBase.isSubstring
    val isSuffix = StringBase.isSuffix

    fun compare x =
        collate Char.compare x

    fun splitl whileFn ((str, start, len):slice) =
        let
          fun loop i =
              if i < len
                 andalso whileFn (SMLSharp.PrimString.sub_unsafe
                                    (str, start + i))
              then loop (i + 1)
              else ((str, start, i) : slice, (str, start + i, len - i) : slice)
        in
          loop 0
        end

    fun splitr whileFn ((str, start, len):slice) =
        let
          fun loop i =
              if i > 0
                 andalso whileFn (SMLSharp.PrimString.sub_unsafe
                                    (str, start + i - 1))
              then loop (i - 1)
              else ((str, start, i) : slice, (str, start + i, i) : slice)
        in
          loop len
        end

    fun splitAt ((str, start, length):slice, index) =
        if index < 0 orelse length < index then raise Subscript
        else ((str, start, index) : slice, (str, index, length - index) : slice)

    fun dropl whileFn ((str, start, length):slice) =
        let
          fun loop (start, length) =
              if length > 0
                 andalso whileFn (SMLSharp.PrimString.sub_unsafe (str, start))
              then loop (start + 1, length - 1)
              else (str, start, length) : slice
        in
          loop (start, length)
        end

    fun dropr whileFn ((str, start, length):slice) =
        let
          fun loop length =
              if length > 0
                 andalso whileFn (SMLSharp.PrimString.sub_unsafe
                                    (str, start + length - 1))
              then loop (length - 1)
              else (str, start, length) : slice
        in
          loop length
        end

    fun takel whileFn ((str, start, length):slice) =
        let
          fun loop i =
              if i < length
                 andalso whileFn (SMLSharp.PrimString.sub_unsafe
                                    (str, start + i))
              then loop (i + 1)
              else (str, start, i) : slice
        in
          loop 0
        end

    fun taker whileFn ((str, start, length):slice) =
        let
          fun loop i =
              if i < length
                 andalso whileFn (SMLSharp.PrimString.sub_unsafe
                                    (str, start + i))
              then loop (i + 1)
              else (str, start + length - i, i) : slice
        in
          loop 0
        end

    fun position str1 (arg as (slice as (str2, start, len2):slice)) =
        case StringBase.substringIndex str1 slice of
          NONE => (arg, (str2, start + len2, len2):slice)
        | SOME index =>
          let val prefixLen = index - start
          in ((str2, start, prefixLen) : slice,
              (str2, index, len2 - prefixLen) : slice)
          end

    fun span ((str1, start1, len1):slice, (str2, start2, len2):slice) =
        if String.compare (str1, str2) = EQUAL
           andalso start1 <= start2 + len2
        then (str1, start1, start2 + len2 - start1) : slice
        else raise General.Span

    val translate = StringBase.translate

    fun tokens isDelimiter ((str, beg, len):slice) =
        let
          val max = beg + len
          fun add (b, e, z) =
              if b = e then z else ((str, b, e - b):slice) :: z
          fun loop (beg, i, z) =
              if i >= max then rev (add (beg, i, z))
              else if isDelimiter (SMLSharp.PrimString.sub_unsafe (str, i))
              then loop (i + 1, i + 1, add (beg, i, z))
              else loop (beg, i + 1, z)
        in
          loop (beg, beg, nil)
        end

    fun fields isDelimiter ((str, beg, len):slice) =
        let
          val max = beg + len
          fun add (b, e, z) = ((str, b, e - b):slice) :: z
          fun loop (beg, i, z) =
              if i >= max then rev (add (beg, i, z))
              else if isDelimiter (SMLSharp.PrimString.sub_unsafe (str, i))
              then loop (i + 1, i + 1, add (beg, i, z))
              else loop (beg, i + 1, z)
        in
          loop (beg, beg, nil)
        end

  end (* Substring *)

  structure Word8ArrayBase =
  struct
    open ArrayBase

    type array = string
    type vector = string
    type elem = SMLSharp.Word8.word

    (* monomorphic version for efficiency *)
    fun List_length l =
        let
          fun loop (nil : SMLSharp.Word8.word list, z) = z
            | loop (h::t, z) = loop (t, z + 1)
        in
          loop (l, 0)
        end

    (* for fromList *)
    fun fillWithList (buf, elems) =
        let
          fun loop (i, nil) = ()
            | loop (i, h::t) =
              let val c = SMLSharp.Word8.toChar h
              in SMLSharp.PrimString.update_unsafe (buf, i, c);
                 loop (i + 1, t)
              end
        in
          loop (0, elems);
          buf
        end

    fun sub (ary, index) =
        SMLSharp.Word8.fromChar (ArrayBase.sub (ary, index))
    fun foldli foldFn z ary =
        ArrayBase.foldli
          (fn (i,x,z) => foldFn (i, SMLSharp.Word8.fromChar x, z))
          z ary
    fun foldl foldFn z ary =
        ArrayBase.foldli
          (fn (i,x,z) => foldFn (SMLSharp.Word8.fromChar x, z))
          z ary
    fun appi appFn ary =
        ArrayBase.foldli
          (fn (i,x,()) => appFn (i, SMLSharp.Word8.fromChar x))
          () ary
    fun app appFn ary =
        ArrayBase.foldli
          (fn (i,x,()) => appFn (SMLSharp.Word8.fromChar x))
          () ary
    fun foldri foldFn z ary =
        ArrayBase.foldri
          (fn (i,x,z) => foldFn (i, SMLSharp.Word8.fromChar x, z))
          z ary
    fun foldr foldFn z ary =
        ArrayBase.foldri
          (fn (i,x,z) => foldFn (SMLSharp.Word8.fromChar x, z))
          z ary
    fun findi predicate ary =
        case ArrayBase.findi
               (fn (i,x) => predicate (i, SMLSharp.Word8.fromChar x))
               ary of
          NONE => NONE
        | SOME (i,x) => SOME (i, SMLSharp.Word8.fromChar x)
    fun find predicate ary =
        case ArrayBase.findi
               (fn (i,x) => predicate (SMLSharp.Word8.fromChar x))
               ary of
          NONE => NONE
        | SOME (i,x) => SOME (SMLSharp.Word8.fromChar x)
    fun exists predicate ary =
        ArrayBase.exists (fn x => predicate (SMLSharp.Word8.fromChar x)) ary
    fun all predicate ary =
        ArrayBase.all (fn x => predicate (SMLSharp.Word8.fromChar x)) ary
    fun collate cmpFn arys =
        ArrayBase.collate
          (fn (x,y) => cmpFn (SMLSharp.Word8.fromChar x,
                              SMLSharp.Word8.fromChar y))
          arys

  end (* Word8ArrayBase *)

  structure Word8Vector : MONO_VECTOR =
  struct
    open Word8ArrayBase

    fun fromList elems =
        let
          val len = List_length elems
          val buf = SMLSharp.PrimString.allocVector len
        in
          fillWithList (buf, elems)
        end

    fun tabulate (len, elemFn) =
        CharVector.tabulate (len, fn i => SMLSharp.Word8.toChar (elemFn i))

    fun update (vec, index, elem) =
        CharVector.update (vec, index, SMLSharp.Word8.toChar elem)

    val concat = CharVector.concat

    fun mapi mapFn vec =
        CharVector.mapi
          (fn (i,x) => SMLSharp.Word8.toChar
                         (mapFn (i, SMLSharp.Word8.fromChar x)))
          vec
    fun map mapFn vec =
        CharVector.mapi
          (fn (i,x) => SMLSharp.Word8.toChar
                         (mapFn (SMLSharp.Word8.fromChar x)))
          vec

  end (* Word8Vector *)

  structure Word8Array : MONO_ARRAY =
  struct
    open Word8ArrayBase

    fun array (len, elem) =
        CharArray.array (len, SMLSharp.Word8.toChar elem)

    fun fromList elems =
        let
          val len = List_length elems
          val buf = SMLSharp.PrimString.allocArray len
        in
          fillWithList (buf, elems)
        end

    fun tabulate (len, elemFn) =
        CharArray.tabulate (len, fn i => SMLSharp.Word8.toChar (elemFn i))

    fun update (ary, index, elem) =
        CharArray.update (ary, index, SMLSharp.Word8.toChar elem)

    val vector = CharArray.vector
    val copy = CharArray.copy
    val copyVec = CharArray.copy

    fun modifyi mapFn ary =
        CharArray.modifyi
          (fn (i,x) => SMLSharp.Word8.toChar
                         (mapFn (i, SMLSharp.Word8.fromChar x)))
          ary
    fun modify mapFn ary =
        CharArray.modifyi
          (fn (i,x) => SMLSharp.Word8.toChar
                         (mapFn (SMLSharp.Word8.fromChar x)))
          ary

  end (* Word8Array *)

  structure Word8ArraySliceBase =
  struct
    open ArraySliceBase

    type array = string
    type vector = string
    type vector_slice = ArraySliceBase.slice
    type elem = SMLSharp.Word8.word

    fun sub (slice, index) =
        SMLSharp.Word8.fromChar (ArraySliceBase.sub (slice, index))

    fun getItem slice =
        case ArraySliceBase.getItem slice of
          NONE => NONE
        | SOME (x, slice) => SOME (SMLSharp.Word8.fromChar x, slice)

    fun foldli foldFn z slice =
        ArraySliceBase.foldli
          (fn (i,x,z) => foldFn (i, SMLSharp.Word8.fromChar x, z))
          z slice
    fun foldl foldFn z slice =
        ArraySliceBase.foldli
          (fn (i,x,z) => foldFn (SMLSharp.Word8.fromChar x, z))
          z slice
    fun appi appFn slice =
        ArraySliceBase.foldli
          (fn (i,x,()) => appFn (i, SMLSharp.Word8.fromChar x))
          () slice
    fun app appFn slice =
        ArraySliceBase.foldli
          (fn (i,x,()) => appFn (SMLSharp.Word8.fromChar x))
          () slice
    fun foldri foldFn z slice =
        ArraySliceBase.foldri
          (fn (i,x,z) => foldFn (i, SMLSharp.Word8.fromChar x, z))
          z slice
    fun foldr foldFn z slice =
        ArraySliceBase.foldri
          (fn (i,x,z) => foldFn (SMLSharp.Word8.fromChar x, z))
          z slice
    fun findi predicate slice =
        case ArraySliceBase.findi
               (fn (i,x) => predicate (i, SMLSharp.Word8.fromChar x))
               slice of
          NONE => NONE
        | SOME (i,x) => SOME (i, SMLSharp.Word8.fromChar x)
    fun find predicate slice =
        case ArraySliceBase.findi
               (fn (i,x) => predicate (SMLSharp.Word8.fromChar x))
               slice of
          NONE => NONE
        | SOME (i,x) => SOME (SMLSharp.Word8.fromChar x)
    fun exists predicate slice =
        ArraySliceBase.exists
          (fn x => predicate (SMLSharp.Word8.fromChar x))
          slice
    fun all predicate slice =
        ArraySliceBase.all
          (fn x => predicate (SMLSharp.Word8.fromChar x))
          slice
    fun collate cmpFn slices =
        ArraySliceBase.collate
          (fn (x,y) => cmpFn (SMLSharp.Word8.fromChar x,
                              SMLSharp.Word8.fromChar y))
          slices

  end (* Word8ArraySliceBase *)

  structure Word8VectorSlice : MONO_VECTOR_SLICE =
  struct
    open Word8ArraySliceBase
    val concat = CharVectorSlice.concat

    fun mapi mapFn vec =
        CharVectorSlice.mapi
          (fn (i,x) => SMLSharp.Word8.toChar
                         (mapFn (i, SMLSharp.Word8.fromChar x)))
          vec
    fun map mapFn vec =
        CharVectorSlice.mapi
          (fn (i,x) => SMLSharp.Word8.toChar
                         (mapFn (SMLSharp.Word8.fromChar x)))
          vec

  end (* Word8VectorSlice *)

  structure Word8ArraySlice : MONO_ARRAY_SLICE =
  struct
    open Word8ArraySliceBase

    fun update (slice, index, elem) =
        CharArraySlice.update (slice, index, SMLSharp.Word8.toChar elem)

    val copy = CharArraySlice.copy
    val copyVec = CharArraySlice.copy

    fun modifyi mapFn vec =
        CharArraySlice.modifyi
          (fn (i,x) => SMLSharp.Word8.toChar
                         (mapFn (i, SMLSharp.Word8.fromChar x)))
          vec
    fun modify mapFn vec =
        CharArraySlice.modifyi
          (fn (i,x) => SMLSharp.Word8.toChar
                         (mapFn (SMLSharp.Word8.fromChar x)))
          vec

  end (* Word8ArraySlice *)

  structure Byte =
  struct

    val byteToChar = SMLSharp.Word8.toChar
    val charToByte = SMLSharp.Word8.fromChar
    fun bytesToString x = x : string
    fun stringToBytes x = x : Word8Vector.vector
    val unpackStringVec = Word8VectorSlice.vector
    val unpackString = Word8ArraySlice.vector
    fun packString (ary, di, slice) =
        Word8ArraySlice.copy {src=slice, dst=ary, di=di}

  end (* Byte *)

end (* StringStructures *)

in

open StringStructures

type substring = Substring.substring
val op ^ = String.^
val concat = String.concat
val explode = String.explode
val implode = String.implode
val size = String.size
val str = String.str
val substring = String.substring

end (* local *)
