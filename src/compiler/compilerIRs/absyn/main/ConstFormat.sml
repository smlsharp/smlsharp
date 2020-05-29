(**
 * Constant formatters
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure ConstFormat =
struct

  fun term s = SMLFormat.FormatExpression.Term (size s, s)

  fun cminus str =
      String.map (fn #"~" => #"-" | x => x) str
  fun prepend prefix str =
      if String.isPrefix "~" str
      then "~" ^ prefix ^ String.extract (str, 1, NONE)
      else prefix ^ str
  fun toLower str =
      String.map Char.toLower str

  fun format_dec_MLi fmt x =
      [term (fmt StringCvt.DEC x)]
  fun format_dec_MLw fmt x =
      [term (prepend "0w" (fmt StringCvt.DEC x))]
  fun format_dec_C fmt x =
      [term (cminus (fmt StringCvt.DEC x))]
  fun format_hex_MLi fmt x =
      [term (prepend "0x" (toLower (fmt StringCvt.HEX x)))]
  fun format_hex_MLw fmt x =
      [term (prepend "0wx" (toLower (fmt StringCvt.HEX x)))]
  fun format_hex_C fmt x =
      [term (cminus (prepend "0x" (toLower (fmt StringCvt.HEX x))))]

  fun format_intInf_dec_ML x = format_dec_MLi IntInf.fmt x
  fun format_intInf_word_ML x = format_hex_MLw IntInf.fmt x
  fun format_int64_dec_ML x = format_dec_MLi Int64.fmt x
  fun format_int32_dec_ML x = format_dec_MLi Int32.fmt x
  fun format_int16_dec_ML x = format_dec_MLi Int16.fmt x
  fun format_int8_dec_ML x = format_dec_MLi Int8.fmt x
  fun format_int_dec_ML x = format_dec_MLi Int.fmt x
  fun format_word64_hex_ML x = format_hex_MLw Word64.fmt x
  fun format_word32_hex_ML x = format_hex_MLw Word32.fmt x
  fun format_word16_hex_ML x = format_hex_MLw Word16.fmt x
  fun format_word8_hex_ML x = format_hex_MLw Word8.fmt x
  fun format_word_hex_ML x = format_hex_MLw Word.fmt x
  fun format_real64_ML x = [term (Real64.fmt StringCvt.EXACT x)]
  fun format_real32_ML x = [term (Real32.fmt StringCvt.EXACT x)]
  fun format_int64_dec_C x = format_dec_C Int64.fmt x
  fun format_int32_dec_C x = format_dec_C Int32.fmt x
  fun format_int16_dec_C x = format_dec_C Int16.fmt x
  fun format_int8_dec_C x = format_dec_C Int8.fmt x
  fun format_int_dec_C x = format_dec_C Int.fmt x
  fun format_word64_hex_C x = format_hex_C Word64.fmt x
  fun format_word32_hex_C x = format_hex_C Word32.fmt x
  fun format_word16_hex_C x = format_hex_C Word16.fmt x
  fun format_word8_hex_C x = format_hex_C Word8.fmt x
  fun format_word_hex_C x = format_hex_C Word.fmt x
  fun format_real64_C x = [term (Real64.fmt StringCvt.EXACT x)]
  fun format_real32_C x = [term (Real32.fmt StringCvt.EXACT x ^ "f")]

  fun oct3 i = StringCvt.padLeft #"0" 3 (Int.fmt StringCvt.OCT i)

  fun escapeC s =
      String.translate
        (fn #"\008" => "\\b"
          | #"\012" => "\\f"
          | #"\010" => "\\n"
          | #"\013" => "\\r"
          | #"\009" => "\\t"
          | #"\092" => "\\\\"
          | #"\034" => "\\\""
          | c => if ord c < 128 andalso Char.isPrint c then str c
                 else "\\" ^ oct3 (ord c))
        s

  fun format_string_ML s = [term ("\"" ^ String.toString s ^ "\"")]
  fun format_string_C s = [term ("\"" ^ escapeC s ^ "\"")]
  fun format_char_ML c = [term ("#\"" ^ Char.toString c ^ "\"")]
  fun format_char_C #"\034" = [term "'\"'"]
    | format_char_C c = [term ("'" ^ escapeC (str c) ^ "'")]

end
