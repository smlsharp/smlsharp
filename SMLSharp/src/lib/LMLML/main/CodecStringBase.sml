(**
 * functor to generate a codec-specific String structure.
 * @author YAMATODANI Kiyoshi
 * @version $Id: CodecStringBase.sml,v 1.2.28.5 2010/05/11 07:08:03 kiyoshiy Exp $
 *)
functor CodecStringBase(P : PRIM_CODEC) : MULTI_BYTE_STRING =
struct

  structure BV = Word8Vector
  structure BVS = Word8VectorSlice

  type string = P.string

  type char = P.char

  val MBSToBytesSlice = P.encode

  val MBSToBytes = BVS.vector o MBSToBytesSlice

  val MBSToString = Byte.bytesToString o MBSToBytes

  val bytesSliceToMBS = P.decode

  val bytesToMBS = bytesSliceToMBS o BVS.full

  val stringToMBS = bytesToMBS o Byte.stringToBytes

(*
  fun convert toCodecName string =
      P.convert toCodecName string
      handle Codecs.ConverterNotFound =>
             let
               val fromCodecName = hd P.names
               val bytes = P.encode string
             IConv.conv {from = fromCodecName, to = toCodecName} 
*)
  val maxSize = P.maxSize

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

  val fromAsciiString = implode o (List.map P.fromAsciiChar) o String.explode

  val toAsciiString = 
      String.implode
      o List.map (fn c => Option.getOpt(P.toAsciiChar c, #"?"))
      o explode

  local
    fun fromStringBase converter cstring =
        (* Sequences of ASCII characters may contain C-escape sequences,
         * each of which shoule be converted to a character.
         * So, we discriminate between sequences of ASCII characters and
         * sequences of non-ASCII (= multi-byte) characters.
         *)
        (* This function converts between String.string and multibyte string
         * a few times, which is inefficient.
         * A possible improvement is to change PrimCodec to provide
         * a scanner function which moves a cursor on a String.string forward
         * by one multibyte character while decoding.
         *)
        let
          val string = stringToMBS cstring
          val len = size string
          (* @param start the index of the first character of the current
           *          sequence of ASCII characters.
           * @param index the current index.
           * @param strings a list of converted sequences in reverse order.
           *)
          fun inASCIIs start index strings =
              (* in a sequence of ASCII characters. *)
              if index < len andalso P.isAscii (P.sub (string, index))
              then inASCIIs start (index + 1) strings
              else
                (* found the end of the sequence of ASCII characters. *)
                case
                  (converter o toAsciiString)
                      (P.substring (string, start, index - start))
                 of SOME(asciis) =>
                    let val strings' = (fromAsciiString asciis) :: strings
                    in
                      if index = len
                      then SOME(index, strings')
                      else inNonASCIIs index (index + 1) strings'
                    end
                  | NONE => (* The sequence starts with an invalid escape. *)
                    if 0 = start then NONE else SOME(start, strings)
          and inNonASCIIs start index strings =
              (* in a sequence of non-ASCII characters. *)
              if index < len
              then
                if P.isAscii (P.sub (string, index))
                then 
                  (* found the end of the sequence of non-ASCII characters. *)
                  let
                    val strings' =
                        P.substring (string, start, index - start) :: strings
                  in inASCIIs index (index + 1) strings'
                  end
                else inNonASCIIs start (index + 1) strings
              else SOME(start, strings)
        in
          case inASCIIs 0 0 []
           of SOME(start, strings) =>
              SOME
                  ((concat (List.rev strings))
                   ^ P.substring (string, start, len - start))
            | NONE => NONE
        end

    fun toStringBase converter =
        String.concat
        o List.map
              (fn c =>
                  case P.toAsciiChar c
                   of SOME asciiChar => converter asciiChar
                    | NONE => (MBSToString o str) c)
              o explode

  in
  val fromString = fromStringBase String.fromString
  val toString = toStringBase Char.toString
  val fromCString = fromStringBase String.fromCString
  val toCString = toStringBase Char.toCString
  end

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

  val dump = P.dumpString

end