(* -*- sml -*- *)
(**
 * syntax for the IML.
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author Katsuhiro Ueno
 *)
structure AbsynConst =
struct
  datatype constant =
      INT of IntInf.int
    | WORD of IntInf.int
    | STRING of string
    | REAL of string
    | CHAR of char
    | UNITCONST
end
