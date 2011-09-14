(**
 * String converter structure.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: StringCvt.sml,v 1.7 2005/04/28 16:35:32 kiyoshiy Exp $
 *)
_interface "StringCvt.smi"

structure StringCvt :> STRING_CVT =
struct

  infix 6 + - ^
  infixr 5 ::
  infix 4 = <> > >= < <=

  val op - = SMLSharp.Int.sub
  val op >= = SMLSharp.Int.gteq
  val op + = SMLSharp.Int.add

  datatype radix = BIN | OCT | DEC | HEX
  datatype realfmt =
           SCI of int option
         | FIX of int option
         | GEN of int option
         | EXACT
  type ('a, 'b) reader = 'b -> ('a * 'b) option

  fun fill (buf, beg, last, ch) =
      let
        fun loop i =
            if i >= last then ()
            else (SMLSharp.PrimString.update_unsafe (buf, i, ch); loop (i + 1))
      in
        loop beg
      end

  fun padLeft padChar width string =
      let
        val len = SMLSharp.PrimString.size string
      in
        if len >= width then string else
        let
          val buf = SMLSharp.PrimString.allocVector width
        in
          fill (buf, 0, width - len, padChar);
          SMLSharp.PrimString.copy_unsafe (string, 0, buf, width - len, len);
          buf
        end
      end

  fun padRight padChar width string =
      let
        val len = SMLSharp.PrimString.size string
      in
        if len >= width then string else
        let
          val buf = SMLSharp.PrimString.allocVector width
        in
          SMLSharp.PrimString.copy_unsafe (string, 0, buf, 0, len);
          fill (buf, len, width, padChar);
          buf
        end
      end

  fun splitl predicate reader source =
      let
        fun scan source n prefix =
            case reader source of
              NONE => (n, prefix, source)
            | SOME (char, source') =>
              if predicate char
              then scan source' (n+1) (char :: prefix)
              else (n, prefix, source)
        val (len, chars, source') = scan source 0 []
        val buf = SMLSharp.PrimString.allocVector len
        fun loop (i, nil) = ()
          | loop (i, h::t) =
            (SMLSharp.PrimString.update_unsafe (buf, i, h); loop (i - 1, t))
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
        val stringSize = SMLSharp.PrimString.size string
        fun reader index =
            if index >= stringSize then NONE
            else SOME (SMLSharp.PrimString.sub_unsafe (string, index),
                       index + 1)
      in
        case readerConverter reader 0 of
          NONE => NONE
        | SOME (result, _:cs) => SOME result
      end

end
