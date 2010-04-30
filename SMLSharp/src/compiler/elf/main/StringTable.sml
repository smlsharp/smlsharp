(**
 * write a binary object to file in ELF format.
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: StringTable.sml,v 1.1 2007/11/19 06:00:02 katsu Exp $
 *)
structure StringTable : sig

  type strtab
  type index = Word32.word

  val initialStrtab : strtab
  val intern : strtab * string -> strtab * index
  val intern' : strtab * string -> strtab
  val dumpString : Word8Array.array * int * string -> unit
  val dump : strtab -> Word8Array.array

end =
struct

  structure SubstringOrd =
  struct
    type ord_key = Substring.substring
    val compare = Substring.compare
  end

  structure SubstringMap = BinaryMapFn(SubstringOrd)

  type index = Word32.word

  val toIndex = Word32.fromInt

  type strtab =
      {
        strings: string list,   (* reversed list *)
        lastIndex: int,
        suffixMap: index SubstringMap.map
      }

  val initialStrtab =
      {
        strings = nil,
        lastIndex = 1,
        suffixMap = SubstringMap.empty
      } : strtab

  fun add suffixMap str index =
      let
        fun loop s i 0 map = map
          | loop s i n map =
            let
              val ss = Substring.substring (s, i, n)
              val map = SubstringMap.insert (map, ss, toIndex i + index)
            in
              loop s (i+1) (n-1) map
            end
      in
        loop str 0 (size str) suffixMap
      end

  fun intern (strtab as {strings, lastIndex, suffixMap}:strtab, str) =
      let
        val sz = size str
        val ss = Substring.substring (str, 0, sz)
      in
        case SubstringMap.find (suffixMap, ss) of
          SOME x => (strtab, x)
        | NONE =>
          let
            val index = toIndex lastIndex
          in
            ({
               strings = str :: strings,
               lastIndex = lastIndex + sz + 1,
               suffixMap = add suffixMap str index
             },
             index)
          end
      end

  fun intern' x = #1 (intern x)

  fun dumpString (a, i, s) =
      (CharVector.foldl
         (fn (x, i) => (Word8Array.update (a, i, Word8.fromInt (ord x)); i+1))
         i s;
       ())

  fun dump ({strings, lastIndex, ...}:strtab) =
      let
        val a = Word8Array.array (lastIndex, 0w0)
      in
        (* first byte of strtab must be 0 *)
        foldr (fn (x, i) => (dumpString (a, i, x); i + size x + 1)) 1 strings;
        a
      end

end
