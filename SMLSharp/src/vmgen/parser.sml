structure Parser : sig

  val parse : string -> InsnDef.def list

end =
struct

  (*
   * if you want to debug parser, copy ml-yacc/lib/parser2.sml to here and
   * rewrite it so that DEBUG1 and DEBUG2 are true.
   *)
  structure LrVals = InsnLrValsFun(structure Token = LrParser.Token)
  structure Lex = InsnLexFun(structure Tokens = LrVals.Tokens)
  structure Parser = JoinWithArg(structure ParserData = LrVals.ParserData
			         structure Lex = Lex
			         structure LrParser = LrParser)

  fun parse filename =
      let
        val file = TextIO.openIn filename
      in
        (let
           val source =
               {
                 filename = filename,
                 lineStartPos = ref nil   (* ref [2] *)
               } : InsnDef.source

           val _ = Control.source := SOME source

           val parseError = ref nil

           fun error (msg, lpos, rpos) =
               parseError := ((lpos, rpos), msg) :: !parseError

           val lexarg =
               {
                 source = source,
                 error = error,
                 commentLevel = ref 0,
                 startPos = ref ~1,
                 stringToken = ref ""
               }

           val lexer = Parser.makeLexer (fn _ => TextIO.input file) lexarg
           val result =
               let
                 val (result, lexer) = Parser.parse (15, lexer, error, ref 0)
                 val (token, lexer) = Parser.Stream.get lexer
               in
                 if Parser.sameToken (token, LrVals.Tokens.EOF (~1, ~1))
                 then ()
                 else error ("parser not reached to EOF", ~1, ~1);
                 result
               end
               handle ParseError => nil
         in
           case !parseError of
             nil => ()
           | errs => raise Control.Error (rev errs);
           result
         end
         handle e => (TextIO.closeIn file; raise e))
        before TextIO.closeIn file
      end

end
