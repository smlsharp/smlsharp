(*
test cases for Int structure.
*)
val tilda_m = IntInf.~ (0 - 1);
val tilda_z = IntInf.~ (1 - 1);
val tilda_p = IntInf.~ (0 + 1);

val mul_mm = IntInf.* (~2, ~3);
val mul_mp = IntInf.* (~2, 3);
val mul_pm = IntInf.* (2, ~3);
val mul_pp = IntInf.* (2, 3);
val mul_zp = IntInf.* (0, 3);
val mul_pz = IntInf.* (3, 0);
val mul_zz = IntInf.* (0, 0);

fun mul_c1_f x = (2 : IntInf.int) * x;
val mul_c1 = mul_c1_f 3;
fun mul_c2_f x = x * (4 : IntInf.int);
val mul_c2 = mul_c2_f 5;

val div_mm = IntInf.div (~8, ~3);
val div_mp = IntInf.div (~8, 3);
val div_pm = IntInf.div (8, ~3);
val div_pp = IntInf.div (8, 3);
val div_zp = IntInf.div (0, 3);
(*
val div_pz = (IntInf.div (8, 0)) handle General.Div => 1;
val div_zz = (IntInf.div (0, 0)) handle General.Div => 1;
*)
fun div_c1_f x = (2 : IntInf.int) div x;
val div_c1 = div_c1_f 3;
fun div_c2_f x = x div (4 : IntInf.int);
val div_c2 = div_c2_f 5;

val mod_mm = IntInf.mod (~8, ~3);
val mod_mp = IntInf.mod (~8, 3);
val mod_pm = IntInf.mod (8, ~3);
val mod_pp = IntInf.mod (8, 3);
val mod_zp = IntInf.mod (0, 3);
(*
val mod_pz = (IntInf.mod (8, 0)) handle General.Div => 1;
val mod_zz = (IntInf.mod (0, 0)) handle General.Div => 1;
*)
fun mod_c1_f x = (2 : IntInf.int) mod x;
val mod_c1 = mod_c1_f 3;
fun mod_c2_f x = x mod (4 : IntInf.int);
val mod_c2 = mod_c2_f 5;

val quot_mm = IntInf.quot (~8, ~3);
val quot_mp = IntInf.quot (~8, 3);
val quot_pm = IntInf.quot (8, ~3);
val quot_pp = IntInf.quot (8, 3);
val quot_zp = IntInf.quot (0, 3);
(*
val quot_pz = (IntInf.quot (8, 0)) handle General.Div => 1;
val quot_zz = (IntInf.quot (0, 0)) handle General.Div => 1;
*)

val rem_mm = IntInf.rem (~8, ~3);
val rem_mp = IntInf.rem (~8, 3);
val rem_pm = IntInf.rem (8, ~3);
val rem_pp = IntInf.rem (8, 3);
val rem_zp = IntInf.rem (0, 3);
(*
val rem_pz = (IntInf.rem (8, 0)) handle General.Div => 1;
val rem_zz = (IntInf.rem (0, 0)) handle General.Div => 1;
*)

val add_mm = IntInf.+ (~8, ~3);
val add_mp = IntInf.+ (~8, 3);
val add_pm = IntInf.+ (8, ~3);
val add_pp = IntInf.+ (8, 3);
val add_zp = IntInf.+ (0, 3);
val add_pz = IntInf.+ (8, 0);
val add_zz = IntInf.+ (0, 0);
fun add_c1_f x = (2 : IntInf.int) + x;
val add_c1 = add_c1_f 3;
fun add_c2_f x = x + (4 : IntInf.int);
val add_c2 = add_c2_f 5;

val sub_mm = IntInf.- (~8, ~3);
val sub_mp = IntInf.- (~8, 3);
val sub_pm = IntInf.- (8, ~3);
val sub_pp = IntInf.- (8, 3);
val sub_zp = IntInf.- (0, 3);
val sub_pz = IntInf.- (8, 0);
val sub_zz = IntInf.- (0, 0);
fun sub_c1_f x = (2 : IntInf.int) - x;
val sub_c1 = sub_c1_f 3;
fun sub_c2_f x = x - (4 : IntInf.int);
val sub_c2 = sub_c2_f 5;

