(**
 * implementation of SML source code parser.
 *
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: MLParser.sml,v 1.6 2008/08/10 12:54:32 kiyoshiy Exp $
 *)
(*
2012-3-22 ohori defuncterized 
1 inlined joinWith
2 parser-gen creates MLLrVals
*)
structure MLParser : MLPARSER =
struct

  (***************************************************************************)

(*
  structure MLLrVals = MLLrValsFun(structure Token = LrParser.Token)
*)
  structure Lex = MLLexFun(structure Tokens = MLLrVals.Tokens)

(*
  structure MLParser =
  JoinWithArg(structure ParserData = MLLrVals.ParserData
	      structure Lex = MLLexer
	      structure LrParser = LrParser)

functor JoinWithArg(structure Lex : ARG_LEXER
	     structure ParserData: PARSER_DATA
	     structure LrParser : LR_PARSER
	     sharing ParserData.LrTable = LrParser.LrTable
	     sharing ParserData.Token = LrParser.Token
	     sharing type Lex.UserDeclarations.svalue = ParserData.svalue
	     sharing type Lex.UserDeclarations.pos = ParserData.pos
	     sharing type Lex.UserDeclarations.token = ParserData.Token.token)
*)
  structure ParserData = MLLrVals.ParserData
  structure MLParser : ARG_PARSER  =
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

  (***************************************************************************)

  exception EndOfParse
  exception ParseError of string

  (***************************************************************************)

  fun posToLocation (lineMap, lastNewLinePos, currentLineNumber) pos =
      let
        fun inRegion (_, (leftPos, rightPos)) =
            leftPos <= pos andalso pos <= rightPos
      in
        if !lastNewLinePos < pos
        then (!currentLineNumber, pos - !lastNewLinePos)
        else
          case List.find inRegion (!lineMap) of
            NONE => (~1, pos) (* ToDo : error message. *)
          | SOME(lineCount, (leftPos, _)) => (lineCount, pos - leftPos)
      end

  fun getErrorMessage fileName posToLocation (message, (beginPos, endPos)) =
      let
        val (beginLine, beginCol) = posToLocation beginPos
        val (endLine, endCol) = posToLocation endPos
        val errorMessage = 
            String.concat 
            [
              fileName, ":",
              Int.toString beginLine, ".", Int.toString beginCol,
              "-",
              Int.toString endLine, ".", Int.toString endCol,
              " ",
              message
            ]
      in errorMessage end

  (****************************************)

  fun parse (fileName, sourceStream) =
      let

        type pos = int

        type lexarg =
             {
               brack_stack : int ref list ref,
               comLevel : int ref,
               currentLineNumber : int ref,
               error : (string * int * int) -> unit,
               inFormatComment : bool ref,
               lineMap : (int * (int * int)) list ref,
               lastNewLinePos : int ref,
               stream : TextIO.instream, 
               stringBuf : string list ref,
               stringStart : pos ref,
               stringType : bool ref
             }

        local
          val lineMap = ref []
          val currentLineNumber = ref 1
          val lastNewLinePos = ref 0
        in
        val posToLocation =
            posToLocation (lineMap, lastNewLinePos, currentLineNumber)
        fun onParseError (message, left, right) =
            let
              val fullMessage =
                  getErrorMessage
                      fileName posToLocation (message, (left, right))
            in
              raise ParseError fullMessage
            end
        val initialArg =
            {
              brack_stack = ref [],
              comLevel = ref 0,
              currentLineNumber = currentLineNumber,
              error = onParseError,
              inFormatComment = ref false,
              stream = sourceStream,
              lineMap = lineMap,
              lastNewLinePos = lastNewLinePos,
              stringBuf = ref nil : string list ref,
              stringStart = ref 0,
              stringType = ref true
            } : lexarg
        end

        local
          val dummyEOF = MLLrVals.Tokens.EOF (0, 0)
          val dummySEMICOLON = MLLrVals.Tokens.SEMICOLON (0, 0)
        in
        fun oneParse lexer =
	    let 
	      val (nextToken, lexer') = MLParser.Stream.get lexer
	    in
	      if MLParser.sameToken(nextToken, dummyEOF)
              then raise EndOfParse
	      else
                if MLParser.sameToken(nextToken, dummySEMICOLON)
                then oneParse lexer'
	        else MLParser.parse(0, lexer, onParseError, ())
	    end
        end

        fun untilEOF lexer results =
            let val (ast, lexer') = oneParse lexer
            in untilEOF lexer' (ast :: results) end
              handle EndOfParse => List.rev results

        fun getLine length = case TextIO.inputLine sourceStream of SOME x => x
								 | NONE => "" 

        val asts =
            untilEOF (MLParser.makeLexer getLine initialArg) []
      in
        (asts, posToLocation)
      end

  (***************************************************************************)

end
