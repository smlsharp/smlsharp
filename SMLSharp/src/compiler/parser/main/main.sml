(*
 * Copyright (c) 2006, Tohoku University.
 *
 * a temporary top level loop
 *)


structure Top =struct
structure CoreMLLrVals =
        CoreMLLrValsFun(structure Token = LrParser.Token)

structure CoreMLLex = 
        CoreMLLexFun(structure Tokens = 
                             CoreMLLrVals.Tokens)
structure CoreMLParser=
    JoinWithArg(structure ParserData = CoreMLLrVals.ParserData
	 structure Lex=CoreMLLex
	 structure LrParser=LrParser)


type lexarg = {
  fileName:string, 
  promptMode:bool, 
  stream:TextIO.instream, 
  printInput:bool,
  stringBuf:string list ref,
  stringStart:{fileName:string, line:int, col:int} ref,
  stringType:bool ref,
  comLevel : int ref,
  anyErrors : bool ref,
  ln:int ref,
  linePos:int ref 
}

       fun flush(arg:lexarg) = 
           case TextIO.canInput(TextIO.stdIn, 4096)
             of NONE => (#anyErrors arg := false; #linePos arg := 0; 
                         #ln arg := 1; #comLevel arg := 0;
                         #stringBuf arg := nil;
                         #stringStart arg := {fileName="stdIn",line=0,col=0};
                         #stringType arg := true
                         )
              | (SOME 0) => (#anyErrors arg := false; #linePos arg := 0; 
                         #ln arg := 1; #comLevel arg := 0;
                         #stringBuf arg := nil;
                         #stringStart arg := {fileName="stdIn",line=0,col=0};
                         #stringType arg := true
                         )
              | (SOME _) => (ignore (TextIO.input TextIO.stdIn); flush(arg))

exception  EndOfParse
fun processInput arg =
    let
	val printError = Error.printError


        fun printPrompt promptMode =
          if promptMode then 
            if !Control.doFirstLinePrompt then
      	  (Control.doFirstLinePrompt:=false;
      	   print (!Control.firstLinePrompt);
      	   TextIO.flushOut TextIO.stdOut)
            else(print (!Control.secondLinePrompt);
      	   TextIO.flushOut TextIO.stdOut)
          else ()

	fun getLine  n = (printPrompt(#promptMode arg); 
			  let
			      val s = TextIO.inputLine (#stream arg)
			  in
			      (if (#printInput arg) then 
				  (TextIO.output (TextIO.stdOut, s);
				   TextIO.flushOut TextIO.stdOut)
			       else ();
			       s)
			  end)
	val lexer = CoreMLParser.makeLexer getLine arg
	val dummyEOF = CoreMLLrVals.Tokens.EOF({fileName="",line=0,col=0},
					     {fileName="",line=0,col=0})
	val dummySEMICOLON = CoreMLLrVals.Tokens.SEMICOLON({fileName="",line=0,col=0},
							 {fileName="",line=0,col=0})
	fun oneParse lexer =
	    let 
		val _ = Control.doFirstLinePrompt := true
		val (nextToken,lexer') = CoreMLParser.Stream.get lexer
	    in
		if CoreMLParser.sameToken(nextToken,dummyEOF) then raise EndOfParse
		else if CoreMLParser.sameToken(nextToken,dummySEMICOLON) then
                        oneParse lexer'
		     else CoreMLParser.parse(0,lexer,printError,())
	    end

	fun loop lexer = 
	    let
		val (r,lexer') = oneParse lexer
	    in 
		case r of
		    Absyn.USE s =>
			(let val news = TextIO.openIn s
			    val arg = {fileName=s,
				       promptMode=false,
				       stream=news,
				       printInput=false,
				       ln=ref 1,
                                       stringBuf = ref nil : string list ref,
                                       stringStart=ref {fileName=s,line=0,col=0}: {fileName:string, line:int, col:int} ref,
                                       stringType=ref true,
                                       comLevel=ref 0,
                                       anyErrors=ref false,
				       linePos=ref 0} : lexarg
			in
			    (processInput arg) 
			end handle EndOfParse => loop lexer'
		      | IO.Io s=> 
			    (let
				 val s1 = (#function s)
				 val s2 = (#name s)
				 val ex = (#cause s)
				 val mes = case ex of
				     OS.SysErr (s,SOME e) => 
					 "GenLex error: use clause ignored. " ^ OS.errorMsg e ^ " : " ^ s2
				   | _ => "IO error " ^ s1 ^ " " ^ s2
			    in
				(TextIO.output(TextIO.stdOut,mes ^ "\n");
				 TextIO.flushOut TextIO.stdOut;
 				 loop lexer')
			    end))
		  | Absyn.DECS (dec,loc) => 
                      (PrintAbsyn.printDecs r;
                       loop lexer')
	    end
    in
    	(loop lexer) 
          handle CoreMLParser.ParseError => (flush(arg);
					     processInput arg)
    end

val initialSource = {fileName="stdIn",stream=TextIO.stdIn,ln = ref 1, linePos= ref 1,
		     promptMode = true,
		     printInput = false,
                     comLevel=ref 0,
                     anyErrors = ref false,
		     stringBuf = ref nil : string list ref,
                     stringStart = ref {fileName="stdIn",line=0,col=0},
		     stringType = ref true
} : lexarg

fun top () = 
    processInput initialSource
    handle  EndOfParse => ()
end
