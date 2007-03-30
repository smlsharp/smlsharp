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
fun topLevel (fixenv,context) arg =
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

	fun loop (fixenv,context:Types.context)  = 
	    let
		val (r,lexer') = oneParse (!currentLexer)
		val _ = currentLexer := lexer'
	    in 
		case r of
		    Absyn.USE s => 
			(let 
			    val _ = pushInput()
			    val _ =  useInput s
			in loop (fixenv,context)
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
				   loop (fixenv,context))
			     end))
		  | Absyn.DECS (dec,loc) =>
		     let val _ = if !Control.printSource then
			             (print "Source expr:\n";
				      PrintAbsyn.printDecs r;
				      ())
				 else ()
			 val (pldec,fixenv) = Elab.elabDecs fixenv dec
			 val _ = if !Control.printElab then
			             (print "Elaborated to:\n";
				      map (fn y => print ((PrintPl.pldecToString y) ^ "\n")) pldec;
				      ())
				 else ()
                         val ptdecs = map (SetTvars.setDecl SEnv.empty) pldec
			 val (newContext, ptdecls) = TypeInf.typeinfTop context ptdecs
			 val _ = (print "Statically evaluated to:\n";
                                  map (fn x => print (PrintTP.tpdecToString nil x ^ "\n")) ptdecls;
                                  print "Generated static bindings:\n";
                                  print (PrintType.contextToString newContext);
                                  print "\n"
                                  )
			 val ( binds', warnings ) = ParallelMatchComp.tpdecsToRcdecs ptdecls
			 val _ = if null warnings
			         then ()
				 else app (fn warning => 
					   (print (SMLFormat.prettyPrint
                                                       [SMLFormat.Columns(!Control.printWidth)]
						   (MatchError.format_errorInfo warning)); TextIO.print "\n")) 
				   warnings
			 val _ = (print "Match Compiled to:\n";
				  map(fn x=> print (PrintRcalc.rcdecToString nil x ^ "\n")) binds')
			 val binds'  = RecordCompile.rcompDeclsTop binds'
			 val _ = ( print "Record Compiled to:\n";
				  map (fn x => print (PrintTL.tldecToString nil x ^ "\n")) binds')
			 val binds'  = OptimizeLambda.optimizeTopDecs VEnv.empty  binds'
			 val _ = ( print "Optimized to:\n";
				  map (fn x => print (PrintTL.tldecToString nil x ^ "\n")) binds')
		     in
                       loop (fixenv,
                             TypeinfBase.updateContext(newContext, context))
		     end
		 handle CoreMLParser.ParseError => 
		     (flush();loop (fixenv,context))
		      | Control.Bug s => (print (s^"\n");
					  flush();
					  loop (fixenv,context))
	    end
    in
	(loop  (fixenv,context))
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
    TypeinfBase.initialContext
     )
    initialSource;
end;
