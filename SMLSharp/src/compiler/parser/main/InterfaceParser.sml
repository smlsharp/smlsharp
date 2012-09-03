(**
 * Interface parser.
 *
 * @author Liu Bochao
 * @version $Id: InterfaceParser.sml,v 1.2 2008/03/11 04:16:18 bochao Exp $
 *)
structure InterfaceParser:>INTERFACEPARSER  =
struct

  (***************************************************************************)

  structure InterfaceLrVals = InterfaceLrValsFun(structure Token = LrParser.Token)
  structure InterfaceLex = InterfaceLexFun(structure Tokens = InterfaceLrVals.Tokens)
  structure InterfaceParser : ARG_PARSER =
  JoinWithArg(structure ParserData = InterfaceLrVals.ParserData
              structure Lex = InterfaceLex
              structure LrParser = LrParser)
  (***************************************************************************)

  type lexer =
         (InterfaceParser.svalue, InterfaceParser.pos)
             InterfaceParser.Token.token InterfaceParser.Stream.stream

  type context =
       {
         lexArg : InterfaceParser.lexarg,
         getLine : int -> string,
         lexer : lexer,
         onParseError : (string * Loc.pos * Loc.pos) -> unit
       }

  structure PC = ParserConstants


  exception  EndOfParse

  (* raised by lexer *)
  exception ParseError = InterfaceParser.ParseError

  (***************************************************************************)

  fun lineMapEntryToString {lineCount, beginPos} =
      "(" ^ Int.toString lineCount ^ ", " ^ Int.toString beginPos ^ ")"
  fun printLineMap lineMap =
      (
        print "lineMap = {";
        app (print o lineMapEntryToString) lineMap;
        print "}\n"
      )

  fun extendGetLine
          ({lineMap, lineCount, charCount, ...} : InterfaceParser.lexarg, getLine)
          num =
      let
        val line = getLine num
        val lineLength = String.size line
        val _= lineCount := (!lineCount) + 1
        val _= charCount := (!charCount) + lineLength
        val _=
            lineMap :=
            {lineCount = !lineCount, beginPos = !charCount} :: (!lineMap)
      in
        line
      end

  fun createContext {sourceName, onError, getLine, isPrelude} =
      let
        val lineCount = ref 1
        val charCount = ref PC.INITIAL_POS_OF_LEXER
        val lineMap = ref [{lineCount = 1, beginPos = !charCount}]
        val startPos = Loc.makePos {fileName = sourceName, line = 0, col = 0}
        val lexArg =
            {
              fileName = sourceName,
              isPrelude = isPrelude,
              errorPrinter = onError, (* not raise ParseError *)
              stringBuf = ref nil : string list ref,
              stringStart = ref startPos,
              stringType = ref true,
              comLevel = ref 0,
              anyErrors = ref false,
              lineMap = lineMap,
              lineCount = lineCount,
              charCount = charCount,
              initialCharCount = ! charCount - PC.INITIAL_POS_OF_LEXER
            } : InterfaceParser.lexarg
        val extendedGetLine = extendGetLine (lexArg, getLine)
        val lexer = (InterfaceParser.makeLexer extendedGetLine lexArg) : lexer
        val context =
            {
              lexArg = lexArg,
              getLine = extendedGetLine,
              lexer = lexer,
              onParseError = onError
            }
      in
        context
      end

  (**
   * refresh parser context.
   *)
  fun resumeContext ({lexArg, getLine, onParseError, ...} : context) =
      let
        val startPos =
            Loc.makePos {fileName = #fileName lexArg, line = 0, col = 0}
        val newLexArg =
            {
              fileName = #fileName lexArg,
              isPrelude = #isPrelude lexArg,
              errorPrinter = #errorPrinter lexArg,
              stringBuf = ref nil : string list ref,
              stringStart = ref startPos,
              stringType = ref true,
              comLevel = ref 0,
              anyErrors = ref false,
              lineMap = ref (!(#lineMap lexArg)),
              lineCount = ref (!(#lineCount lexArg)),
              charCount = ref (!(#charCount lexArg)),
              initialCharCount = !(#charCount lexArg) - PC.INITIAL_POS_OF_LEXER
            } : InterfaceParser.lexarg
        val extendedGetLine = extendGetLine (newLexArg, getLine)
        val lexer = (InterfaceParser.makeLexer extendedGetLine newLexArg) : lexer
        val context =
            {
              lexArg = newLexArg,
              getLine = getLine,
              lexer = lexer,
              onParseError = onParseError
            }
      in
        context
      end

  fun parse ({lexArg, getLine, lexer, onParseError, ...} : context) =
      let
        val dummyEOF = InterfaceLrVals.Tokens.EOF(Loc.nopos, Loc.nopos)

        fun parseImpl lexer =
            let
              val _ = (#anyErrors lexArg) := false
              (* look ahead one token. *)
              val (nextToken, lexer') = InterfaceParser.Stream.get lexer
            in
              (if InterfaceParser.sameToken(nextToken, dummyEOF)
               then raise EndOfParse
               else
                   let
                     (* restart lex from the head token. *)
                     val (parseResult, lexer'') =
                         InterfaceParser.parse(0, lexer, onParseError, ())
                   in
                     if !(#anyErrors lexArg)
                     then raise ParseError
                     else
                       (
                         parseResult,
                         {
                           lexArg = lexArg,
                           getLine = getLine,
                           lexer = lexer'',
                           onParseError = onParseError
                         }
                       )
                   end)
            end
      in
        parseImpl lexer
      end

  fun errorToString (message, pos1, pos2) =
      String.concat 
          [
            Loc.fileNameOfPos pos1, ":",
            Int.toString (Loc.lineOfPos pos1),
            ".",
            Int.toString (Loc.colOfPos pos1),
            "-",
            Int.toString (Loc.lineOfPos pos2),
            ".",
            Int.toString (Loc.colOfPos pos2),
            " ",
            message,
            "\n"
          ]

  (***************************************************************************)

end
