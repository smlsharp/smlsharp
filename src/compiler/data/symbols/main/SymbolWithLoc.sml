(**
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure SymbolWithLoc =
struct
local
  type loc = Loc.loc
in
  type symbol =
    {symbol:Symbol.symbol, loc:loc}

  fun format_symbol {symbol, loc} = Symbol.format_symbol symbol
  fun formatWithLoc_symbol {symbol, loc} =
      Symbol.format_symbol symbol
      @ [SMLFormat.FormatExpression.Term (1, "("),
         SMLFormat.FormatExpression.Sequence (Loc.format_loc loc),
         SMLFormat.FormatExpression.Term (1, ")")]

  type longsymbol =
      {
        path : symbol list, (* strid path *)
        last : symbol,
        loc : Loc.loc (* user's original location *)
      }

  fun fromAbsynId (symbol, loc) = {symbol = symbol, loc = Loc.LOC loc}

  fun fromAbsyn (strids, id, loc) =
      {path = map fromAbsynId strids,
       last = fromAbsynId id,
       loc = Loc.LOC loc}

  fun toSymbolList ({path, last, loc} : longsymbol) =
      path @ [last]

  fun toLongsymbol ({path, last, loc} : longsymbol) =
      Longsymbol.fromSymbolList (map #symbol path, #symbol last)

  fun toRecordLabel longsymbol =
      RecordLabel.fromString (Longsymbol.toString (toLongsymbol longsymbol))

  fun fromLongsymbol longsymbol =
      case Longsymbol.toSymbolList longsymbol of
        (path, last) =>
        {path = map (fn x => {symbol = x, loc = Loc.noloc}) path,
         last = {symbol = last, loc = Loc.noloc},
         loc = Loc.noloc}

  fun format_longsymbol longsymbol =
      Longsymbol.format_longsymbol (toLongsymbol longsymbol)

  fun formatWithLoc_longsymbol (longsymbol as {loc, ...}) =
      format_longsymbol longsymbol
      @ [SMLFormat.FormatExpression.Term (1, "("),
         SMLFormat.FormatExpression.Sequence (Loc.format_loc loc),
         SMLFormat.FormatExpression.Term (1, ")")]

  fun compareLoc ({symbol=s1, loc=l1}, {symbol=s2, loc=l2}) =
      Loc.compareLoc (l1, l2)

  fun lastSymbol ({last, ...} : longsymbol) = last

  fun pathOf ({path, ...} : longsymbol) = path

  fun symbolToString (s : symbol) = Symbol.toString (#symbol s)

  fun symbolToStringWithLoc s =
      symbolToString s ^ "(" ^ Loc.locToString (#loc s) ^ ")"

  fun longsymbolToString longsymbol =
      Longsymbol.toString (toLongsymbol longsymbol)

  fun longsymbolToLoc ({loc, ...} : longsymbol) = loc

  fun coerceLongsymbolToSymbol (longsymbol as {loc, ...} : longsymbol) =
      {symbol =
         Symbol.fromString (Longsymbol.toString (toLongsymbol longsymbol)),
       loc = loc}

  fun mkSymbol string loc = {symbol = Symbol.fromString string, loc=loc}

  fun mkLongsymbol stringList loc =
      case rev stringList of
        nil => raise Bug.Bug "mkLongsymbol with empty list"
      | last :: othersRev =>
        {path = map (fn s => mkSymbol s loc) (rev othersRev),
         last = mkSymbol last loc,
         loc = loc}

  fun setVersion ({path, last, loc} : longsymbol, version) =
      {path = path @ [last],
       last = {symbol = Symbol.fromString (Int.toString version),
               loc = Loc.noloc},
       loc = loc}

  fun symbolCompare (s1 : symbol, s2 : symbol) =
      String.compare (symbolToString s1, symbolToString s2)

  fun longsymbolCompare (s1 : longsymbol, s2 : longsymbol) =
      String.compare (longsymbolToString s1, longsymbolToString s2)

  fun eqSymbol (s1 : symbol, s2 : symbol) =
      case symbolCompare (s1, s2) of
        EQUAL => true
      | _ => false

  fun eqLongsymbol (s1 : longsymbol, s2 : longsymbol) =
      longsymbolToString s1 = longsymbolToString s2

  fun replaceLocSymbol loc (symbol : symbol) =
      symbol # {loc = loc}

  fun replaceLocLongsymbol loc (longsymbol : longsymbol) =
      longsymbol # {loc = loc}

  fun symbolToLongsymbol (symbol as {loc, ...} : symbol) =
      {path = nil, last = symbol, loc = loc}

  fun prefixPath (prefix, longsymbol as {path, ...}: longsymbol) =
      longsymbol # {path = prefix @ path}

  fun prefixPath' (prefix, symbol as {loc, ...} : symbol) =
      {path = prefix, last = symbol, loc = loc}

  fun replacePrefix (longsymbol : longsymbol, prefix) =
      longsymbol # {path = prefix}

  val seed = ref nil : char list ref

  fun gensym () =
      let
        fun inc nil = [#"a"]
          | inc (h::t) =
            if h >= #"z"
            then #"a" :: inc t
            else (chr (ord h + 1)) :: t
      in
        seed := inc (!seed);
        implode (rev (!seed))
      end

  (* FIXME: how to ensure the generated symbol is fresh? *)
  fun generate () =
      {symbol = Symbol.fromString ("$" ^ gensym ()), loc = Loc.noloc}

  fun generateLongsymbol () =
      symbolToLongsymbol (generate ())

end

end

structure SymbolWithLocOrd =
struct
  type ord_key = SymbolWithLoc.symbol
  val compare = SymbolWithLoc.symbolCompare
end

structure SymbolWithLocEnv = BinaryMapFn2(SymbolWithLocOrd)
