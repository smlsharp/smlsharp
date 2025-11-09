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
    symbol list

  fun format_longsymbol symbols =
      SMLFormat.BasicFormatters.format_list
        (format_symbol, [SMLFormat.FormatExpression.Term (1, ".")])
        symbols
  fun formatWithLoc_longsymbol symbols =
      SMLFormat.BasicFormatters.format_list
        (formatWithLoc_symbol, [SMLFormat.FormatExpression.Term (1, ".")])
        symbols

  fun formatWithLoc_longsymbol symbols =
      SMLFormat.BasicFormatters.format_list
        (formatWithLoc_symbol, [SMLFormat.FormatExpression.Term (1, ".")])
        symbols

  fun compareLoc ({symbol=s1, loc=l1}, {symbol=s2, loc=l2}) =
      Loc.compareLoc (l1,l2)

  fun lastSymbol longsymbol = List.last longsymbol
  fun symbolToString (s:symbol) = Symbol.toString (#symbol s)
  fun symbolToLoc (s:symbol) = #loc s
  fun symbolToStringWithLoc (s:symbol) = 
      Symbol.toString (#symbol s) ^ "(" ^ Loc.locToString (symbolToLoc s) ^ ")"
  fun longsymbolToString (s:longsymbol) = String.concatWith "." (map symbolToString s)
  fun longsymbolToLoc (s:longsymbol) =
      let
        val head = List.hd s
        val (pos1,_) = symbolToLoc head
        val last = List.last s
        val (_, pos2) = symbolToLoc last
      in
        (pos1, pos2)
      end
      handle List.Empty => Loc.noloc
        
  fun longsymbolToLastLoc (s:longsymbol) =
      let
        val last = List.last s
      in
        symbolToLoc last
      end
      handle List.Empty => Loc.noloc
        
  fun longsymbolToLongid (s:longsymbol) = map symbolToString s

  fun toLongsymbol (s:longsymbol) =
      Longsymbol.fromSymbolList (map #symbol s)
  fun fromLongsymbol (s:Longsymbol.longsymbol) loc =
      map (fn s => {symbol = s, loc = loc}) (Longsymbol.toSymbolList s)

  fun coerceLongsymbolToSymbol longsymbol =
      {symbol = Symbol.fromString (longsymbolToString longsymbol),
       loc = longsymbolToLoc longsymbol}

  fun mkSymbol string loc = {symbol=Symbol.fromString string, loc=loc}
  fun mkLongsymbol stringList loc = map (fn s => mkSymbol s loc) stringList

  fun formatUserLongSymbol list =
      format_longsymbol
        (mkLongsymbol (toUserLongSymbols (longsymbolToLongid list)) Loc.noloc)


  fun setVersion (longsymbol, version) =
      longsymbol @ [mkSymbol (Int.toString version) (longsymbolToLoc longsymbol)]
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
  fun replaceLocLongsymbol loc longsymbol = map (replaceLocSymbol loc) longsymbol

  fun prefixPath (path, symbol) =
      let
        val loc = symbolToLoc symbol
        val path = replaceLocLongsymbol loc path
      in
        path@[symbol]
      end
  fun concatPath (path, longsymbol) =
      let
        val loc = longsymbolToLoc longsymbol
        val path = replaceLocLongsymbol loc path
      in
        path @ longsymbol
      end

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

end

end

structure SymbolWithLocOrd =
struct
  type ord_key = SymbolWithLoc.symbol
  val compare = SymbolWithLoc.symbolCompare
end

structure SymbolWithLocEnv = BinaryMapFn2(SymbolWithLocOrd)

structure SymbolWithLocSet = BinarySetFn(SymbolWithLocOrd)