val compare_mmL = IntInf.compare (~8, ~3);
val compare_mmE = IntInf.compare (~8, ~8);
val compare_mmG = IntInf.compare (~3, ~8);
val compare_mp = IntInf.compare (~8, 3);
val compare_pm = IntInf.compare (8, ~3);
val compare_ppL = IntInf.compare (3, 8);
val compare_ppE = IntInf.compare (8, 8);
val compare_ppG = IntInf.compare (8, 3);
val compare_zp = IntInf.compare (0, 3);
val compare_pz = IntInf.compare (8, 0);
val compare_zz = IntInf.compare (0, 0);

val gt_mmL = IntInf.> (~8, ~3);
val gt_mmE = IntInf.> (~8, ~8);
val gt_mmG = IntInf.> (~3, ~8);
val gt_mp = IntInf.> (~8, 3);
val gt_pm = IntInf.> (8, ~3);
val gt_ppL = IntInf.> (3, 8);
val gt_ppE = IntInf.> (8, 8);
val gt_ppG = IntInf.> (8, 3);
val gt_zp = IntInf.> (0, 3);
val gt_pz = IntInf.> (8, 0);
val gt_zz = IntInf.> (0, 0);
fun gt_c1_f x = (2 : IntInf.int) > x;
val gt_c1 = gt_c1_f 3;
fun gt_c2_f x = x > (4 : IntInf.int);
val gt_c2 = gt_c2_f 5;

val ge_mmL = IntInf.>= (~8, ~3);
val ge_mmE = IntInf.>= (~8, ~8);
val ge_mmG = IntInf.>= (~3, ~8);
val ge_mp = IntInf.>= (~8, 3);
val ge_pm = IntInf.>= (8, ~3);
val ge_ppL = IntInf.>= (3, 8);
val ge_ppE = IntInf.>= (8, 8);
val ge_ppG = IntInf.>= (8, 3);
val ge_zp = IntInf.>= (0, 3);
val ge_pz = IntInf.>= (8, 0);
val ge_zz = IntInf.>= (0, 0);
fun ge_c1_f x = (2 : IntInf.int) >= x;
val ge_c1 = ge_c1_f 3;
fun ge_c2_f x = x >= (4 : IntInf.int);
val ge_c2 = ge_c2_f 5;

val lt_mmL = IntInf.< (~8, ~3);
val lt_mmE = IntInf.< (~8, ~8);
val lt_mmG = IntInf.< (~3, ~8);
val lt_mp = IntInf.< (~8, 3);
val lt_pm = IntInf.< (8, ~3);
val lt_ppL = IntInf.< (3, 8);
val lt_ppE = IntInf.< (8, 8);
val lt_ppG = IntInf.< (8, 3);
val lt_zp = IntInf.< (0, 3);
val lt_pz = IntInf.< (8, 0);
val lt_zz = IntInf.< (0, 0);
fun lt_c1_f x = (2 : IntInf.int) < x;
val lt_c1 = lt_c1_f 3;
fun lt_c2_f x = x < (4 : IntInf.int);
val lt_c2 = lt_c2_f 5;

val le_mmL = IntInf.<= (~8, ~3);
val le_mmE = IntInf.<= (~8, ~8);
val le_mmG = IntInf.<= (~3, ~8);
val le_mp = IntInf.<= (~8, 3);
val le_pm = IntInf.<= (8, ~3);
val le_ppL = IntInf.<= (3, 8);
val le_ppE = IntInf.<= (8, 8);
val le_ppG = IntInf.<= (8, 3);
val le_zp = IntInf.<= (0, 3);
val le_pz = IntInf.<= (8, 0);
val le_zz = IntInf.<= (0, 0);
fun le_c1_f x = (2 : IntInf.int) <= x;
val le_c1 = le_c1_f 3;
fun le_c2_f x = x <= (4 : IntInf.int);
val le_c2 = le_c2_f 5;

val abs_m = IntInf.abs (0 - 1);
val abs_z = IntInf.abs 0;
val abs_p = IntInf.abs 1;

val min_mmL = IntInf.min (~8, ~3);
val min_mmE = IntInf.min (~8, ~8);
val min_mmG = IntInf.min (~3, ~8);
val min_mp = IntInf.min (~8, 3);
val min_pm = IntInf.min (8, ~3);
val min_ppL = IntInf.min (3, 8);
val min_ppE = IntInf.min (8, 8);
val min_ppG = IntInf.min (8, 3);
val min_zp = IntInf.min (0, 3);
val min_pz = IntInf.min (8, 0);
val min_zz = IntInf.min (0, 0);

