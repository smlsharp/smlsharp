(**
 * String related structures.
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @copyright 2010, 2011, Tohoku University.
 *)

_interface "Word8Array.smi"

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
  structure Word8ArrayStructure :>
  sig
    structure Word8Array : MONO_ARRAY
      where type array = string
      where type vector = Word8Vector.vector
      where type elem = SMLSharp.Word8.word
    structure Word8ArraySlice : MONO_ARRAY_SLICE
      where type vector = Word8Vector.vector
      where type vector_slice = Word8VectorSlice.slice
      where type array = Word8Array.array
      where type elem = SMLSharp.Word8.word
  end
  = 
  struct
    structure Word8Array : MONO_ARRAY =
    struct
      type vector = string
      type array = string
      type elem = SMLSharp.Word8.word
    
      (* object size occupies 28 bits of 32-bit object header. *)
      val maxLen = 0x0fffffff
    
      val length = SMLSharp.PrimString.size
    
      fun sub (ary, index) =
          if index < 0 orelse SMLSharp.PrimString.size ary <= index
          then raise Subscript
          else SMLSharp.Word8.sub_unsafe (ary, index)
    
      fun foldli foldFn z ary =
          let
            val len = SMLSharp.PrimString.size ary
            fun loop (i, z) =
                if i >= len then z
                else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
                     in loop (i + 1, foldFn (i, x, z))
                     end
          in
            loop (0, z)
          end
    
      fun foldl foldFn z ary =
          foldli (fn (i,x,z) => foldFn (x,z)) z ary
    
      fun foldri foldFn z ary =
          let
            val len = SMLSharp.PrimString.size ary
            fun loop (i, z) =
                if i < 0 then z
                else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
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
            val len = SMLSharp.PrimString.size ary
            fun loop i =
                if i >= len then NONE
                else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
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
                else predicate (SMLSharp.Word8.sub_unsafe (ary, i))
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
                  val c1 = SMLSharp.Word8.sub_unsafe (ary1, i)
                  val c2 = SMLSharp.Word8.sub_unsafe (ary2, i)
                in
                  case cmpFn (c1, c2) of
                    EQUAL => loop (i + 1, rest1 - 1, rest2 - 1)
                  | order => order
                end
          in
            loop (0, len1, len2)
          end
    
      fun array (len, elem) =
          let
            val buf = SMLSharp.PrimString.allocArray len
            fun loop i =
                if i >= len then ()
                else (SMLSharp.Word8.update_unsafe (buf, i, elem);
                      loop (i + 1))
          in
            loop 0;
            buf
          end
    
      fun fromList elems =
          let
            fun length (nil : elem list, z) = z
              | length (h::t, z) = length (t, z + 1)
            val len = length (elems, 0)
            val buf = SMLSharp.PrimString.allocArray len
            fun fill (i, nil) = ()
              | fill (i, h::t) =
                (SMLSharp.Word8.update_unsafe (buf, i, h); fill (i + 1, t))
          in
            fill (0, elems);
            buf
          end
    
      fun tabulate (len, elemFn) =
          let
            val buf = SMLSharp.PrimString.allocArray len
            fun fill i =
                if i >= len then ()
                else (SMLSharp.Word8.update_unsafe (buf, i, elemFn i);
                      fill (i + 1))
          in
            fill 0;
            buf
          end
    
      fun update (ary, index, elem) =
          if index < 0 orelse SMLSharp.PrimString.size ary <= index
          then raise Subscript
          else SMLSharp.Word8.update_unsafe (ary, index, elem)
    
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
                else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
                     in SMLSharp.Word8.update_unsafe (ary, i, mapFn (i, x));
                        loop (i + 1)
                     end
          in
            loop 0
          end
    
      fun modify mapFn ary =
          modifyi (fn (i,x) => mapFn x) ary
    end (* Word8Array *)
  
    structure Word8ArraySlice = 
    struct
      type array = string
      type vector = string
      type slice = array * int * int  (* array * start * length *)
      type vector_slice = Word8VectorSlice.slice
      type elem = SMLSharp.Word8.word
    
      fun length ((ary, start, length):slice) = length
    
      fun sub ((ary, start, length):slice, index) =
          if index < 0 orelse length <= index then raise Subscript
         else SMLSharp.Word8.sub_unsafe (ary, start + index)
    
      fun full ary =
          (ary, 0, Word8Array.length ary) : slice
    
      fun slice (ary, start, lengthOpt) =
          let
            val length = Word8Array.length ary
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
        else SOME (SMLSharp.Word8.sub_unsafe (ary, start),
                   (ary, start + 1, length - 1) : slice)
  
    fun foldli foldFn z ((ary, start, length):slice) =
        let
          val max = start + length
          fun loop (i, z) =
              if i >= max then z
              else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
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
              else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
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
              else let val x = SMLSharp.Word8.sub_unsafe (ary, i)
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
              else predicate (SMLSharp.Word8.sub_unsafe (ary, i))
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
                val c1 = SMLSharp.Word8.sub_unsafe (ary1, i)
                val c2 = SMLSharp.Word8.sub_unsafe (ary2, j)
              in
                case cmpFn (c1, c2) of
                  EQUAL => loop (i + 1, rest1 - 1, j + 1, rest2 - 1)
                | order => order
              end
        in
          loop (start1, length1, start2, length2)
        end
  
    fun update ((ary, start, length):slice, index, elem) =
        if index < 0 orelse length <= index
        then raise Subscript
        else SMLSharp.Word8.update_unsafe (ary, start + index, elem)
  
    fun copy {src = (srcary, srcstart, srclen):slice, dst, di} =
        let
          val dstlen = Word8Array.length dst
        in
          if di < 0 orelse dstlen < di orelse dstlen - di < srclen
          then raise Subscript
          else SMLSharp.PrimString.copy_unsafe
                 (srcary, srcstart, dst, di, srclen)
        end
  
    fun copyVec {src:vector_slice, dst, di} =
        let
          val (srcary, srcstart, srclen) = Word8VectorSlice.base src
          val dstlen = Word8Array.length dst
        in
          if di < 0 orelse dstlen < di orelse dstlen - di < srclen
          then raise Subscript
          else SMLSharp.PrimString.copy_unsafe
                  (srcary, srcstart, dst, di, srclen)
        end
  
    fun modifyi mapFn ((ary, start, length):slice) =
        let
          val max = start + length
          fun loop i =
              if i >= max then ()
              else
                let val x = SMLSharp.Word8.sub_unsafe (ary, i)
                    val x = mapFn (i - start, x)
                in SMLSharp.Word8.update_unsafe (ary, i, x);
                   loop (i + 1)
                end
        in
          loop start
        end
  
    fun modify mapFn slice =
        modifyi (fn (i,x) => mapFn x) slice
  end  (* Word8ArraySlice *)
  end  (* Word8ArrayStructure *)
in

open Word8ArrayStructure

end (* local *)
