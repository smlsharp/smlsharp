(**
 * SMLPP example: Format expression parser
 *
 * YAMATODANI Kiyoshi
 *
 * Original is:
 * Copyright 2001
 * Atsushi Ohori 
 * JAIST, Ishikawa Japan. 
 *)
structure Main =
struct

  (***************************************************************************)

  structure FormatExpressionLrVals =
  FormatExpressionLrValsFun(structure Token = LrParser.Token)
  structure FormatExpressionLex = 
  FormatExpressionLexFun(structure Tokens = FormatExpressionLrVals.Tokens)
  structure FormatExpressionParser=
  JoinWithArg(structure ParserData = FormatExpressionLrVals.ParserData
	      structure Lex=FormatExpressionLex
	      structure LrParser=LrParser)

  structure PP = SMLFormat.PrinterParameter

  (***************************************************************************)

  type pos = {fileName : string, line : int, col : int}

  type lexarg =
       {
         columns : int ref,
         space : string ref,
         newline : string ref,
         guardLeft : string ref,
         guardRight : string ref,
         maxDepthOfGuards : int option ref,
         maxWidthOfGuards : int option ref,
         cutOverTail : bool ref,

         comLevel : int ref,
         doFirstLinePrompt : bool ref,
         error : (string * pos * pos) -> unit,
         fileName : string, 
         linePos : int ref ,
         ln : int ref,
         promptMode : bool, 
         stream : TextIO.instream, 
         stringBuf : string list ref,
         stringStart : pos ref,
         stringType : bool ref,
         verbose : bool ref
       }

  (***************************************************************************)

  exception EndOfParse
  exception ParseError

  (***************************************************************************)

  val firstLinePrompt = "->"
  val secondLinePrompt = ">>"

  (***************************************************************************)

  fun makeScale length =
      let
        fun append index (lineChars, scaleChars) =
            if index = length + 1
            then
              (String.implode lineChars) ^ "\n" ^
              (String.implode(List.rev scaleChars))
            else
              append
              (index + 1)
              (
                (#"-" :: lineChars),
                (String.sub (Int.toString (index mod 10), 0) :: scaleChars)
              )
      in
        append 1 ([], [])
      end

  fun printError
      (
        message,
        {fileName, line = lineBegin, col = colBegin},
        {fileName = _, line = lineEnd, col = colEnd}
      ) =
      (TextIO.output
       (
         TextIO.stdOut,
         String.concat 
         [
           fileName, ":",
           Int.toString lineBegin, ".", Int.toString colBegin,
           "-",
           Int.toString lineEnd, ".", Int.toString colEnd,
           " ",
           message,
           "\n"
         ]
       );
       raise ParseError)

  fun flush(arg:lexarg) =
      (
        #comLevel arg := 0;
        #doFirstLinePrompt arg := true;
        #linePos arg := 0; 
        #ln arg := 1;
        #stringBuf arg := nil;
        #stringStart arg := 
        {fileName = #fileName (!(#stringStart arg)), line = 0, col = 0};
        #stringType arg := true
      )

  fun processInput arg =
      let

        local
          val dummyLocation =
              (
                {fileName = "", line = 0, col = 0},
                {fileName = "", line = 0, col = 0}
              )
          val dummyEOF = FormatExpressionLrVals.Tokens.EOF dummyLocation
          val dummySEMICOLON =
              FormatExpressionLrVals.Tokens.SEMICOLON dummyLocation
        in
        fun oneParse lexer =
	    let 
	      val _ = #doFirstLinePrompt arg := true
	      val (nextToken, lexer') = FormatExpressionParser.Stream.get lexer
	    in
	      if FormatExpressionParser.sameToken(nextToken, dummyEOF)
              then raise EndOfParse
	      else
                if FormatExpressionParser.sameToken(nextToken, dummySEMICOLON)
                then oneParse lexer'
	        else FormatExpressionParser.parse(0, lexer, printError, ())
	    end
        end

        fun loop lexer = 
	    let
	      val (result, lexer') = oneParse lexer
	    in 
	      case result of
                Ast.SET(item, value) =>
                (case item of
                   "columns" =>
                   (case Int.fromString value of
                       SOME width => (#columns arg) := width
                     | NONE => print "columns must be integer.\n";
                     loop lexer')
                 | "cutovertail" =>
                   (case value of
                       "true" => (#cutOverTail arg) := true
                     | "false" => (#cutOverTail arg) := false
                     | _ => print "cutovertail must be true or false.\n";
                     loop lexer')
                 | "space" => (#space arg := value; loop lexer')
                 | "newline" => (#newline arg := value; loop lexer')
                 | "guardleft" => (#guardLeft arg := value; loop lexer')
                 | "guardright" => (#guardRight arg := value; loop lexer')
                 | "depth" =>
                   (case value of
                      "-" => (#maxDepthOfGuards arg := NONE; loop lexer')
                    | _ =>
                      (case Int.fromString value of
                         SOME d => #maxDepthOfGuards arg := SOME d
                       | NONE => print "depth must be integer or '-'.\n";
                       loop lexer'))
                 | "width" =>
                   (case value of
                      "-" => (#maxWidthOfGuards arg := NONE; loop lexer')
                    | _ =>
                      (case Int.fromString value of
                         SOME d => #maxWidthOfGuards arg := SOME d
                       | NONE => print "width must be integer or '-'.\n";
                       loop lexer'))
                 | "verbose" =>
                   (case value of
                       "true" => (#verbose arg) := true
                     | "false" => (#verbose arg) := false
                     | _ => print "verbose must be true or false.\n";
                     loop lexer')
                 | _ =>
                   (print ("unknown option:" ^ item ^ ".\n"); loop lexer'))
              | Ast.EXIT => ()
	      | Ast.USE sourceFileName =>
	        (let
		   val arg =
                       {
                         columns = ref (!(#columns arg)),
                         space = ref (!(#space arg)),
                         newline = ref (!(#newline arg)),
                         guardLeft = ref (!(#guardLeft arg)),
                         guardRight = ref (!(#guardRight arg)),
                         maxDepthOfGuards = ref (!(#maxDepthOfGuards arg)),
                         maxWidthOfGuards = ref (!(#maxWidthOfGuards arg)),
                         cutOverTail = ref (!(#cutOverTail arg)),

                         comLevel = ref 0,
                         doFirstLinePrompt = ref true,
                         error = #error arg,
                         fileName = sourceFileName,
		         promptMode = false,
		         stream = TextIO.openIn sourceFileName,
		         linePos = ref 0,
		         ln = ref 1,
                         stringBuf = ref nil : string list ref,
                         stringStart =
                         ref {fileName = sourceFileName, line = 0, col = 0},
                         stringType = ref true,
                         verbose = ref (!(#verbose arg))
                       } : lexarg
	         in
		   processInput arg
	         end
                   handle EndOfParse => loop lexer'
		        | IO.Io detail => 
			  let
			    val message =
                                case (#cause detail) of
                                  OS.SysErr (s, SOME err) => 
                                  "GenLex error: use clause ignored. " ^
                                  (OS.errorMsg err) ^ " : " ^ (#name detail)
                                | _ =>
                                  "IO error " ^ (#function detail) ^ " " ^
                                  (#name detail)
                          in
                            TextIO.output(TextIO.stdOut, message ^ "\n");
                            TextIO.flushOut TextIO.stdOut;
                            loop lexer'
                          end)

	      |  Ast.PRINT (expressions) =>
                 let
                   val parameter =
                       [
                         SMLFormat.Columns(!(#columns arg)),
                         SMLFormat.Newline(!(#newline arg)),
                         SMLFormat.Space(!(#space arg)),
                         SMLFormat.GuardLeft(!(#guardLeft arg)),
                         SMLFormat.GuardRight(!(#guardRight arg)),
                         SMLFormat.MaxDepthOfGuards(!(#maxDepthOfGuards arg)),
                         SMLFormat.MaxWidthOfGuards(!(#maxWidthOfGuards arg)),
                         SMLFormat.CutOverTail(!(#cutOverTail arg))
                       ]
                 in
                   print (SMLFormat.prettyPrint parameter expressions)
                   handle SMLFormat.Fail message => print (message ^ "\n");
                   print "\n";
                   if !(#verbose arg)
                   then print (makeScale (!(#columns arg)) ^ "\n")
                   else ();
                   loop lexer'
                 end
	    end

        fun getLine length =
            (
              if #promptMode arg
              then 
                if !(#doFirstLinePrompt arg)
                then
      	          (
                    #doFirstLinePrompt arg := false;
      	            print firstLinePrompt;
      	            TextIO.flushOut TextIO.stdOut
                  )
                else
                  (
                    print secondLinePrompt;
      	            TextIO.flushOut TextIO.stdOut
                  )
              else ();
              case TextIO.inputLine (#stream arg)
               of NONE => ""
                | SOME s => s
            )

        val lexer = FormatExpressionParser.makeLexer getLine arg
      in
        (loop lexer) 
        handle ParseError => (flush arg; processInput arg)
      end

  fun main () =
      let
        val initialSource =
            {
              columns = ref 40,
              space = ref PP.defaultSpace,
              newline = ref PP.defaultNewline,
              guardLeft = ref PP.defaultGuardLeft,
              guardRight = ref PP.defaultGuardRight,
              maxDepthOfGuards = ref NONE,
              maxWidthOfGuards = ref NONE,
              cutOverTail = ref false,

              comLevel=ref 0,
              doFirstLinePrompt = ref true,
              error = printError,
              fileName="stdIn",
              stream=TextIO.stdIn,
              linePos= ref 1,
              ln = ref 1,
              promptMode = true,
              stringBuf = ref nil : string list ref,
              stringStart = ref {fileName = "stdIn", line = 0, col = 0},
              stringType = ref true,
              verbose = ref false
            } : lexarg
      in
        processInput initialSource
        handle EndOfParse => ()
      end
end
