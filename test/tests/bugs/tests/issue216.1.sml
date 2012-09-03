(* NOTE: this test case should be checked without the case branch inline
 * optimization. *)

val x = case 0 of 0 => 1 | n => 1;
