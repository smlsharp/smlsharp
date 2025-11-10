(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure Symbol =
struct
  type symbol = string

  fun toString (x : symbol) = x
  fun fromString (x : string) = x
  val compare = String.compare

  fun term s = SMLFormat.FormatExpression.Term (size s, s)
  fun format_symbol symbol = [term symbol]

  structure Ord =
  struct
    type ord_key = symbol
    val compare = compare
  end
  structure Map = BinaryMapFn(Ord)
  structure Set = BinarySetFn(Ord)
end
