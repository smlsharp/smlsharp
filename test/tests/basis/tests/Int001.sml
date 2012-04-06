(*
test cases for Int structure.
*)
val tilda_m = Int.~ (0 - 1);
val tilda_z = Int.~ (1 - 1);
val tilda_p = Int.~ (0 + 1);

val mul_mm = Int.* (~2, ~3);
val mul_mp = Int.* (~2, 3);
val mul_pm = Int.* (2, ~3);
val mul_pp = Int.* (2, 3);
val mul_zp = Int.* (0, 3);
val mul_pz = Int.* (3, 0);
val mul_zz = Int.* (0, 0);

val div_mm = Int.div (~8, ~3);
val div_mp = Int.div (~8, 3);
val div_pm = Int.div (8, ~3);
val div_pp = Int.div (8, 3);
val div_zp = Int.div (0, 3);
(*
val div_pz = (Int.div (8, 0)) handle General.Div => 1;
val div_zz = (Int.div (0, 0)) handle General.Div => 1;
*)

val mod_mm = Int.mod (~8, ~3);
val mod_mp = Int.mod (~8, 3);
val mod_pm = Int.mod (8, ~3);
val mod_pp = Int.mod (8, 3);
val mod_zp = Int.mod (0, 3);
(*
val mod_pz = (Int.mod (8, 0)) handle General.Div => 1;
val mod_zz = (Int.mod (0, 0)) handle General.Div => 1;
*)

val quot_mm = Int.quot (~8, ~3);
val quot_mp = Int.quot (~8, 3);
val quot_pm = Int.quot (8, ~3);
val quot_pp = Int.quot (8, 3);
val quot_zp = Int.quot (0, 3);
(*
val quot_pz = (Int.quot (8, 0)) handle General.Div => 1;
val quot_zz = (Int.quot (0, 0)) handle General.Div => 1;
*)

val rem_mm = Int.rem (~8, ~3);
val rem_mp = Int.rem (~8, 3);
val rem_pm = Int.rem (8, ~3);
val rem_pp = Int.rem (8, 3);
val rem_zp = Int.rem (0, 3);
(*
val rem_pz = (Int.rem (8, 0)) handle General.Div => 1;
val rem_zz = (Int.rem (0, 0)) handle General.Div => 1;
*)

val add_mm = Int.+ (~8, ~3);
val add_mp = Int.+ (~8, 3);
val add_pm = Int.+ (8, ~3);
val add_pp = Int.+ (8, 3);
val add_zp = Int.+ (0, 3);
val add_pz = Int.+ (8, 0);
val add_zz = Int.+ (0, 0);

val sub_mm = Int.- (~8, ~3);
val sub_mp = Int.- (~8, 3);
val sub_pm = Int.- (8, ~3);
val sub_pp = Int.- (8, 3);
val sub_zp = Int.- (0, 3);
val sub_pz = Int.- (8, 0);
val sub_zz = Int.- (0, 0);

val compare_mmL = Int.compare (~8, ~3);
val compare_mmE = Int.compare (~8, ~8);
val compare_mmG = Int.compare (~3, ~8);
val compare_mp = Int.compare (~8, 3);
val compare_pm = Int.compare (8, ~3);
val compare_ppL = Int.compare (3, 8);
val compare_ppE = Int.compare (8, 8);
val compare_ppG = Int.compare (8, 3);
val compare_zp = Int.compare (0, 3);
val compare_pz = Int.compare (8, 0);
val compare_zz = Int.compare (0, 0);

val gt_mmL = Int.> (~8, ~3);
val gt_mmE = Int.> (~8, ~8);
val gt_mmG = Int.> (~3, ~8);
val gt_mp = Int.> (~8, 3);
val gt_pm = Int.> (8, ~3);
val gt_ppL = Int.> (3, 8);
val gt_ppE = Int.> (8, 8);
val gt_ppG = Int.> (8, 3);
val gt_zp = Int.> (0, 3);
val gt_pz = Int.> (8, 0);
val gt_zz = Int.> (0, 0);

