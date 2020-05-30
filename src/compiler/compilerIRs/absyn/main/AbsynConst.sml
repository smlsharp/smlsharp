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

  (*%
    @formatter(intinf_int) ConstFormat.format_intInf_dec_ML
    @formatter(intinf_word) ConstFormat.format_intInf_word_ML
    @formatter(string_ML) ConstFormat.format_string_ML
    @formatter(char_ML) ConstFormat.format_char_ML
  *)
  datatype constant
    = (*%
         @format(n) n:intinf_int
       *)
      INT of IntInf.int
    | (*%
         @format(n) n:intinf_word
       *)
      WORD of IntInf.int
    | (*%
         @format(x) x:string_ML
       *)
      STRING of string
    | (*%
         @format(x) x
       *)
      REAL of string
    | (*%
         @format(x) x:char_ML
       *)
      CHAR of char
    | (*%
         @format "()"
       *)
      UNITCONST

end
