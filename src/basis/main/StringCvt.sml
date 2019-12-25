(**
 * String converter structure.
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 6 + - ^
infixr 5 ::
infix 4 = <> > >= < <=
val op - = SMLSharp_Builtin.Int32.sub_unsafe
val op + = SMLSharp_Builtin.Int32.add_unsafe
val op <= = SMLSharp_Builtin.Int32.lteq
val op >= = SMLSharp_Builtin.Int32.gteq
structure Int32 = SMLSharp_Builtin.Int32
structure Array = SMLSharp_Builtin.Array
structure String = SMLSharp_Builtin.String

structure StringCvt =
struct

  datatype radix = BIN | OCT | DEC | HEX
  datatype realfmt =
           SCI of int32 option
         | FIX of int32 option
         | GEN of int32 option
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
        if width <= len then string else
        let
          val buf = String.alloc width
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
        if width <= len then string else
        let
          val buf = String.alloc width
        in
          Array.copy_unsafe (String.castToArray string, 0,
                             String.castToArray buf, 0, len);
          fill (String.castToArray buf, len, width, padChar);
          buf
        end
      end

  fun splitl predicate reader source =
      let
        fun scan (take, n, source) =
            case reader source of
              NONE => (take, n, source)
            | SOME (char, source') =>
              if predicate char
              then scan (char :: take, Int32.add (n, 1), source')
              else (take, n, source)
        val (chars, len, source') =
            scan ([], 0, source) handle Overflow => raise Size
        val buf = String.alloc len
        fun loop (i, nil) = ()
          | loop (i, h::t) =
            (Array.update_unsafe (String.castToArray buf, i, h);
             loop (i - 1, t))
      in
        loop (len - 1, chars);
        (buf, source')
      end

  fun takel predicate reader source =
      #1 (splitl predicate reader source)

  fun dropl predicate reader source =
      case reader source of
        NONE => source
      | SOME (char, source') =>
        if predicate char then dropl predicate reader source' else source

  (* isWS must be the same as Char.isSpace. *)
  fun isWS #" " = true
    | isWS #"\n" = true
    | isWS #"\t" = true
    | isWS #"\r" = true
    | isWS #"\v" = true
    | isWS #"\f" = true
    | isWS _ = false

  fun skipWS reader source =
      case reader source of
        NONE => source
      | SOME(char, source') =>
        if isWS char then skipWS reader source' else source

  type cs = int32

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
