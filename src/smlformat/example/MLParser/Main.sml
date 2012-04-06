(**
 * SMLFormat example: core ML parser
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

  structure CoreMLLrVals = CoreMLLrValsFun(structure Token = LrParser.Token)
  structure CoreMLLex = CoreMLLexFun(structure Tokens = CoreMLLrVals.Tokens)
  structure CoreMLParser =
  JoinWithArg(structure ParserData = CoreMLLrVals.ParserData
	      structure Lex=CoreMLLex
	      structure LrParser=LrParser)

  (***************************************************************************)

  type pos = {fileName : string, line : int, col : int}

  type lexarg =
       {
         columns : int ref,
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

  (***************************************************************************)

  val firstLinePrompt = "->"
  val secondLinePrompt = ">>"

  (***************************************************************************)

  fun printFormat columns formatExpressions =
      let
        val parameter = [SMLFormat.PrinterParameter.Columns columns]
      in
        print (SMLFormat.prettyPrint parameter formatExpressions)
      end

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

  fun printError (message, left, right) =
      raise Absyn.ParseError (left, right, message)

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
          val dummyEOF = CoreMLLrVals.Tokens.EOF dummyLocation
          val dummySEMICOLON = CoreMLLrVals.Tokens.SEMICOLON dummyLocation
        in
        fun oneParse lexer =
	    let 
	      val _ = #doFirstLinePrompt arg := true
	      val (nextToken, lexer') = CoreMLParser.Stream.get lexer
	    in
	      if CoreMLParser.sameToken(nextToken, dummyEOF)
              then raise EndOfParse
	      else
                if CoreMLParser.sameToken(nextToken, dummySEMICOLON)
                then oneParse lexer'
	        else CoreMLParser.parse(0, lexer, printError, ())
	    end
        end

        fun loop lexer = 
	    let
	      val (result, lexer') = oneParse lexer
	    in 
	      case result of
                Absyn.SET(item, value) =>
                (case item of
                   "columns" =>
                   (
                     case Int.fromString value of
                       SOME width => (#columns arg) := width
                     | NONE => print "columns must be integer.\n";
                     loop lexer'
                   )
                 | "verbose" =>
                   (
                     case value of
                       "true" => (#verbose arg) := true
                     | "false" => (#verbose arg) := false
                     | _ => print "verbose must be true or false.\n";
                     loop lexer'
                   )
                 | _ =>
                   (print ("unknown option:" ^ item ^ ".\n"); loop lexer'))
              | Absyn.EXIT => ()
	      | Absyn.USE sourceFileName =>
	        (let
		   val arg =
                       {
                         columns = ref (!(#columns arg)),
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
              | res as (Absyn.DECS (dec, loc)) =>
                let
                  val formatExpressions = Absyn.format_parseresult res
                in
                  if !(#verbose arg) then
                    (
                      print "FormatExpression:\n";
                      app
                      (fn e =>
                          print
                              ((SMLFormat.FormatExpression.toString e) ^ " "))
                      formatExpressions;
                      print "\n";
                      print "Formatted Code:\n"
                    )
                  else ();
                  printFormat (!(#columns arg)) formatExpressions;
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
              Option.getOpt(TextIO.inputLine (#stream arg), "")
            )

        val lexer = CoreMLParser.makeLexer getLine arg
      in
        (loop lexer) 
        handle (exn as Absyn.ParseError _) =>
               (
                 printFormat
                     (!(#columns arg))
                     (SMLFormat.BasicFormatters.format_exn exn);
                 print "\n";
                 flush arg;
                 processInput arg
               )
             | exn =>
               (
                 printFormat
                     (!(#columns arg))
                     (SMLFormat.BasicFormatters.format_exn exn);
                 print "\n";
                 raise exn
               )
      end

  fun main () =
      let
        val initialSource =
            {
              columns = ref 40,
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
            } : lexarg;
      in
        processInput initialSource
        handle EndOfParse => ()
      end
end
