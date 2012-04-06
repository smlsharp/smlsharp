(* ML-Yacc Parser Generator (c) 1989 Andrew W. Appel, David R. Tarditi *)
(*
2012-3-21 ohori defuncterized
  yacc.sml is the only user as
   structure ParseGenParser =
	   ParseGenParserFun(structure Parser = Parser
	                     structure Header = Header)
*)

local
   structure Lex = LexMLYACC(structure Tokens = LrVals.Tokens
			     structure Hdr = Header)
  structure ParserData = LrVals.ParserData

(*  
 structure Parser = JoinWithArg(structure Lex=Lex
			         structure ParserData = LrVals.ParserData
			         structure LrParser= LrParser)
*)
  structure Parser = 
  struct
    structure Token = ParserData.Token
    structure Stream = LrParser.Stream

    exception ParseError = LrParser.ParseError

    type arg = ParserData.arg
    type lexarg = Lex.UserDeclarations.arg
    type pos = ParserData.pos
    type result = ParserData.result
    type svalue = ParserData.svalue

    val makeLexer = fn s => fn arg =>
		 LrParser.Stream.streamify (Lex.makeLexer s arg)
    val parse = fn (lookahead,lexer,error,arg) =>
	(fn (a,b) => (ParserData.Actions.extract a,b))
     (LrParser.parse {table = ParserData.table,
	        lexer=lexer,
		lookahead=lookahead,
		saction = ParserData.Actions.actions,
		arg=arg,
		void= ParserData.Actions.void,
	        ec = {is_keyword = ParserData.EC.is_keyword,
		      noShift = ParserData.EC.noShift,
		      preferred_change = ParserData.EC.preferred_change,
		      errtermvalue = ParserData.EC.errtermvalue,
		      error=error,
		      showTerminal = ParserData.EC.showTerminal,
		      terms = ParserData.EC.terms}}
      )
    val sameToken = Token.sameToken
  end
in
structure ParseGenParser : PARSE_GEN_PARSER =
 struct
      structure Header = Header
      val parse = fn file =>
          let
	      val in_str = TextIO.openIn file
	      val source = Header.newSource(file,in_str,TextIO.stdOut)
	      val error = fn (s : string,i:int,_) =>
		              Header.error source i s
	      val stream =  Parser.makeLexer (fn i => (TextIO.inputN(in_str,i)))
		            source
	      val (result,_) = (Header.lineno := 1; 
				Header.text := nil;
		                Parser.parse(15,stream,error,source))
	   in (TextIO.closeIn in_str; (result,source))
	   end
  end
end
