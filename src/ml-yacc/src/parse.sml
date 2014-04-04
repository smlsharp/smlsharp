(* ML-Yacc Parser Generator (c) 1989 Andrew W. Appel, David R. Tarditi *)
(*
2012-3-21 ohori defuncterized
  yacc.sml is the only user as
   structure ParseGenParser =
	   ParseGenParserFun(structure Parser = Parser
	                     structure Header = Header)
*)
local
  structure Lex = LexMLYACC
  structure Parser = LrVals.Parser
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
              val lexer = Lex.makeLexer (fn i => (TextIO.inputN(in_str,i))) source
	      val stream =  Parser.makeStream {lexer=lexer}
	      val (result,_) = (Header.lineno := 1; 
				Header.text := nil;
		                Parser.parse {lookahead=15,stream=stream,error=error,arg=source}
                               )
	   in (TextIO.closeIn in_str; (result,source))
	   end
  end
end
