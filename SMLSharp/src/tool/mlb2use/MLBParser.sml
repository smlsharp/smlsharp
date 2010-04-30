(**
 * parser of lambda expression.
 * @copyright 2000, YAMATODANI Kiyoshi, Jaist.
 * @author YAMATODANI Kiyoshi
 * @version $Id: MLBParser.sml,v 1.1 2007/07/29 00:50:00 kiyoshiy Exp $
 *)
structure MLBParser = 
struct

  structure MLBLrVals = 
  MLBLrValsFun (structure Token = LrParser.Token)
  structure MLBLex =
  MLBLexFun (structure Tokens = MLBLrVals.Tokens)
  structure MLBParserImp = 
  JoinWithArg (structure ParserData = MLBLrVals.ParserData;
               structure Lex = MLBLex;
               structure LrParser = LrParser)

  exception ParseError

  (* parse stream to abstract syntax tree. *)
  fun parseStream name istream = 
      let
        val lexArg = {source = Source.new name}
        val lexer =
            MLBParserImp.makeLexer (fn n=>TextIO.inputN (istream, n)) lexArg
        (* do nothing, expecting someone handle ParseError.*)
        val print_error = fn (s, i, _) => ()
      in
        #1 (MLBParserImp.parse (0, lexer, print_error, ()))
        handle MLBParserImp.ParseError => raise ParseError
             | MLBLex.LexError => raise ParseError
      end

  fun parseFile file =
      let
        val istream = TextIO.openIn file
      in
        parseStream file istream
        before TextIO.closeIn istream
      end

end;
