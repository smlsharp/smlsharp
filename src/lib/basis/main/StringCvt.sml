(**
 * String converter structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: StringCvt.sml,v 1.7 2005/04/28 16:35:32 kiyoshiy Exp $
 *)
structure StringCvt =
struct

  (***************************************************************************)

  datatype radix = BIN | OCT | DEC | HEX

  datatype realfmt =
           SCI of int Option.option
         | FIX of int Option.option
         | GEN of int Option.option
         | EXACT

  type ('a, 'b) reader = 'b -> ('a * 'b) Option.option

  (***************************************************************************)

  local
    fun makePad padChar requiredSize string =
        let
          val stringSize = size string
          val padSize = requiredSize - stringSize
        in
          if 0 < padSize
          then SOME(implode(List.tabulate (padSize, fn _ => padChar)))
          else NONE
      end
  in
  fun padLeft padChar width string =
      case makePad padChar width string of
        NONE => string
      | SOME padString => padString ^ string
                          
  fun padRight padChar width string =
      case makePad padChar width string of
        NONE => string
      | SOME padString => string ^ padString
  end                          

  fun splitl predicate reader source =
      let
        fun scan source prefix =
            case reader source of
              Option.NONE => (prefix, source)
            | Option.SOME (char, source') =>
              if predicate char
              then scan source' (char :: prefix)
              else (prefix, source)
      in
        case scan source [] of
          (prefixChars, source') => (implode(rev prefixChars), source')
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
        Option.NONE => source
      | Option.SOME(char, source') =>
        if isWS char then skipWS reader source' else source
  end

  type cs = int

  fun 'a scanString readerConverter string =
      let
        val stringSize = size string
        fun reader index =
            if index < stringSize
            then Option.SOME(String_sub (string, index), index + 1)
            else Option.NONE
(*
        val convertedReader : ('a, cs) reader =
            readerConverter (reader : (char, cs) reader)
*)
        val convertedReader =
            readerConverter reader
      in
        case convertedReader 0 of
          Option.NONE => Option.NONE
        | Option.SOME(result, _) => Option.SOME result
      end

end;
