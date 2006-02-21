(**
 * String structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: String.sml,v 1.8 2005/08/16 23:25:00 kiyoshiy Exp $
 *)
(*
 * Because the STRING signature refers to String structure, the STRING
 * signature and the String structure makes a recursive reference.
 * To avoid this, we define the String structure without constraint first,
 * then define the STRING signature, and re-define the String structure
 * constrained by the STRING signature.
 *)
structure String =
struct

  type string = string (* NOTE: string is a primitie type. *)

  type char = char

(*
  val maxSize = 0xFFFFFFFF
*)
  val maxSize = 0xFFFF

  val size = String_size (* NOTE: sizeString is a primitive operator. *)

  fun sub (string, index) =
      if index < 0 orelse size string <= index
      then raise General.Subscript
      else String_sub (string, index)(* NOTE: String_sub is a primitive. *)

  fun extract (string, begin, lengthOpt) =
      let
        val stringSize = size string
        val length =
            case lengthOpt of
              NONE => stringSize - begin
            | SOME length => length
      in
        if
          case lengthOpt of
            NONE => (begin < 0) orelse (stringSize < begin)
          | SOME length =>
            (begin < 0)
            orelse (length < 0)
            orelse (stringSize < begin + length)
        then raise General.Subscript
        else
          if (begin = stringSize) andalso (length = 0)
          then ""
          else String_substring (string, begin, length)
      end

  fun substring (string, begin, length) = extract(string, begin, SOME length)

  fun concat [] = ""
    | concat (string :: strings) =
      let
        fun append [] result = result
          | append (head :: tail) result =
            append tail (String_concat2 (result, head))
      in append strings string
      end

  fun concatWith separator [] = ""
    | concatWith separator [string] = string
    | concatWith separator (string :: strings) =
      let
        fun append [] result = result
          | append (head :: tail) result =
            append
                tail
                (String_concat2 (result, String_concat2(separator, head)))
      in append strings string
      end

  val op ^ = op ^ (* ^ is a primitive operator. *)

  val str = Char_toString

  fun implode chars =
      let
        fun scan [] accum = accum
          | scan (char :: chars) accum =
            scan chars (accum ^ (Char_toString char))
      in scan chars ""
      end

  fun explode string =
      let
        fun accum 0 chars = chars
          | accum n chars = accum (n - 1) (sub (string, n - 1) :: chars)
      in accum (size string) [] end

  fun map mapper string =
      implode(List.map mapper (explode string))

  fun translate translator string =
      concat(List.map translator (explode string))

  fun tokens isDelimiter string =
      let
        val chars = explode string
        fun charsToToken chars = implode (List.rev chars)
        val (chars, tokens) =
            List.foldl
            (fn (char, (chars, tokens)) =>
                if isDelimiter char
                then
                  case chars of
                    [] => ([], tokens)
                  | _ :: _ => ([], charsToToken chars :: tokens)
                else (char :: chars, tokens))
            ([], [])
            chars
        val tokens =
            case chars of
              [] => tokens |
              _ :: _ => (charsToToken chars) :: tokens
      in List.rev tokens end

  fun fields isDelimiter string =
      let
        val chars = explode string
        fun charsToField chars = implode (List.rev chars)
        val (chars, fields) =
            List.foldl
            (fn (char, (chars, fields)) =>
                if isDelimiter char
                then ([], charsToField chars :: fields)
                else (char :: chars, fields))
            ([], [])
            chars
        val fields = (charsToField chars) :: fields
      in List.rev fields end

  fun isPrefix left right =
      let
        val leftSize = size left
        val rightSize = size right
      in
        if rightSize < leftSize
        then false
        else left = substring (right, 0, leftSize)
      end

  fun isSubstring left right = (* ToDo : implement *)
      raise General.Fail "String.isSubstring is not implemented."

  fun isSuffix left right =
      let
        val leftSize = size left
        val rightSize = size right
      in
        if rightSize < leftSize
        then false
        else left = substring (right, rightSize - leftSize, leftSize)
      end

  fun collate charCollate (left, right) =
      let
        val leftSize = size left
        val rightSize = size right
        fun scan index =
            if leftSize = index orelse rightSize = index
            then
              if leftSize < rightSize
              then General.LESS
              else
                if leftSize = rightSize then General.EQUAL else General.GREATER
            else
              case charCollate (sub (left, index), sub (right, index)) of
                EQUAL => scan (index + 1)
              | notEqual => notEqual
      in scan 0 end

  val compare = collate Char.compare

  fun op < (left, right) =
      case compare (left, right) of General.LESS => true | _ => false
  fun op <= (left, right) =
      case compare (left, right) of General.GREATER => false | _ => true
  val op > = not o (op <=)
  val op >= = not o (op <)

  local structure PC = ParserComb
  in
  fun fromString string =
      StringCvt.scanString
          (PC.wrap(PC.zeroOrMore Char.scan, fn chars => implode chars))
          string
  end  
  fun toString string = translate Char.toString string

  local structure PC = ParserComb
  in
  fun fromCString string =
      StringCvt.scanString
          (PC.wrap(PC.zeroOrMore Char.scanCString, fn chars => implode chars))
          string
  end  
  fun toCString string = string

end;