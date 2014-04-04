(**
 * String converter structure.
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 6 + - ^
infixr 5 ::
infix 4 = <> > >= < <=
val op - = SMLSharp_Builtin.Int.sub_unsafe
val op + = SMLSharp_Builtin.Int.add_unsafe
val op >= = SMLSharp_Builtin.Int.gteq
structure Array = SMLSharp_Builtin.Array
structure String = SMLSharp_Builtin.String

structure StringCvt =
struct

  datatype radix = BIN | OCT | DEC | HEX
  datatype realfmt =
           SCI of int option
         | FIX of int option
         | GEN of int option
         | EXACT
  type ('a, 'b) reader = 'b -> ('a * 'b) option

  fun fill (buf, beg, last, ch : char) =
      let
        fun loop i =
            if i >= last then ()
            else (Array.update_unsafe (buf, i, ch); loop (i + 1))
      in
        loop beg
      end

  fun padLeft padChar width string =
      let
        val len = String.size string
      in
        if len >= width then string else
        let
          val buf = String.alloc_unsafe width
          val padlen = width - len
        in
          fill (String.castToArray buf, 0, padlen, padChar);
          Array.copy_unsafe (String.castToArray string, 0,
                             String.castToArray buf, padlen, len);
          buf
        end
      end

  fun padRight padChar width string =
      let
        val len = String.size string
      in
        if len >= width then string else
        let
          val buf = String.alloc_unsafe width
        in
          Array.copy_unsafe (String.castToArray string, 0,
                             String.castToArray buf, 0, len);
          fill (String.castToArray buf, len, width, padChar);
          buf
        end
      end

  fun splitl predicate reader source =
      let
        fun scan (source, n, prefix) =
            case reader source of
              NONE => (n, prefix, source)
            | SOME (char, source') =>
              if predicate char
              then scan (source', n+1, char :: prefix)
              else (n, prefix, source)
        val (len, chars, source') = scan (source, 0, [])
        val buf = String.alloc_unsafe len
        fun loop (i, nil) = ()
          | loop (i, h::t) =
            (Array.update_unsafe (String.castToArray buf, i, h);
             loop (i - 1, t))
        val _ = loop (len - 1, chars)
      in
        (buf, source')
      end

  fun takel predicate reader source = #1(splitl predicate reader source)

  fun dropl predicate reader source = #2(splitl predicate reader source)

  local
    (* ToDo : this isWS and Char.isSpace shoud be the same. *)
    fun isWS #" " = true
      | isWS #"\n" = true
      | isWS #"\t" = true
      | isWS #"\r" = true
      | isWS #"\v" = true
      | isWS #"\f" = true
      | isWS _ = false
  in
  fun skipWS reader source =
      case reader source of
        NONE => source
      | SOME(char, source') =>
        if isWS char then skipWS reader source' else source
  end

  type cs = int

  fun scanString readerConverter string =
      let
        val stringSize = String.size string
        fun reader index =
            if index >= stringSize then NONE
            else SOME (Array.sub_unsafe (String.castToArray string, index),
                       index + 1)
      in
        case readerConverter reader 0 of
          NONE => NONE
        | SOME (result, _:cs) => SOME result
      end

end
