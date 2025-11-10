(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure Longsymbol =
struct
  type longsymbol = Symbol.symbol list

  fun toStringList (x : longsymbol) = map Symbol.toString x
  fun fromStringList (x : string list) = map Symbol.fromString x
  fun toSymbolList (x : longsymbol) = x
  fun fromSymbolList x : longsymbol = x
  fun toString x = String.concatWith "." (toStringList x)

  fun term s = SMLFormat.FormatExpression.Term (size s, s)
  fun format_longsymbol longsymbol = [term (toString longsymbol)]

  fun compare (nil, nil) = EQUAL
    | compare (_ :: _, nil) = GREATER
    | compare (nil, _ :: _) = LESS
    | compare (h1 :: t1, h2 :: t2) =
      case Symbol.compare (h1, h2) of
        EQUAL => compare (t1, t2)
      | LESS => LESS
      | GREATER => GREATER

  fun append (x : longsymbol, y) = x @ [y]
  fun last (x : longsymbol) = List.last x

  structure Ord =
  struct
    type ord_key = longsymbol
    val compare = compare
  end
  structure Map = BinaryMapFn(Ord)
  structure Set = BinarySetFn(Ord)
end