val ge_mmL = Int.>= (~8, ~3);
val ge_mmE = Int.>= (~8, ~8);
val ge_mmG = Int.>= (~3, ~8);
val ge_mp = Int.>= (~8, 3);
val ge_pm = Int.>= (8, ~3);
val ge_ppL = Int.>= (3, 8);
val ge_ppE = Int.>= (8, 8);
val ge_ppG = Int.>= (8, 3);
val ge_zp = Int.>= (0, 3);
val ge_pz = Int.>= (8, 0);
val ge_zz = Int.>= (0, 0);

val lt_mmL = Int.< (~8, ~3);
val lt_mmE = Int.< (~8, ~8);
val lt_mmG = Int.< (~3, ~8);
val lt_mp = Int.< (~8, 3);
val lt_pm = Int.< (8, ~3);
val lt_ppL = Int.< (3, 8);
val lt_ppE = Int.< (8, 8);
val lt_ppG = Int.< (8, 3);
val lt_zp = Int.< (0, 3);
val lt_pz = Int.< (8, 0);
val lt_zz = Int.< (0, 0);

val le_mmL = Int.<= (~8, ~3);
val le_mmE = Int.<= (~8, ~8);
val le_mmG = Int.<= (~3, ~8);
val le_mp = Int.<= (~8, 3);
val le_pm = Int.<= (8, ~3);
val le_ppL = Int.<= (3, 8);
val le_ppE = Int.<= (8, 8);
val le_ppG = Int.<= (8, 3);
val le_zp = Int.<= (0, 3);
val le_pz = Int.<= (8, 0);
val le_zz = Int.<= (0, 0);

val abs_m = Int.abs (0 - 1);
val abs_z = Int.abs 0;
val abs_p = Int.abs 1;

val min_mmL = Int.min (~8, ~3);
val min_mmE = Int.min (~8, ~8);
val min_mmG = Int.min (~3, ~8);
val min_mp = Int.min (~8, 3);
val min_pm = Int.min (8, ~3);
val min_ppL = Int.min (3, 8);
val min_ppE = Int.min (8, 8);
val min_ppG = Int.min (8, 3);
val min_zp = Int.min (0, 3);
val min_pz = Int.min (8, 0);
val min_zz = Int.min (0, 0);

val max_mmL = Int.max (~8, ~3);
val max_mmE = Int.max (~8, ~8);
val max_mmG = Int.max (~3, ~8);
val max_mp = Int.max (~8, 3);
val max_pm = Int.max (8, ~3);
val max_ppL = Int.max (3, 8);
val max_ppE = Int.max (8, 8);
val max_ppG = Int.max (8, 3);
val max_zp = Int.max (0, 3);
val max_pz = Int.max (8, 0);
val max_zz = Int.max (0, 0);

val sign_m = Int.sign (0 - 1);
val sign_z = Int.sign 0;
val sign_p = Int.sign 1;

val sameSign_mm = Int.sameSign (~1, ~2);
val sameSign_mz = Int.sameSign (~1, 0);
val sameSign_mp = Int.sameSign (~1, 2);
val sameSign_zm = Int.sameSign (0, ~2);
val sameSign_zz = Int.sameSign (0, 0);
val sameSign_zp = Int.sameSign (0, 2);
val sameSign_pm = Int.sameSign (1, ~2);
val sameSign_pz = Int.sameSign (1, 0);
val sameSign_pp = Int.sameSign (1, 2);

val fmt_bin_m1 = Int.fmt StringCvt.BIN ~1;
val fmt_bin_m2 = Int.fmt StringCvt.BIN ~123;
val fmt_bin_z = Int.fmt StringCvt.BIN 0;
val fmt_bin_p1 = Int.fmt StringCvt.BIN 1;
val fmt_bin_p2 = Int.fmt StringCvt.BIN 123;

val fmt_oct_m1 = Int.fmt StringCvt.OCT ~1;
val fmt_oct_m2 = Int.fmt StringCvt.OCT ~123;
val fmt_oct_z = Int.fmt StringCvt.OCT 0;
val fmt_oct_p1 = Int.fmt StringCvt.OCT 1;
val fmt_oct_p2 = Int.fmt StringCvt.OCT 123;

