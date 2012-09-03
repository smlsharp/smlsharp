(**
 * String structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: StringBase.sml,v 1.1 2006/12/11 10:57:03 kiyoshiy Exp $
 *)
(*
 * Because the STRING signature refers to String structure, the STRING
 * signature and the String structure makes a recursive reference.
 * To avoid this, we define the String structure without constraint first,
 * then define the STRING signature, and re-define the String structure
 * constrained by the STRING signature.
 *)
functor StringBase
        (P
         : sig
             type string
             type char
             val sub : string * int -> char
             val substring : string * int * int -> string
             val size : string -> int
             val concat : string list -> string
             val compareChar : char * char -> General.order
             val charToString : char -> string
         end) =
struct

  type string = P.string

  type char = P.char

(*
  val maxSize = 0xFFFFFFFF
*)
  val maxSize = 0xFFFF

  val emptyString = P.concat []

  val size = P.size (* NOTE: sizeString is a primitive operator. *)

  fun sub (string, index) =
      if index < 0 orelse size string <= index
      then raise General.Subscript
      else P.sub (string, index)(* NOTE: P.sub is a primitive. *)

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
          then emptyString
          else P.substring (string, begin, length)
      end

  fun substring (string, begin, length) = extract(string, begin, SOME length)

  fun concat strings = P.concat strings

  fun concatWith separator [] = emptyString
    | concatWith separator [string] = string
    | concatWith separator (string :: strings) =
      let
        fun append [] result = result
          | append (head :: tail) result =
            append tail (P.concat [result, separator, head])
      in append strings string
      end

  fun left ^ right = P.concat [left, right]

  val str = P.charToString

  fun implode chars = concat (List.map str chars)

  fun explode string =
      let
        fun accum 0 chars = chars
          | accum n chars = accum (n - 1) (sub (string, n - 1) :: chars)
      in accum (size string) [] end

  fun map mapper string = implode(List.map mapper (explode string))

  fun translate translator string =
      concat(List.map translator (explode string))

  fun tokens isDelimiter string =
      let
        val len = size string
        fun tok (start, last) = substring (string, start, last - start)
        fun inToken index (start, tokens) =
            if len <= index
            then (tok (start, index)) :: tokens
            else
              if isDelimiter (sub (string, index))
              then inDelimiter (index + 1) (tok (start, index) :: tokens)
              else inToken (index + 1) (start, tokens)
        and inDelimiter index tokens =
            if len <= index
            then tokens
            else
              if isDelimiter (sub (string, index))
              then inDelimiter (index + 1) tokens
              else inToken (index + 1) (index, tokens)
      in List.rev (inDelimiter 0 []) end

  fun fields isDelimiter string =
      let
        val len = size string
        fun tok (start, last) = substring (string, start, last - start)
        fun inToken index (start, tokens) =
            if len <= index
            then (tok (start, index)) :: tokens
            else
              if isDelimiter (sub (string, index))
              then inDelimiter (index + 1) (tok (start, index) :: tokens)
              else inToken (index + 1) (start, tokens)
        and inDelimiter index tokens =
            if len <= index
            then tok (index, index) :: tokens
            else
              if isDelimiter (sub (string, index))
              then (* add an empty field. *)
                inDelimiter (index + 1) (tok (index, index) :: tokens)
              else inToken (index + 1) (index, tokens)
      in List.rev (inToken 0 (0, [])) end

  local
    fun collateImp
            charCollate
            ((left, leftStart, leftSize), (right, rightStart, rightSize)) =
      let
        fun scan index =
            if leftSize = index orelse rightSize = index
            then
              if leftSize < rightSize
              then General.LESS
              else
                if leftSize = rightSize then General.EQUAL else General.GREATER
            else
              case
                charCollate
                    (
                      sub (left, leftStart + index),
                      sub (right, rightStart + index)
                    )
               of EQUAL => scan (index + 1)
                | notEqual => notEqual
      in scan 0 end
  in

  fun collate charCollate (left, right) =
      let
        val leftSize = size left
        val rightSize = size right
      in
        collateImp charCollate ((left, 0, leftSize), (right, 0, rightSize))
      end

  val compare = collate P.compareChar

  fun isPrefix left right =
      let
        val leftSize = size left
        val rightSize = size right
      in
        if rightSize < leftSize
        then false
        else
          General.EQUAL
          = collateImp
                P.compareChar ((left, 0, leftSize), (right, 0, leftSize))
      end

  fun isSubstring left right = 
      let
        val leftSize = size left
        val rightSize = size right
        (* ToDo : rewrite by efficient search algorithm. *)
        fun search index =
            if rightSize - index < leftSize
            then false
            else
              if
                General.EQUAL
                = collateImp
                      P.compareChar
                      ((left, 0, leftSize), (right, index, leftSize))
              then true
              else search (index + 1)
      in
        search 0
      end

  fun isSuffix left right =
      let
        val leftSize = size left
        val rightSize = size right
      in
        if rightSize < leftSize
        then false
        else
          General.EQUAL
          = collateImp
                P.compareChar
                ((left, 0, leftSize), (right, rightSize - leftSize, leftSize))
      end

  fun op < (left, right) =
      case compare (left, right) of General.LESS => true | _ => false
  fun op <= (left, right) =
      case compare (left, right) of General.GREATER => false | _ => true
  val op > = not o (op <=)
  val op >= = not o (op <)

  end (* end of local *)
(*
  local structure PC = ParserComb
  in
  fun fromString string =
      StringCvt.scanString
          (PC.wrap(PC.zeroOrMore Char.scan, fn chars => implode chars))
          string
  end  
  fun toString string = translate P.charToString string

  local structure PC = ParserComb
  in
  fun fromCString string =
      StringCvt.scanString
          (PC.wrap(PC.zeroOrMore Char.scanCString, fn chars => implode chars))
          string
  end  
  fun toCString string = string
*)
end;