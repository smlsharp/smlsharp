(*
test cases for Int structure.
*)

val maxWord = Word.fromLargeWord (0wxFFFFFFFF : LargeWord.word);

val toLargeWord_0 = Word.toLargeWord 0w0;
val toLargeWord_123 = Word.toLargeWord 0wx123;
val toLargeWord_7FFFFFFF = Word.toLargeWord 0wx7FFFFFFF;

val toLargeWordX_0 = Word.toLargeWordX 0w0;
val toLargeWordX_123 = Word.toLargeWordX 0wx123;
val toLargeWordX_7FFFFFFF = Word.toLargeWordX 0wx7FFFFFFF;

val fromLargeWord_0 = Word.fromLargeWord 0w0;
val fromLargeWord_123 = Word.fromLargeWord 0w123;
val fromLargeWord_7FFFFFFF = Word.fromLargeWord 0wx7FFFFFFF;
val fromLargeWord_FFFFFFFF = Word.fromLargeWord (0wxFFFFFFFF : LargeWord.word);

val toLargeInt_0 = Word.toLargeInt 0w0;
val toLargeInt_7FFFFFFF = Word.toLargeInt 0wx7FFFFFFF;
val toLargeInt_FFFFFFFF =
    (Word.toLargeInt (Word.fromLargeWord (0wxFFFFFFFF : LargeWord.word)))
    handle General.Overflow => 1;

val toLargeIntX_0 = Word.toLargeIntX 0w0;
val toLargeIntX_7FFFFFFF = Word.toLargeIntX 0wx7FFFFFFF;
val toLargeIntX_FFFFFFFF =
    Word.toLargeIntX (Word.fromLargeWord (0wxFFFFFFFF : LargeWord.word));

val fromLargeInt_0 = Word.fromLargeInt 0;
val fromLargeInt_123 = Word.fromLargeInt 123;
val fromLargeInt_m123 = Word.fromLargeInt ~123;
val fromLargeInt_7FFFFFFF = Word.fromLargeInt (0x7FFFFFFF : LargeInt.int);
val fromLargeInt_FFFFFFFF = Word.fromLargeInt (~1 : LargeInt.int);

val orb_0_0 = Word.orb (0w0, 0w0);
val orb_F0_0F = Word.orb (0wxF0, 0wx0F);
val orb_0F_0F = Word.orb (0wx0F, 0wx0F);

val xorb_0_0 = Word.xorb (0w0, 0w0);
val xorb_F0_0F = Word.xorb (0wxF0, 0wx0F);
val xorb_0F_0F = Word.xorb (0wx0F, 0wx0F);

val andb_0_0 = Word.andb (0w0, 0w0);
val andb_F0_0F = Word.andb (0wxF0, 0wx0F);
val andb_0F_0F = Word.andb (0wx0F, 0wx0F);

val notb_0 = Word.notb 0w0;
val notb_F0 = Word.notb 0wxF0;

val leftShift_0_0 = Word.<< (0w0, 0w0);
val leftShift_1_0 = Word.<< (0w1, 0w0);
val leftShift_1_1 = Word.<< (0w1, 0w1);
val leftShift_1_2 = Word.<< (0w1, 0w2);
val leftShift_1_max_m1 = Word.<< (0w1, Word.fromInt(Word.wordSize - 1));
val leftShift_1_max = Word.<< (0w1, Word.fromInt Word.wordSize);
val leftShift_FF_1 = Word.<< (0wxFF, 0w1);
val leftShift_FF_2 = Word.<< (0wxFF, 0w2);
val leftShift_FF_max_m1 = Word.<< (0wxFF, Word.fromInt(Word.wordSize - 1));
val leftShift_FF_max = Word.<< (0wxFF, Word.fromInt Word.wordSize);

val logicalRightShift_0_0 = Word.>> (0w0, 0w0);
val logicalRightShift_1_0 = Word.>> (0w1, 0w0);
val logicalRightShift_1_1 = Word.>> (0w1, 0w1);
val logicalRightShift_2_1 = Word.>> (0w2, 0w1);
val logicalRightShift_max_1 = Word.>> (maxWord, 0w1);
val logicalRightShift_max_max_m1 =
    Word.>> (maxWord, Word.fromInt(Word.wordSize - 1));
val logicalRightShift_max_max = Word.>> (maxWord, Word.fromInt Word.wordSize);

