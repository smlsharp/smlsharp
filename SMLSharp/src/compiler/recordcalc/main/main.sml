(*
 * Copyright (c) 2006, Tohoku University.
 *
 * a temporary top level loop
 *)

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


structure Top = struct
exception  EndOfParse
exception  EndOfInput
fun topLevel (fixenv,tcenv,varenv) arg =
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
	val dummyEOF = CoreMLLrVals.Tokens.EOF({fileName="",line=0,col=0},
					       {fileName="",line=0,col=0})
	val dummySEMICOLON = CoreMLLrVals.Tokens.SEMICOLON({fileName="",line=0,col=0},
							   {fileName="",line=0,col=0})
	fun getLine (arg:lexarg) n = 
	    (printPrompt(#promptMode arg); 
	     let
		 val s = TextIO.inputLine (#stream arg)
	     in
		 (if (#printInput arg) then 
		      (TextIO.output (TextIO.stdOut, s);
		       TextIO.flushOut TextIO.stdOut)
		  else ();
		      s)
	     end)

	val currentArg = ref arg
	val currentLexer = ref (CoreMLParser.makeLexer (getLine arg) arg)

	fun useInput sname = 
	let
	    val arg = {fileName=sname,
		       promptMode=false,
		       stream=TextIO.openIn sname,
		       printInput=false,
		       ln=ref 1,
		       stringBuf = ref nil : string list ref,
		       stringStart=ref {fileName=sname,line=0,col=0}
		       : {fileName:string, line:int, col:int} ref,
		       stringType=ref true,
		       comLevel=ref 0,
		       anyErrors=ref false,
		       linePos=ref 0} : lexarg
	    val lexer = CoreMLParser.makeLexer (getLine arg) arg
	in
	    (currentArg := arg; currentLexer := lexer)
	end

	val inputStack = ref [(!currentArg,!currentLexer)]

        fun pushInput () = inputStack := (!currentArg,!currentLexer) :: (!inputStack)

        fun popInput () = 
	    case !inputStack of
		nil => raise EndOfInput
	      |  ((a,l)::t) => (inputStack := t;
				currentArg := a;
				currentLexer := l)

       val _ = popInput()

       fun flush () = 
	   if (#fileName (!currentArg)) = "stdIn" then
           case TextIO.canInput(TextIO.stdIn, 4096)
             of NONE => currentLexer:= CoreMLParser.makeLexer (getLine (!currentArg)) (!currentArg)
              | (SOME 0) =>currentLexer:= CoreMLParser.makeLexer (getLine (!currentArg)) (!currentArg)
              | (SOME _) => (ignore (TextIO.input TextIO.stdIn); flush())
	   else
	       currentLexer:= CoreMLParser.makeLexer (getLine (!currentArg)) (!currentArg)

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
	handle EndOfParse => (case #fileName (!currentArg) of
				  "stdIn" =>()
				| _ =>TextIO.closeIn (#stream (!currentArg));
				      popInput();
				      oneParse (!currentLexer))
	     | CoreMLParser.ParseError => (flush();oneParse (!currentLexer))

	fun loop (fixenv,tcenv,varenv)  = 
	    let
		val (r,lexer') = oneParse (!currentLexer)
		val _ = currentLexer := lexer'
	    in 
		case r of
		    Absyn.USE s => 
			(let 
			    val _ = pushInput()
			    val _ =  useInput s
			in loop (fixenv,tcenv,varenv)
			end
        	     handle IO.Io s=> 
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
				   popInput();
				   loop (fixenv,tcenv,varenv))
			     end))
		  | Absyn.DECS (dec,loc) =>
		     let val _ = if !Control.printSource then
			             (print "Source expr:\n";
				      map (fn y => map (fn x => (print (x ^ "\n"))) 
					   (PrintAbsyn.decToString y))
				      dec;
				      ())
				 else ()
			 val (pldec,fixenv) = Elab.elabDecs fixenv dec
			 val _ = if !Control.printElab then
			             (print "Elaborated to:\n";
				      map (fn y => map (fn x => (print (x ^ "\n")))
					   (PrintPl.pldecToString y))
				      pldec;
				      ())
				 else ();
			 val (tcenv1,varenv1,binds) =
			     TypeInf.typeinfTop (tcenv,varenv) pldec
			 val _ = if !Control.printETerm then
			            (print "Statically evaluated to:\n";
				     map (fn x => print (PrintTP.tpdecToString nil x ^ "\n")) binds;
				     print "Generated static bindings:\n";
				     print (PrintType.varenvToString nil varenv1))
				 else ();

			 val binds' = map MatchCompile.tpdecToTldec binds
			 val _ = (print "Match Compiled to:\n";
				  map (fn x => print (PrintRcalc.rcdecToString nil x ^ "\n")) binds')
		     in
                       loop (fixenv,
			     StaticEnv.mergeTcenv (tcenv1,tcenv),
			     StaticEnv.mergeVarenv (varenv1,varenv))
		     end
		 handle CoreMLParser.ParseError => 
		     (flush();loop (fixenv,tcenv,varenv))
		      | Control.Bug s => (print (s^"\n");
					  flush();
					  loop (fixenv,tcenv,varenv))
	    end
    in
	(loop  (fixenv,tcenv,varenv))
	handle EndOfInput =>()
	     | Control.Bug s => print s
    end

val initialSource = {fileName="stdIn",stream=TextIO.stdIn,ln = ref 1, linePos= ref 1,
		     promptMode = true,
		     printInput = false,
                     comLevel=ref 0,
                     anyErrors = ref false,
		     stringBuf = ref nil : string list ref,
                     stringStart = ref {fileName="stdIn",line=0,col=0},
		     stringType = ref true
} : lexarg;
fun top () =
    topLevel
    (StaticEnv.initialFixenv,
     StaticEnv.initialTcenv,
     StaticEnv.initialVarenv
     )
    initialSource;

end;
(*
Top.top();
*)
