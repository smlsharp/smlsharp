structure MB = MultiByteString;
structure MBS = MB.String;
structure MBC = MB.Char;

(*****************************************************************************)

fun assert true = ()
  | assert false = raise Fail "fail";

fun remake encode = 
    MBS.implode o (map ((MBC.fromWord encode) o MBC.ordw)) o MBS.explode;

val utf8_text =
    (Byte.bytesToString o Word8Vector.fromList)
        [
          0wxE6, 0wxB2, 0wxB3, (* '河' *)
          0wxE8, 0wxB1, 0wx9A,  (* '豚' *)
          0wx20, (* ' ' *)
          0wx4D, (* 'M' *)
          0wx79 (* 'y' *)
        ];
val utf8_mbs = MBS.decodeString "utf-8" utf8_text;
val _ = assert (5 = MBS.size utf8_mbs);
val utf8_mbs' = remake "utf-8" utf8_mbs;
val _ = assert (EQUAL = MBS.compare (utf8_mbs, utf8_mbs'));

val utf16be_text =
    (Byte.bytesToString o Word8Vector.fromList)
        [
          0wx6C, 0wxB3, (* '河' *)
          0wx8C, 0wx5A,  (* '豚' *)
          0wx00, 0wx20, (* ' ' *)
          0wx00, 0wx4D, (* 'M' *)
          0wx00, 0wx79 (* 'y' *)
        ];
val utf16be_mbs = MBS.decodeString "utf-16be" utf16be_text;
val _ = assert (5 = MBS.size utf16be_mbs);
val _ = assert (false = MBC.isAscii(MBS.sub(utf16be_mbs, 0)));
val _ = assert (true = MBC.isAscii(MBS.sub(utf16be_mbs, 2)));
val utf16be_mbs' = remake "utf-16be" utf16be_mbs;
val _ = assert (EQUAL = MBS.compare (utf16be_mbs, utf16be_mbs'));

val utf16le_text =
    (Byte.bytesToString o Word8Vector.fromList)
        [
          0wxB3, 0wx6C, (* '河' *)
          0wx5A, 0wx8C,  (* '豚' *)
          0wx20, 0wx00, (* ' ' *)
          0wx4D, 0wx00, (* 'M' *)
          0wx79, 0wx00 (* 'y' *)
        ];
val utf16le_mbs = MBS.decodeString "utf-16le" utf16le_text;
val _ = assert (5 = MBS.size utf16le_mbs);
val _ = assert (false = MBC.isAscii(MBS.sub(utf16le_mbs, 0)));
val _ = assert (true = MBC.isAscii(MBS.sub(utf16le_mbs, 2)));
val utf16le_mbs' = remake "utf-16le" utf16le_mbs;
val _ = assert (EQUAL = MBS.compare (utf16le_mbs, utf16le_mbs'));

val utf16_text =
    (Byte.bytesToString o Word8Vector.fromList)
        [
          0wxFF, 0wxFE, (* little endian *)
          0wxB3, 0wx6C, (* '河' *)
          0wx5A, 0wx8C,  (* '豚' *)
          0wx20, 0wx00, (* ' ' *)
          0wx4D, 0wx00, (* 'M' *)
          0wx79, 0wx00 (* 'y' *)
        ];
val utf16_mbs = MBS.decodeString "utf-16" utf16_text;
val _ = assert (5 = MBS.size utf16_mbs);
val _ = assert (false = MBC.isAscii(MBS.sub(utf16_mbs, 0)));
val _ = assert (true = MBC.isAscii(MBS.sub(utf16_mbs, 2)));
val utf16_mbs' = remake "utf-16" utf16_mbs;
val _ = assert (EQUAL = MBS.compare (utf16_mbs, utf16_mbs'));

val iso2022jp_text =
    (Byte.bytesToString o Word8Vector.fromList)
        [
          0wx1B, 0wx24, 0wx42, (* <ESC> '$' 'B' *)
          0wx24, 0wx2B,  (* 'か' *)
          0wx24, 0wx4A,  (* 'な' *)
          0wx1B, 0wx28, 0wx42, (* <ESC> '(' 'B' *)
          0wx41, 0wx42, 0wx43, (* "ABC" *)
          0wx1B, 0wx24, 0wx42, (* <ESC> '$' 'B' *)
          0wx34, 0wx41,  (* '漢' *)
          0wx3B, 0wx7A,  (* '字' *)
          0wx1B, 0wx28, 0wx4A,   (* <ESC> '(' 'J' *)
          (* escape sequence for test *)
          0wx1B, 0wx24, 0wx42 (* <ESC> '$' 'B' *)
        ];

val iso2022jp_mbs = MBS.decodeString "iso-2022-jp" iso2022jp_text;
val _ = assert (7 = MBS.size iso2022jp_mbs);
(* 3 bytes of suffix must be appended to string to change to 1byte mode. *)
val _ = assert (23 = String.size (MBS.toString iso2022jp_mbs));
val iso2022jp_mbs' = remake "iso-2022-jp" iso2022jp_mbs;
val _ = assert (EQUAL = MBS.compare (iso2022jp_mbs, iso2022jp_mbs'));

val euc_jp_text =
    (Byte.bytesToString o Word8Vector.fromList)
        [
          0wxA4, 0wxAB,  (* 'か' *)
          0wxA4, 0wxCA,  (* 'な' *)
          0wx41, 0wx42, 0wx43, (* "ABC" *)
          0wxB4, 0wxC1,  (* '漢' *)
          0wxBB, 0wxFA   (* '字' *)
        ];
val euc_jp_mbs = MBS.decodeString "euc-jp" euc_jp_text;
val _ = assert (7 = MBS.size euc_jp_mbs);
val euc_jp_mbs' = remake "euc-jp" euc_jp_mbs;
val _ = assert (EQUAL = MBS.compare (euc_jp_mbs, euc_jp_mbs'));

val shiftjis_text =
    (Byte.bytesToString o Word8Vector.fromList)
        [
          0wx82, 0wxA9,  (* 'か' *)
          0wx82, 0wxC8,  (* 'な' *)
          0wx41, 0wx42, 0wx43, (* "ABC" *)
          0wx8A, 0wxBF,  (* '漢' *)
          0wx8E, 0wx9A   (* '字' *)
        ];
val shiftjis_mbs = MBS.decodeString "shift_jis" shiftjis_text;
val _ = assert (7 = MBS.size shiftjis_mbs);
val shiftjis_mbs' = remake "shift_jis" shiftjis_mbs;
val _ = assert (EQUAL = MBS.compare (shiftjis_mbs, shiftjis_mbs'));

(******************************************************************************)

(* for Windows *)
val encode = "Shift_JIS";
(* for unix *)
(*
val encode = "euc-jp";
*)
(*
val encode = "utf-8";
val encode = "GB2312";
*)
val _ = MB.setDefaultCodecName encode;

val mb_kuten = valOf(MBC.fromString "、");
val mb_comma = MBS.fromString ",";

val mbs =  MBS.decodeString encode "漢字、abc、ひらがな";

val _ =
    (print
     o MBS.toString
     o MBS.concatWith mb_comma
     o MBS.tokens (fn c => EQUAL = MBC.compare (mb_kuten, c)))
    mbs;

(****************************************)

val kanjiDigits =
    Vector.fromList
        (List.map
             (valOf o MBC.decodeString encode)
             ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九"]);

fun digitToKanji c =
    if MBC.isDigit c
    then Vector.sub(kanjiDigits, valOf(Int.fromString(MBC.toString c)))
    else c;

val exp = MBS.decodeString encode "1 + 2 - 3 * 10";

val _ = (print o MBS.toString o MBS.map digitToKanji) exp;
