(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure Symbol =
struct
  type symbol = string
  type longsymbol = symbol list

  fun toString (x : symbol) = x
  fun fromString (x : string) = x
  val compare = String.compare

  fun toStringList (x : longsymbol) = x
  fun fromStringList (x : string list) = x
  val toSymbolList = toStringList
  val fromSymbolList = fromStringList
  fun longsymbolToString x = String.concatWith "." x

  fun term s = SMLFormat.FormatExpression.Term (size s, s)
  fun format_symbol symbol = [term symbol]
  fun format_longsymbol longsymbol = [term (longsymbolToString longsymbol)]

  fun compareLongsymbol (nil, nil) = EQUAL
    | compareLongsymbol (_ :: _, nil) = GREATER
    | compareLongsymbol (nil, _ :: _) = LESS
    | compareLongsymbol (h1 :: t1, h2 :: t2) =
      case String.compare (h1, h2) of
        EQUAL => compareLongsymbol (t1, t2)
      | LESS => LESS
      | GREATER => GREATER

  fun append (x : longsymbol, y) = x @ [y]
  fun lastSymbol (x : longsymbol) = List.last x
end

structure SymbolOrd =
struct
  type ord_key = Symbol.symbol
  val compare = Symbol.compare
end
structure SymbolEnv = BinaryMapFn2(SymbolOrd)
structure SymbolSet = BinarySetFn(SymbolOrd)

structure LongsymbolOrd =
struct
  type ord_key = Symbol.symbol list
  val compare = Symbol.compareLongsymbol
end
structure LongsymbolEnv = BinaryMapFn2(LongsymbolOrd)
structure LongsymbolSet = BinarySetFn(LongsymbolOrd)