val fmt_dec_m1 = Int.fmt StringCvt.DEC ~1;
val fmt_dec_m2 = Int.fmt StringCvt.DEC ~123;
val fmt_dec_z = Int.fmt StringCvt.DEC 0;
val fmt_dec_p1 = Int.fmt StringCvt.DEC 1;
val fmt_dec_p2 = Int.fmt StringCvt.DEC 123;

val fmt_hex_m1 = Int.fmt StringCvt.HEX ~1;
val fmt_hex_m2 = Int.fmt StringCvt.HEX ~123;
val fmt_hex_z = Int.fmt StringCvt.HEX 0;
val fmt_hex_p1 = Int.fmt StringCvt.HEX 1;
val fmt_hex_p2 = Int.fmt StringCvt.HEX 123;

val toString_m1 = Int.toString ~1;
val toString_m2 = Int.toString ~123;
val toString_z = Int.toString 0;
val toString_p1 = Int.toString 1;
val toString_p2 = Int.toString 123;

val fromString_null = Int.fromString "";
val fromString_nonum = Int.fromString "abc123def";
val fromString_m1 = Int.fromString "~1";
val fromString_m12 = Int.fromString "~1abc";
val fromString_m2 = Int.fromString "~123";
val fromString_m22 = Int.fromString "~123abc";
val fromString_z1 = Int.fromString "0";
val fromString_z12 = Int.fromString "00";
val fromString_z12 = Int.fromString "00abc";
val fromString_p1 = Int.fromString "1";
val fromString_p12 = Int.fromString "1abc";
val fromString_p2 = Int.fromString "123";
val fromString_p22 = Int.fromString "123abc";

fun reader [] = NONE | reader (head :: tail) = SOME(head, tail);
fun scan radix string = Int.scan radix reader (explode string);
val scan_bin_null = scan StringCvt.BIN "";
val scan_bin_0 = scan StringCvt.BIN "0";
val scan_bin_01 = scan StringCvt.BIN "00";
val scan_bin_p0 = scan StringCvt.BIN "+0";
val scan_bin_t0 = scan StringCvt.BIN "~0";
val scan_bin_m0 = scan StringCvt.BIN "-0";
val scan_bin_t1 = scan StringCvt.BIN "~1";
val scan_bin_t1b = scan StringCvt.BIN "~1abc";
val scan_bin_t1c = scan StringCvt.BIN "~01";
val scan_bin_m1 = scan StringCvt.BIN "-1";
val scan_bin_m1b = scan StringCvt.BIN "-1abc";
val scan_bin_m1c = scan StringCvt.BIN "-01";
val scan_bin_p1 = scan StringCvt.BIN "+1";
val scan_bin_p1b = scan StringCvt.BIN "+1abc";
val scan_bin_p1c = scan StringCvt.BIN "+01";
val scan_bin_1 = scan StringCvt.BIN "1";
val scan_bin_1b = scan StringCvt.BIN "1abc";
val scan_bin_1c = scan StringCvt.BIN "01";

val scan_oct_null = scan StringCvt.OCT "";
val scan_oct_0 = scan StringCvt.OCT "0";
val scan_oct_01 = scan StringCvt.OCT "00";
val scan_oct_p0 = scan StringCvt.OCT "+0";
val scan_oct_t0 = scan StringCvt.OCT "~0";
val scan_oct_m0 = scan StringCvt.OCT "-0";
val scan_oct_t1 = scan StringCvt.OCT "~123";
val scan_oct_t1b = scan StringCvt.OCT "~12389a";
val scan_oct_t1c = scan StringCvt.OCT "~0123";
val scan_oct_m1 = scan StringCvt.OCT "-123";
val scan_oct_m1b = scan StringCvt.OCT "-12389a";
val scan_oct_m1c = scan StringCvt.OCT "-0123";
val scan_oct_p1 = scan StringCvt.OCT "+123";
val scan_oct_p1b = scan StringCvt.OCT "+12389a";
val scan_oct_p1c = scan StringCvt.OCT "+0123";
val scan_oct_1 = scan StringCvt.OCT "123";
val scan_oct_1b = scan StringCvt.OCT "12389a";
val scan_oct_1c = scan StringCvt.OCT "0123";