val arithmeticRightShift_0_0 = Word.~>> (0w0, 0w0);
val arithmeticRightShift_1_0 = Word.~>> (0w1, 0w0);
val arithmeticRightShift_1_1 = Word.~>> (0w1, 0w1);
val arithmeticRightShift_2_1 = Word.~>> (0w2, 0w1);
val arithmeticRightShift_max_1 = Word.~>> (maxWord, 0w1);
val arithmeticRightShift_max_max_m1 =
    Word.~>> (maxWord, Word.fromInt(Word.wordSize - 1));
val arithmeticRightShift_max_max =
    Word.~>> (maxWord, Word.fromInt Word.wordSize);

val add_pp = Word.+ (0w8, 0w3);
val add_zp = Word.+ (0w0, 0w3);
val add_pz = Word.+ (0w8, 0w0);
val add_zz = Word.+ (0w0, 0w0);

val sub_pp = Word.- (0w8, 0w3);
val sub_zp = Word.- (0w0, 0w3);
val sub_pz = Word.- (0w8, 0w0);
val sub_zz = Word.- (0w0, 0w0);

val mul_pp = Word.* (0w2, 0w3);
val mul_zp = Word.* (0w0, 0w3);
val mul_pz = Word.* (0w3, 0w0);
val mul_zz = Word.* (0w0, 0w0);

val div_pp = Word.div (0w8, 0w3);
val div_zp = Word.div (0w0, 0w3);
(*
val div_pz = (Word.div (0w8, 0w0)) handle General.Div => 1;
val div_zz = (Word.div (0w0, 0w0)) handle General.Div => 1;
*)

val mod_pp = Word.mod (0w8, 0w3);
val mod_zp = Word.mod (0w0, 0w3);
(*
val mod_pz = (Word.mod (0w8, 0w0)) handle General.Div => 1;
val mod_zz = (Word.mod (0w0, 0w0)) handle General.Div => 1;
*)

val compare_ppL = Word.compare (0w3, 0w8);
val compare_ppE = Word.compare (0w8, 0w8);
val compare_ppG = Word.compare (0w8, 0w3);
val compare_zp = Word.compare (0w0, 0w3);
val compare_pz = Word.compare (0w8, 0w0);
val compare_zz = Word.compare (0w0, 0w0);

val gt_ppL = Word.> (0w3, 0w8);
val gt_ppE = Word.> (0w8, 0w8);
val gt_ppG = Word.> (0w8, 0w3);
val gt_zp = Word.> (0w0, 0w3);
val gt_pz = Word.> (0w8, 0w0);
val gt_zz = Word.> (0w0, 0w0);

val ge_ppL = Word.>= (0w3, 0w8);
val ge_ppE = Word.>= (0w8, 0w8);
val ge_ppG = Word.>= (0w8, 0w3);
val ge_zp = Word.>= (0w0, 0w3);
val ge_pz = Word.>= (0w8, 0w0);
val ge_zz = Word.>= (0w0, 0w0);

val lt_ppL = Word.< (0w3, 0w8);
val lt_ppE = Word.< (0w8, 0w8);
val lt_ppG = Word.< (0w8, 0w3);
val lt_zp = Word.< (0w0, 0w3);
val lt_pz = Word.< (0w8, 0w0);
val lt_zz = Word.< (0w0, 0w0);

val le_ppL = Word.<= (0w3, 0w8);
val le_ppE = Word.<= (0w8, 0w8);
val le_ppG = Word.<= (0w8, 0w3);
val le_zp = Word.<= (0w0, 0w3);
val le_pz = Word.<= (0w8, 0w0);
val le_zz = Word.<= (0w0, 0w0);

val min_ppL = Word.min (0w3, 0w8);
val min_ppE = Word.min (0w8, 0w8);
val min_ppG = Word.min (0w8, 0w3);
val min_zp = Word.min (0w0, 0w3);
val min_pz = Word.min (0w8, 0w0);
val min_zz = Word.min (0w0, 0w0);

val max_ppL = Word.max (0w3, 0w8);
val max_ppE = Word.max (0w8, 0w8);
val max_ppG = Word.max (0w8, 0w3);
val max_zp = Word.max (0w0, 0w3);
val max_pz = Word.max (0w8, 0w0);
val max_zz = Word.max (0w0, 0w0);

