local
  structure MBS = MultiByteString.String
  structure MBC = MultiByteString.Char
  structure MBSS = MBSubstring
  structure P =
  struct
    type string = MBS.string
    type char = MBS.char
    type substring = MBSS.substring
    val implode = MBS.implode
    val getc = MBSS.getc
    val full = MBSS.full
    val compareChar = MBC.compare
  end
in
structure MBParserCombinator : PARSER_COMBINATOR = ParserCombinatorBase(P)
end
