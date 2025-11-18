(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure Longsymbol =
struct
  type longsymbol = Symbol.symbol list * Symbol.symbol

  fun fromSymbolList x : longsymbol = x

  fun toSymbolList x : longsymbol = x

  fun fromStringList (path, last) =
      (map Symbol.fromString path, Symbol.fromString last)

  fun toStringList ((path, last) : longsymbol) =
      (map Symbol.toString path, Symbol.toString last)

  fun toString ((path, last) : longsymbol) =
      String.concatWith "." (map Symbol.toString (path @ [last]))

  fun format_longsymbol longsymbol =
      SMLFormat.BasicFormatters.format_string (toString longsymbol)

  fun comparePath (nil, nil) = EQUAL
    | comparePath (_ :: _, nil) = GREATER
    | comparePath (nil, _ :: _) = LESS
    | comparePath (h1 :: t1, h2 :: t2) =
      case Symbol.compare (h1, h2) of
        EQUAL => comparePath (t1, t2)
      | order => order

  fun compare ((path1, last1), (path2, last2)) =
      case comparePath (path1, path2) of
        EQUAL => Symbol.compare (last1, last2)
      | order => order

  fun last ((path, last) : longsymbol) = last

  structure Ord =
  struct
    type ord_key = longsymbol
    val compare = compare
  end
  structure Map = BinaryMapFn(Ord)
  structure Set = BinarySetFn(Ord)
end