val scan_dec_null = scan StringCvt.DEC "";
val scan_dec_0 = scan StringCvt.DEC "0";
val scan_dec_01 = scan StringCvt.DEC "00";
val scan_dec_p0 = scan StringCvt.DEC "+0";
val scan_dec_t0 = scan StringCvt.DEC "~0";
val scan_dec_m0 = scan StringCvt.DEC "-0";
val scan_dec_t1 = scan StringCvt.DEC "~123";
val scan_dec_t1b = scan StringCvt.DEC "~12389a";
val scan_dec_t1c = scan StringCvt.DEC "~0123";
val scan_dec_m1 = scan StringCvt.DEC "-123";
val scan_dec_m1b = scan StringCvt.DEC "-12389a";
val scan_dec_m1c = scan StringCvt.DEC "-0123";
val scan_dec_p1 = scan StringCvt.DEC "+123";
val scan_dec_p1b = scan StringCvt.DEC "+12389a";
val scan_dec_p1c = scan StringCvt.DEC "+0123";
val scan_dec_1 = scan StringCvt.DEC "123";
val scan_dec_1b = scan StringCvt.DEC "12389a";
val scan_dec_1c = scan StringCvt.DEC "0123";

val scan_hex_null = scan StringCvt.HEX "";
val scan_hex_head1 = scan StringCvt.HEX "0x ";
val scan_hex_head2 = scan StringCvt.HEX "0X ";
val scan_hex_0 = scan StringCvt.HEX "0";
val scan_hex_01 = scan StringCvt.HEX "00";
val scan_hex_0h1 = scan StringCvt.HEX "0x0";
val scan_hex_0h2 = scan StringCvt.HEX "0X0";
val scan_hex_p0 = scan StringCvt.HEX "+0";
val scan_hex_p0h1 = scan StringCvt.HEX "+0x0";
val scan_hex_p0h2 = scan StringCvt.HEX "+0X0";
val scan_hex_t0 = scan StringCvt.HEX "~0";
val scan_hex_m0 = scan StringCvt.HEX "-0";
val scan_hex_t1 = scan StringCvt.HEX "~123";
val scan_hex_t1b = scan StringCvt.HEX "~12AaFfGg";
val scan_hex_t1b_h1 = scan StringCvt.HEX "~0x12AaFfGg";
val scan_hex_t1b_h2 = scan StringCvt.HEX "~0X12AaFfGg";
val scan_hex_t1c = scan StringCvt.HEX "~0123";
val scan_hex_m1 = scan StringCvt.HEX "-123";
val scan_hex_m1b = scan StringCvt.HEX "-12AaFfGg";
val scan_hex_m1b_h1 = scan StringCvt.HEX "-0x12AaFfGg";
val scan_hex_m1b_h2 = scan StringCvt.HEX "-0X12AaFfGg";
val scan_hex_m1c = scan StringCvt.HEX "-0123";
val scan_hex_p1 = scan StringCvt.HEX "+123";
val scan_hex_p1b = scan StringCvt.HEX "+12AaFfGg";
val scan_hex_p1b_h1 = scan StringCvt.HEX "+0x12AaFfGg";
val scan_hex_p1b_h2 = scan StringCvt.HEX "+0X12AaFfGg";
val scan_hex_p1c = scan StringCvt.HEX "+0123";
val scan_hex_1 = scan StringCvt.HEX "123";
val scan_hex_1b = scan StringCvt.HEX "12AaFfGg";
val scan_hex_1b_h1 = scan StringCvt.HEX "0x12AaFfGg";
val scan_hex_1b_h2 = scan StringCvt.HEX "0X12AaFfGg";
val scan_hex_1c = scan StringCvt.HEX "0123";

val scan_skipWS1 = scan StringCvt.DEC "  123";
val scan_skipWS2 = scan StringCvt.DEC "\t\n\v\f\r123";
