(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
fun term s = SMLFormat.FormatExpression.Term (size s, s)

structure Symbol =
struct
  type symbol = string

  fun toString (x : symbol) = x
  fun fromString (x : string) = x
  val compare = String.compare

  fun format_symbol symbol = [term symbol]

  structure Ord =
  struct
    type ord_key = symbol
    val compare = compare
  end
  structure Map = BinaryMapFn(Ord)
  structure Set = BinarySetFn(Ord)
end

structure Longsymbol =
struct
  type longsymbol = Symbol.symbol list

  fun toStringList (x : longsymbol) = x
  fun fromStringList (x : string list) = x
  val toSymbolList = toStringList
  val fromSymbolList = fromStringList
  fun toString x = String.concatWith "." x

  fun format_longsymbol longsymbol = [term (toString longsymbol)]

  fun compare (nil, nil) = EQUAL
    | compare (_ :: _, nil) = GREATER
    | compare (nil, _ :: _) = LESS
    | compare (h1 :: t1, h2 :: t2) =
      case String.compare (h1, h2) of
        EQUAL => compare (t1, t2)
      | LESS => LESS
      | GREATER => GREATER

  fun append (x : longsymbol, y) = x @ [y]
  fun lastSymbol (x : longsymbol) = List.last x

  structure Ord =
  struct
    type ord_key = longsymbol
    val compare = compare
  end
  structure Map = BinaryMapFn(Ord)
  structure Set = BinarySetFn(Ord)
end
