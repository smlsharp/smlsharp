(**
 * Substring structure, defunctorized.
 * @author Atsushi Ohori 
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Substring.sml,v 1.6 2006/09/16 08:10:20 kiyoshiy Exp $
 *)
structure Substring = struct
local
  structure P = struct
    val emptyString = ""
    val sub = SMLSharp.PrimString.sub_unsafe
    val substring = SMLSharp.Runtime.String_substring
    val size = SMLSharp.PrimString.size
    val concat2 = SMLSharp.Runtime.String_concat2
    fun compare (left : string, right) =
        if left < right then LESS else if left = right then EQUAL else GREATER
    fun compareChar (left : char, right) =
        if left < right then LESS else if left = right then EQUAL else GREATER
  end
in

  type char = char
  type string = string
  (***************************************************************************)

  type substring = {string : string, start : int, length : int}

  (***************************************************************************)

  fun base ({string, start, length} : substring) = (string, start, length)

  fun string (substring : substring) = 
      P.substring (#string substring, #start substring, #length substring)

  fun extract (string, start, lengthOpt) =
      let
        val sizeOfString = P.size string
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

  fun full string =
      {string = string, start = 0, length = P.size string} : substring

  fun isEmpty (substring : substring) = (#length substring) = 0

  fun getc ({string, start, length} : substring) =
      if 0 = length
      then NONE
      else
        let
          val newSubstring =
              {string = string, start = start + 1, length = length - 1}
        in SOME(P.sub(string, start), newSubstring)
        end

  fun first ({string, start, length} : substring) =
      if length = 0 then NONE else SOME(P.sub (string, start))

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
      else P.sub (string, start + index)

  fun size ({string, length, ...} : substring) = length

  fun concat [] = P.emptyString
    | concat (substring :: substrings) =
      let
        fun append [] result = result
          | append (head :: tail) result =
            append tail (P.concat2 (result, string head))
      in append substrings (string substring)
      end

  fun concatWith separator [] = P.emptyString
    | concatWith separator (substring :: substrings) =
      let
        fun append [] result = result
          | append (head :: tail) result =
            append tail (P.concat2 (result, P.concat2(separator, string head)))
      in append substrings (string substring)
      end

  fun explode ({string, start, length} : substring) =
    let
      fun accum 0 chars = chars
        | accum n chars =
          accum (n - 1) (P.sub (string, start + n - 1) :: chars)
    in accum length [] end

  local
    fun match (string1, index1, substring2, index2, size) =
        let
          fun scan index =
              if size <= index
              then true
              else 
                case
                  P.compareChar
                      (
                        P.sub (string1, index1 + index),
                        sub (substring2, index2 + index)
                      )
                 of EQUAL => scan (index + 1)
                  | _ => false
        in
          scan 0
        end
  in
  fun isPrefix string1 substring2 =
      let
        val size1 = P.size string1
        val size2 = size substring2
      in
        if size2 < size1
        then false
        else match (string1, 0, substring2, 0, size1)
      end

  fun isSubstring string1 substring2 =
      let
        val size1 = P.size string1
        val size2 = size substring2
        fun scan index =
            if size2 < index + size1
            then false
            else
              if match (string1, 0, substring2, index, size1)
              then true
              else scan (index + 1)
      in
        scan 0
      end

  fun isSuffix string1 substring2 =
      let
        val size1 = P.size string1
        val size2 = size substring2
      in
        if size2 < size1
        then false
        else match (string1, 0, substring2, size2 - size1, size1)
      end
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
                val leftChar = P.sub (leftString, leftStart + index)
                val rightChar = P.sub (rightString, rightStart + index)
              in
                case charCollate (leftChar, rightChar) of
                  EQUAL => scan (index + 1)
                | notEqual => notEqual
              end
      in
        scan 0
      end
        
  fun compare arg = collate P.compareChar arg

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
              if predicate (P.sub (string, start + index))
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
              if predicate (P.sub (string, start + index))
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
              if predicate (P.sub (string, start + index))
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
              if predicate (P.sub (string, start + index))
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
              if predicate (P.sub (string, start + index))
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
              if predicate (P.sub (string, start + index))
              then scan (index - 1)
              else index
        val index = (scan (length - 1)) + 1 (* the left-most index of right *)
      in {string = string, start = start + index, length = length - index}
      end

  fun position string (substring : substring) =
      let
        val sizeOfString = P.size string
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
      if
        EQUAL <> P.compare (leftString, rightString)
        orelse rightStart + rightLength < leftStart
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
                    transChar (P.sub (string, start + index))
              in
                scan (index + 1) (P.concat2 (accum, translated))
              end
      in scan 0 P.emptyString
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
                if isDelimiter (P.sub (string, start + index))
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
                    folder (P.sub(string, start + index), accum)
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
                    folder (P.sub(string, start + index), accum)
              in scan (index - 1) newAccum
              end
      in scan (length - 1) initial
      end

  fun app f ({string, start, length} : substring) =
      let
        fun scan index =
            if index = length
            then ()
            else (f (P.sub(string, start + index)); scan (index + 1))
      in scan 0
      end

  (***************************************************************************)

end
end

