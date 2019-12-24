(* -*- sml -*- *)
(**
 * syntax for the IML.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @author Liu Bochao
 *)

structure AbsynConst =
struct

  (*% @formatter(IntInf.int) TermFormat.format_IntInf_dec_ML *)
  datatype constant
    = (*%
         @format(n) n
       *)
      INT of IntInf.int
    | (*%
         @format(n) n
       *)
      WORD of IntInf.int
    | (*%
         @format(value) "\"" value "\""
       *)
      STRING of string
    | (*%
         @format(value) value
       *)
      REAL of string
    | (*%
         @format(value) "#\"" value "\""
       *)
      CHAR of char
    | (*%
         @format "()"
       *)
      UNITCONST

end
