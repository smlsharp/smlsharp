(*
val String_sub = String.sub;
val String_substring = String.substring;
val String_size = String.size;
val String_concat2 = op ^;
*)

(**
 * Substring structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Substring.sml,v 1.4 2005/05/01 21:26:57 kiyoshiy Exp $
 *)
structure Substring =
struct

  (***************************************************************************)

  type char = char

  type string = string

  type substring = {string : string, start : int, length : int}

  (***************************************************************************)

  fun base ({string, start, length} : substring) = (string, start, length)

  fun string (substring : substring) = 
      String_substring (#string substring, #start substring, #length substring)

  fun extract (string, start, lengthOpt) =
      let
        val sizeOfString = String_size string
        val length =
            case lengthOpt of
              NONE =>
              if start < 0 orelse sizeOfString < start
              then raise General.Subscript
              else sizeOfString - start
            | SOME length =>
              if
                start < 0
                orelse length < 0
                orelse sizeOfString < start + length
              then raise General.Subscript 
              else length
      in {string = string, start = start, length = length} : substring
      end

  fun substring (string, start, length) = extract (string, start, SOME length)

  fun all string =
      {string = string, start = 0, length = size string} : substring

  fun isEmpty (substring : substring) = (#length substring) = 0

  fun getc ({string, start, length} : substring) =
      if 0 = length
      then NONE
      else
        let
          val newSubstring =
              {string = string, start = start + 1, length = length - 1}
        in SOME(String_sub(string, start), newSubstring)
        end

  fun first ({string, start, length} : substring) =
      if length = 0 then NONE else SOME(String_sub (string, start))

  fun triml removeLength =
      if removeLength < 0
      then raise General.Subscript
      else
       fn ({string, start, length} : substring) =>
          if length < removeLength
          then {string = string, start = start + length, length = 0}
          else
            {
              string = string,
              start = start + removeLength,
              length = length - removeLength
            } : substring

  fun trimr removeLength =
      if removeLength < 0
      then raise General.Subscript
      else
       fn ({string, start, length} : substring) =>
          if length < removeLength
          then {string = string, start = start, length = 0}
          else
            {
              string = string,
              start = start,
              length = length - removeLength
            } : substring

  fun slice (substring : substring, start, lengthOpt) =
      let
        val length =
            case lengthOpt of
              NONE =>
              if start < 0 orelse #length substring < start
              then raise General.Subscript
              else #length substring - start
            | SOME length =>
              if
                start < 0
                orelse length < 0
                orelse #length substring < (start + length)
              then raise General.Subscript
              else length
      in
        {
          string = #string substring,
          start = #start substring + start,
          length = length
        }
      end

  fun sub ({string, start, length, ...} : substring, index) =
      if index < 0 orelse length <= index
      then raise General.Subscript
      else String_sub (string, start + index)

  fun size ({string, length, ...} : substring) = length

  fun concat [] = ""
    | concat (substring :: substrings) =
      let
        fun append [] result = result
          | append (head :: tail) result =
            append tail (String_concat2 (result, string head))
      in append substrings (string substring)
      end

  fun explode ({string, start, length} : substring) =
    let
      fun accum 0 chars = chars
        | accum n chars =
          accum (n - 1) (String_sub (string, start + n - 1) :: chars)
    in accum length [] end

  (** return true if the string is a prefix of the substring. *)
  fun isPrefix string (substring : substring) =
      let
        val sizeOfString = String_size string
        fun scan index =
            if sizeOfString <= index
            then true
            else
              if
                String_sub (string, index)
                = String_sub (#string substring, #start substring + index)
              then scan (index + 1)
              else false
      in
        if #length substring < sizeOfString then false else scan 0
      end

  fun collate
          charCollate
          (
            {string = leftString, start = leftStart, length = leftLength},
            {string = rightString, start = rightStart, length = rightLength}
          ) =
      let
        fun scan index =
            if leftLength = index orelse rightLength = index
            then
              if leftLength < rightLength
              then General.LESS
              else
                if leftLength = rightLength
                then General.EQUAL
                else General.GREATER
            else
              let
                val leftChar = String_sub (leftString, leftStart + index)
                val rightChar = String_sub (rightString, rightStart + index)
              in
                case charCollate (leftChar, rightChar) of
                  EQUAL => scan (index + 1)
                | notEqual => notEqual
              end
      in
        scan 0
      end
        
  fun compare arg =
      let
        fun charCollate (leftChar : char, rightChar) =
            if leftChar < rightChar
            then General.LESS
            else
              if leftChar = rightChar then General.EQUAL else General.GREATER
      in collate charCollate arg
      end

  fun splitAt ({string, start, length} : substring, index) =
      if index < 0 orelse length < index
      then raise General.Subscript
      else
        (* NOTE: it is allowed even if length = index. *)
        let
          val left = {string = string, start = start, length = index}
          val right =
              {string = string, start = start + index, length = length - index}
        in
          (left, right)
        end

  fun splitl predicate (substring as {string, start, length} : substring) =
      let
        fun scan index =
            if length = index
            then index
            else
              if predicate (String_sub (string, start + index))
              then scan (index + 1)
              else index
        val index = scan 0 (* index of the start of the right *)
      in splitAt (substring, index)
      end

  fun splitr predicate (substring as {string, start, length} : substring) =
      let
        fun scan index =
            if index < 0
            then index
            else
              if predicate (String_sub (string, start + index))
              then scan (index - 1)
              else index
        val index = scan (length - 1) (* index of the end of the left *)
      in splitAt (substring, index + 1)
      end

  fun dropl predicate ({string, start, length} : substring) =
      let
        fun scan index =
            if length = index
            then index
            else
              if predicate (String_sub (string, start + index))
              then scan (index + 1)
              else index
        val index = scan 0
      in {string = string, start = start + index, length = length - index}
      end

  fun dropr predicate (substring as {string, start, length = 0} : substring) =
      substring
    | dropr predicate ({string, start, length} : substring) =
      let
        fun scan index =
            if index < 0
            then index
            else
              if predicate (String_sub (string, start + index))
              then scan (index - 1)
              else index
        val index = scan (length - 1)
      in {string = string, start = start, length = index + 1}
      end

  fun takel predicate ({string, start, length} : substring) =
      let
        fun scan index =
            if length = index
            then index
            else
              if predicate (String_sub (string, start + index))
              then scan (index + 1)
              else index
        val index = scan 0
      in {string = string, start = start, length = index}
      end

  fun taker predicate (substring as {string, start, length = 0} : substring) =
      substring
    | taker predicate ({string, start, length} : substring) =
      let
        fun scan index =
            if index < 0
            then index
            else
              if predicate (String_sub (string, start + index))
              then scan (index - 1)
              else index
        val index = (scan (length - 1)) + 1 (* the left-most index of right *)
      in {string = string, start = start + index, length = length - index}
      end

  fun position string (substring : substring) =
      let
        val sizeOfString = String_size string
        val isPrefix = isPrefix string
        fun scan index =
            if #length substring - index < sizeOfString
            then
              {
                string = #string substring,
                start = #start substring + #length substring,
                length = 0
              }
            else
            let
              val newSubstring =
                  {
                    string = #string substring,
                    start = #start substring + index,
                    length = #length substring - index
                  }
            in
              if isPrefix newSubstring
              then newSubstring
              else scan (index + 1)
            end
        val suffix = scan 0
        val prefix =
            {
              string = #string substring,
              start = #start substring,
              length = #length substring - #length suffix
            }
      in
        (prefix, suffix)
      end

  fun span
          (
            {string = leftString, start = leftStart, length = leftLength},
            {string = rightString, start = rightStart, length = rightLength}
          ) =
      if leftString <> rightString orelse rightStart + rightLength < leftStart
      then raise General.Span
      else
        {
          string = leftString,
          start = leftStart,
          length = rightStart + rightLength - leftStart
        }

  fun translate transChar {string, start, length} =
      let
        fun scan index accum =
            if length = index
            then accum
            else
              let
                val translated = 
                    transChar (String_sub (string, start + index))
              in
                scan (index + 1) (accum ^ translated)
              end
      in scan 0 ""
      end

  local
    fun divideToElements
            isNewElement isDelimiter ({string, start, length} : substring) =
        let
          (* startIndexOfToken is the index from the start of the substring,
           * not of the 'string'. *)
          fun addToken startIndexOfToken lastIndexOfToken tokens =
              let val lengthOfToken = lastIndexOfToken - startIndexOfToken
              in
                if isNewElement lengthOfToken
                then
                  {
                    string = string,
                    start = start + startIndexOfToken,
                    length = lengthOfToken
                  }
                  :: tokens
                else tokens
              end
          fun scan startIndexOfLastToken index tokens =
              if length = index
              then (startIndexOfLastToken, tokens)
              else
                if isDelimiter (String_sub (string, start + index))
                then
                  let
                    val newTokens = addToken startIndexOfLastToken index tokens
                  in scan (index + 1) (index + 1) newTokens
                  end
                else scan startIndexOfLastToken (index + 1) tokens
          val (startIndexOfLastToken, tokens) = scan 0 0 []
          val tokens = addToken startIndexOfLastToken length tokens
        in List.rev tokens
        end
  in
  fun tokens isDelimiter substring =
      let fun isNewToken lengthOfToken = (0 < lengthOfToken)
      in divideToElements isNewToken isDelimiter substring
      end
  fun fields isDelimiter substring =
      let fun isNewToken _ = true
      in divideToElements isNewToken isDelimiter substring
      end
  end

  fun foldl folder initial ({string, start, length} : substring) =
      let
        fun scan index accum =
            if length = index
            then accum
            else
              let
                val newAccum =
                    folder (String_sub(string, start + index), accum)
              in scan (index + 1) newAccum
              end
      in scan 0 initial
      end

  fun foldr folder initial ({string, start, length} : substring) =
      let
        fun scan index accum =
            if index < 0
            then accum
            else
              let
                val newAccum =
                    folder (String_sub(string, start + index), accum)
              in scan (index - 1) newAccum
              end
      in scan (length - 1) initial
      end

  fun app f ({string, start, length} : substring) =
      let
        fun scan index =
            if index = length
            then ()
            else (f (String_sub(string, start + index)); scan (index + 1))
      in scan 0
      end

  (***************************************************************************)

end;