val fmt_bin_z = Word.fmt StringCvt.BIN 0w0;
val fmt_bin_p1 = Word.fmt StringCvt.BIN 0w1;
val fmt_bin_p2 = Word.fmt StringCvt.BIN 0w123;

val fmt_oct_z = Word.fmt StringCvt.OCT 0w0;
val fmt_oct_p1 = Word.fmt StringCvt.OCT 0w1
val fmt_oct_p2 = Word.fmt StringCvt.OCT 0w123;

val fmt_dec_z = Word.fmt StringCvt.DEC 0w0;
val fmt_dec_p1 = Word.fmt StringCvt.DEC 0w1
val fmt_dec_p2 = Word.fmt StringCvt.DEC 0w123;

val fmt_hex_z = Word.fmt StringCvt.HEX 0w0;
val fmt_hex_p1 = Word.fmt StringCvt.HEX 0w1
val fmt_hex_p2 = Word.fmt StringCvt.HEX 0w123;

val toString_z = Word.toString 0w0;
val toString_p1 = Word.toString 0w1
val toString_p2 = Word.toString 0w123;

val fromString_null = Word.fromString "";
val fromString_nonum = Word.fromString "ghi123def";
val fromString_z1 = Word.fromString "0";
val fromString_z2 = Word.fromString "0w00";
val fromString_z12 = Word.fromString "0ghi";
val fromString_p1 = Word.fromString "1abc";
val fromString_p12 = Word.fromString "0wx1abcghi";
val fromString_p2 = Word.fromString "123abc";
val fromString_p22 = Word.fromString "0wx123abcghi";

fun reader [] = NONE | reader (head :: tail) = SOME(head, tail);
fun scan radix string = Word.scan radix reader (explode string);
val scan_bin_null = scan StringCvt.BIN "";
val scan_bin_0 = scan StringCvt.BIN "0";
val scan_bin_01 = scan StringCvt.BIN "0w00";
val scan_bin_1 = scan StringCvt.BIN "1";
val scan_bin_1b = scan StringCvt.BIN "0w1abcghi";
val scan_bin_1c = scan StringCvt.BIN "01";

val scan_oct_null = scan StringCvt.OCT "";
val scan_oct_0 = scan StringCvt.OCT "0";
val scan_oct_01 = scan StringCvt.OCT "0w00";
val scan_oct_1 = scan StringCvt.OCT "123";
val scan_oct_1b = scan StringCvt.OCT "0w12389a";
val scan_oct_1c = scan StringCvt.OCT "0123";

val scan_dec_null = scan StringCvt.DEC "";
val scan_dec_0 = scan StringCvt.DEC "0";
val scan_dec_01 = scan StringCvt.DEC "0w00";
val scan_dec_1 = scan StringCvt.DEC "123";
val scan_dec_1b = scan StringCvt.DEC "0w12389a";
val scan_dec_1c = scan StringCvt.DEC "0123";

val scan_hex_null = scan StringCvt.HEX "";
val scan_hex_head1 = scan StringCvt.HEX "0wx ";
val scan_hex_head2 = scan StringCvt.HEX "0wX ";
val scan_hex_head3 = scan StringCvt.HEX "0x ";
val scan_hex_head4 = scan StringCvt.HEX "0X ";
val scan_hex_0 = scan StringCvt.HEX "0";
val scan_hex_01 = scan StringCvt.HEX "00";
val scan_hex_0h1 = scan StringCvt.HEX "0wx0";
val scan_hex_0h2 = scan StringCvt.HEX "0wX0";
val scan_hex_0h3 = scan StringCvt.HEX "0x0";
val scan_hex_0h4 = scan StringCvt.HEX "0X0";
val scan_hex_1 = scan StringCvt.HEX "123";
val scan_hex_1b = scan StringCvt.HEX "12AaFfGg";
val scan_hex_1b_h1 = scan StringCvt.HEX "0wx12AaFfGg";
val scan_hex_1b_h2 = scan StringCvt.HEX "0wX12AaFfGg";
val scan_hex_1b_h3 = scan StringCvt.HEX "0x12AaFfGg";
val scan_hex_1b_h4 = scan StringCvt.HEX "0X12AaFfGg";
val scan_hex_1c = scan StringCvt.HEX "0123";

val scan_skipWS1 = scan StringCvt.DEC "  123";
val scan_skipWS2 = scan StringCvt.DEC "\t\n\v\f\r123";