val max_mmL = IntInf.max (~8, ~3);
val max_mmE = IntInf.max (~8, ~8);
val max_mmG = IntInf.max (~3, ~8);
val max_mp = IntInf.max (~8, 3);
val max_pm = IntInf.max (8, ~3);
val max_ppL = IntInf.max (3, 8);
val max_ppE = IntInf.max (8, 8);
val max_ppG = IntInf.max (8, 3);
val max_zp = IntInf.max (0, 3);
val max_pz = IntInf.max (8, 0);
val max_zz = IntInf.max (0, 0);

val sign_m = IntInf.sign (0 - 1);
val sign_z = IntInf.sign 0;
val sign_p = IntInf.sign 1;

val sameSign_mm = IntInf.sameSign (~1, ~2);
val sameSign_mz = IntInf.sameSign (~1, 0);
val sameSign_mp = IntInf.sameSign (~1, 2);
val sameSign_zm = IntInf.sameSign (0, ~2);
val sameSign_zz = IntInf.sameSign (0, 0);
val sameSign_zp = IntInf.sameSign (0, 2);
val sameSign_pm = IntInf.sameSign (1, ~2);
val sameSign_pz = IntInf.sameSign (1, 0);
val sameSign_pp = IntInf.sameSign (1, 2);

val fmt_bin_m1 = IntInf.fmt StringCvt.BIN ~1;
val fmt_bin_m2 = IntInf.fmt StringCvt.BIN ~123;
val fmt_bin_z = IntInf.fmt StringCvt.BIN 0;
val fmt_bin_p1 = IntInf.fmt StringCvt.BIN 1;
val fmt_bin_p2 = IntInf.fmt StringCvt.BIN 123;

val fmt_oct_m1 = IntInf.fmt StringCvt.OCT ~1;
val fmt_oct_m2 = IntInf.fmt StringCvt.OCT ~123;
val fmt_oct_z = IntInf.fmt StringCvt.OCT 0;
val fmt_oct_p1 = IntInf.fmt StringCvt.OCT 1;
val fmt_oct_p2 = IntInf.fmt StringCvt.OCT 123;

val fmt_dec_m1 = IntInf.fmt StringCvt.DEC ~1;
val fmt_dec_m2 = IntInf.fmt StringCvt.DEC ~123;
val fmt_dec_z = IntInf.fmt StringCvt.DEC 0;
val fmt_dec_p1 = IntInf.fmt StringCvt.DEC 1;
val fmt_dec_p2 = IntInf.fmt StringCvt.DEC 123;

val fmt_hex_m1 = IntInf.fmt StringCvt.HEX ~1;
val fmt_hex_m2 = IntInf.fmt StringCvt.HEX ~123;
val fmt_hex_z = IntInf.fmt StringCvt.HEX 0;
val fmt_hex_p1 = IntInf.fmt StringCvt.HEX 1;
val fmt_hex_p2 = IntInf.fmt StringCvt.HEX 123;

val toString_m1 = IntInf.toString ~1;
val toString_m2 = IntInf.toString ~123;
val toString_z = IntInf.toString 0;
val toString_p1 = IntInf.toString 1;
val toString_p2 = IntInf.toString 123;

val fromString_null = IntInf.fromString "";
val fromString_nonum = IntInf.fromString "abc123def";
val fromString_m1 = IntInf.fromString "~1";
val fromString_m12 = IntInf.fromString "~1abc";
val fromString_m2 = IntInf.fromString "~123";
val fromString_m22 = IntInf.fromString "~123abc";
val fromString_z1 = IntInf.fromString "0";
val fromString_z12 = IntInf.fromString "00";
val fromString_z12 = IntInf.fromString "00abc";
val fromString_p1 = IntInf.fromString "1";
val fromString_p12 = IntInf.fromString "1abc";
val fromString_p2 = IntInf.fromString "123";
val fromString_p22 = IntInf.fromString "123abc";

fun reader [] = NONE | reader (head :: tail) = SOME(head, tail);
fun scan radix string = IntInf.scan radix reader (explode string);
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
