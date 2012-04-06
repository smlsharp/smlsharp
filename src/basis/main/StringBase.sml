_interface "StringBase.smi"
structure StringBase =
struct
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
in
  type substring = string * int * int
  (* object size occupies 28 bits of 32-bit object header. *)
  val maxLen = 0x0fffffff
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
            in if z > maxLen then raise Size
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
                if size + n > maxLen then raise Size else ();
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

  fun concat strings =
      let
        fun totalLength (nil, z) = z
          | totalLength (h::t, z) =
            let val len = SMLSharp.PrimString.size h
                val z = len + z
            in if z > maxLen then raise Size else totalLength (t, z)
            end
        val len = totalLength (strings, 0)
        val buf = SMLSharp.PrimString.allocVector len
        fun loop (i, nil) = ()
          | loop (i, h::t) =
            let val len = SMLSharp.PrimString.size h
            in SMLSharp.PrimString.copy_unsafe (h, 0, buf, i, len);
               loop (i + len, t)
            end
      in
        loop (0, strings);
        buf
      end

  fun sub (ary, index) =
      if index < 0 orelse SMLSharp.PrimString.size ary <= index
      then raise Subscript
      else SMLSharp.PrimString.sub_unsafe (ary, index)

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

  fun fromList elems =
      let
        fun length (nil : char list, z) = z
          | length (h::t, z) = length (t, z + 1)
        val len = length (elems, 0)
        val buf = SMLSharp.PrimString.allocVector len
        fun fill (i, nil) = ()
          | fill (i, h::t) =
            (SMLSharp.PrimString.update_unsafe (buf, i, h); fill (i + 1, t))
      in
        fill (0, elems);
        buf
      end

end
end (* StringBase *)
