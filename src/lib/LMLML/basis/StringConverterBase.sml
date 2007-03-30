(**
 * String converter structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: StringConverterBase.sml,v 1.1 2006/12/11 10:57:04 kiyoshiy Exp $
 *)
functor StringConverterBase
        (P
         : sig
             type string
             type char
             val sub : string * int -> char
             val size : string -> int
             val concat : string list -> string
             val implode : char list -> string
             val isSpace : char -> bool
         end) : STRING_CONVERTER =
struct

  (***************************************************************************)

  type char = P.char
  type string = P.string

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
          val stringSize = P.size string
          val padSize = requiredSize - stringSize
        in
          if 0 < padSize
          then SOME(P.implode(List.tabulate (padSize, fn _ => padChar)))
          else NONE
      end
  in
  fun padLeft padChar width string =
      case makePad padChar width string of
        NONE => string
      | SOME padString => P.concat [padString, string]
                          
  fun padRight padChar width string =
      case makePad padChar width string of
        NONE => string
      | SOME padString => P.concat [string, padString]
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
          (prefixChars, source') => (P.implode(rev prefixChars), source')
      end

  fun takel predicate reader source = #1(splitl predicate reader source)

  fun dropl predicate reader source = #2(splitl predicate reader source)

  local
    (* ToDo : this isWS and Char.isSpace shoud be the same. *)
(*
    fun isWS #" " = true
      | isWS #"\n" = true
      | isWS #"\t" = true
      | isWS #"\r" = true
      | isWS #"\v" = true
      | isWS #"\f" = true
      | isWS _ = false
*)
    fun isWS c = P.isSpace c
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
        val stringSize = P.size string
        fun reader index =
            if index < stringSize
            then Option.SOME(P.sub (string, index), index + 1)
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
