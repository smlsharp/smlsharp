(**
 * ML parser.
 *
 * @author OHORI Atsushi
 * @author YAMATODANI Kiyoshi
 * @version $Id: Parser.sml,v 1.20 2008/01/22 14:11:21 kiyoshiy Exp $
 *)
structure Parser :> PARSER =
struct

  (***************************************************************************)

  structure MLLrVals = MLLrValsFun(structure Token = LrParser.Token)
  structure MLLex = MLLexFun(structure Tokens = MLLrVals.Tokens)
  structure MLParser : ARG_PARSER =
  JoinWithArg(structure ParserData = MLLrVals.ParserData
              structure Lex = MLLex
              structure LrParser = LrParser)

  structure C = Control
  structure PC = ParserConstants

  (***************************************************************************)

  type lexer =
       (MLParser.svalue, MLParser.pos)
           MLParser.Token.token MLParser.Stream.stream

  type context =
       {
         lexArg : MLParser.lexarg,
         getLine : int -> string,
         lexer : lexer,
         onParseError : (string * Loc.pos * Loc.pos) -> unit,
         beforeParse : unit -> unit,
         print : string -> unit,
         withPrompt : bool
       }

  (***************************************************************************)

  exception  EndOfParse

  (* raised by lexer *)
  exception ParseError = MLParser.ParseError

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
          (
            {lineMap, lineCount, charCount, ...} : MLParser.lexarg,
            getLine,
            print,
            withPrompt
          ) =
      let
        fun extendedGetLine num =
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
        val doFirstLinePrompt = ref true
        fun beforeParse () = doFirstLinePrompt := true
        fun printPrompt () =
            (
              if !doFirstLinePrompt
              then (doFirstLinePrompt := false; print (!C.firstLinePrompt))
              else print (!C.secondLinePrompt)
            )
      in
        if withPrompt
        then (fn num => (printPrompt (); extendedGetLine num), beforeParse)
        else (extendedGetLine, fn () => ())
      end

  fun createContext
          {sourceName, onError, getLine, isPrelude, withPrompt, print} =
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
              stringType = ref MLLex.UserDeclarations.NOSTR,
              commentStart = ref nil,
              anyErrors = ref false,
              lineMap = lineMap,
              lineCount = lineCount,
              charCount = charCount,
              initialCharCount = ! charCount - PC.INITIAL_POS_OF_LEXER
            } : MLParser.lexarg
        val (extendedGetLine, beforeParse) =
            extendGetLine (lexArg, getLine, print, withPrompt)
        val lexer = MLParser.makeLexer extendedGetLine lexArg
        val context =
            {
              lexArg = lexArg,
              getLine = getLine,
              lexer = lexer,
              onParseError = onError,
              beforeParse = beforeParse,
              print = print,
              withPrompt = withPrompt
            }
      in
        context
      end

  (**
   * refresh parser context.
   *)
  fun resumeContext
          (context as {lexArg, getLine, print, withPrompt, ...} : context) =
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
              stringType = ref MLLex.UserDeclarations.NOSTR,
              commentStart = ref nil,
              anyErrors = ref false,
              lineMap = ref (!(#lineMap lexArg)),
              lineCount = ref (!(#lineCount lexArg)),
              charCount = ref (!(#charCount lexArg)),
              initialCharCount = !(#charCount lexArg) - PC.INITIAL_POS_OF_LEXER
            } : MLParser.lexarg
        val (extendedGetLine, beforeParse) =
            extendGetLine (newLexArg, getLine, print, withPrompt)
        val lexer = MLParser.makeLexer extendedGetLine newLexArg
        val newContext =
            {
              lexArg = newLexArg,
              getLine = getLine,
              lexer = lexer,
              onParseError = #onParseError context,
              beforeParse = beforeParse,
              print = print,
              withPrompt = withPrompt
            }
      in
        newContext
      end

  fun parse
        (context as {lexArg, onParseError, ...} : context) =
      let
        val dummyEOF = MLLrVals.Tokens.EOF(Loc.nopos, Loc.nopos)
        val dummySEMICOLON =
            MLLrVals.Tokens.SEMICOLON(Loc.nopos, Loc.nopos)

        fun parseImpl lexer =
            let
              val _ = #beforeParse context ()
              val _ = (#anyErrors lexArg) := false
              (* look ahead one token. *)
              val (nextToken, lexer') = MLParser.Stream.get lexer
            in
              (if MLParser.sameToken(nextToken, dummyEOF)
               then raise EndOfParse
               else
                 if MLParser.sameToken(nextToken, dummySEMICOLON)
                 then
                   (* look ahead one more token. *)
                   parseImpl lexer'
                 else
                   let
                     (* restart lex from the head token. *)
                     val (parseResult, lexer'') =
                         MLParser.parse(0, lexer, onParseError, ())
                   in
                     if !(#anyErrors lexArg)
                     then raise ParseError
                     else
                       (
                         parseResult,
                         {
                           lexArg = lexArg,
                           getLine = #getLine context,
                           lexer = lexer'',
                           onParseError = onParseError,
                           beforeParse = #beforeParse context,
                           print = #print context,
                           withPrompt = #withPrompt context
                         }
                       )
                   end)
            end
      in
        parseImpl (#lexer context)
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
