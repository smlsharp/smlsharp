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

  fun toUserLongSymbols list =
      case list of
        ["Bool","bool"] => ["bool"]
      | ["Int","int"] => ["int"]
      | ["Int8","int"] => ["int8"]
      | ["Int16","int"] => ["int16"]
      | ["Int32","int"] => ["int"]
      | ["Int64","int"] => ["int64"]
      | ["IntInf","int"] => ["intInf"]
      | ["Word","word"] => ["word"]
      | ["Word8","word"] => ["word8"]
      | ["Word16","word"] => ["word16"]
      | ["Word32","word"] => ["word"]
      | ["Word64","word"] => ["word64"]
      | ["Real","real"] => ["real"]
      | ["Real32","real"] => ["real32"]
      | ["Real64","real"] => ["real64"]
      | ["Array","array"] => ["array"]
      | ["Vector","vector"] => ["vector"]
      | "SMLSharp_SQL_Prim"::tl => "SQL"::tl
      | x => x

  type longsymbol =
    {symbols : symbol list, loc : Loc.loc}

  fun toLongsymbol {symbols, loc} =
      Longsymbol.fromSymbolList (map #symbol symbols)
  fun toRecordLabel longsymbol =
      RecordLabel.fromString (Longsymbol.toString (toLongsymbol longsymbol))
  fun fromLongsymbol longsymbol =
      {symbols = map (fn x => {symbol = x, loc = Loc.noloc})
                     (Longsymbol.toSymbolList longsymbol),
       loc = Loc.noloc}

  fun format_longsymbol longsymbol =
      Longsymbol.format_longsymbol (toLongsymbol longsymbol)
  fun formatWithLoc_longsymbol (longsymbol as {symbols, loc}) =
      Longsymbol.format_longsymbol (toLongsymbol longsymbol)
      @ [SMLFormat.FormatExpression.Term (1, "("),
         SMLFormat.FormatExpression.Sequence (Loc.format_loc loc),
         SMLFormat.FormatExpression.Term (1, ")")]

  fun compareLoc ({symbol=s1, loc=l1}, {symbol=s2, loc=l2}) =
      Loc.compareLoc (l1,l2)

  fun lastSymbol {symbols, loc} = List.last symbols
  fun symbolToString (s:symbol) = Symbol.toString (#symbol s)
  fun symbolToLoc (s:symbol) = #loc s
  fun symbolToStringWithLoc (s:symbol) = 
      Symbol.toString (#symbol s) ^ "(" ^ Loc.locToString (symbolToLoc s) ^ ")"
  fun longsymbolToString {symbols, loc} =
      Longsymbol.toString (Longsymbol.fromSymbolList (map #symbol symbols))
  fun longsymbolToLoc {symbols, loc} = loc
  fun longsymbolToLoc' NONE = Loc.noloc
    | longsymbolToLoc' (SOME {symbols, loc}) = loc

  fun coerceLongsymbolToSymbol (longsymbol as {loc, ...}) =
      {symbol = Symbol.fromString (Longsymbol.toString (toLongsymbol longsymbol)),
       loc = loc}

  fun mkSymbol string loc = {symbol=Symbol.fromString string, loc=loc}
  fun mkLongsymbol stringList loc =
      {symbols = map (fn s => mkSymbol s loc) stringList, loc = loc}

  fun formatUserLongSymbol {symbols, loc} =
      Longsymbol.format_longsymbol
        (Longsymbol.fromSymbolList
           (map Symbol.fromString
                (toUserLongSymbols (map (Symbol.toString o #symbol) symbols))))

  fun setVersion ({symbols, loc}, version) =
      {symbols = symbols @ [{symbol = Symbol.fromString (Int.toString version), loc = Loc.noloc}],
       loc = loc}

  fun symbolCompare (s1:symbol, s2:symbol) = 
      String.compare(symbolToString s1, symbolToString s2)

  fun longsymbolCompare (s1:longsymbol, s2:longsymbol) =
      String.compare(longsymbolToString s1, longsymbolToString s2)

  fun eqSymbol (s1:symbol, s2:symbol) = 
      case symbolCompare(s1,s2) of
        EQUAL => true
      | _ => false

  fun eqLongsymbol (s1:longsymbol, s2:longsymbol) =
      longsymbolToString s1 = longsymbolToString s2

  fun replaceLocSymbol loc {symbol, loc=_} = {symbol=symbol, loc=loc}
  fun replaceLocLongsymbol loc {symbols, loc=_} = {symbols=symbols, loc=loc}

  fun symbolToLongsymbol (symbol as {loc, ...}) =
      {symbols = [symbol], loc = loc}

  fun prefixPath (prefix, {symbols, loc}) =
      {symbols = prefix @ symbols, loc = loc}

  fun prefixPath' (prefix, symbol as {loc, ...}) =
      {symbols = prefix @ [symbol], loc = loc}

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
