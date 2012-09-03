(* -*- sml-lex -*- 
 * ml.lex
 * Copyright 1989 by AT&T Bell Laboratories
 *)

type svalue = Tokens.svalue
type ('a,'b) token = ('a,'b) Tokens.token
type pos = {fileName:string, line:int, col:int}
type lexresult = (svalue,pos) Tokens.token

type arg = {
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
  fileName:string, 
  linePos:int ref (* file position at the last nl *),
  ln:int ref, (*  current line number *)
  promptMode:bool, 
  stream:TextIO.instream, 
  stringBuf:string list ref,
  stringStart:pos ref,
  stringType:bool ref,
  verbose : bool ref
}

fun currentPos (p,n,arg:arg) = {fileName = #fileName arg,line = !(#ln arg), col=p - !(#linePos arg) + n}
fun left (p,arg) = currentPos(p,0,arg)
fun right (p,s,arg) = currentPos(p,s,arg)
fun addString (buf,s) = buf := s::(!buf)
fun addChar (buf,s) = buf := Char.toString s::(!buf)
fun makeString (buf) = concat (rev (!buf)) before buf := nil

val eof = fn s => Tokens.EOF (left(0,s),right(0,0,s))
local
  fun cvt radix (s, i) =
      #1(valOf(Int.scan radix Substring.getc (Substring.triml i (Substring.full s))))
in
val atoi = cvt StringCvt.DEC
val xtoi = cvt StringCvt.HEX
end (* local *)

fun inc (ri as ref i) = (ri := i+1)
fun dec (ri as ref i) = (ri := i-1)

%% 
%reject
%s A FC S F Q AQ L LL LLC LLCQ;
%header (functor FormatExpressionLexFun(structure Tokens : FormatExpression_TOKENS));
%arg (args as 
{
  columns,
  space,
  newline,
  guardLeft,
  guardRight,
  maxDepthOfGuards,
  maxWidthOfGuards,
  cutOverTail,

  comLevel,
  doFirstLinePrompt,
  error,
  fileName, 
  linePos,
  ln,
  promptMode, 
  stream, 
  stringBuf,
  stringStart,
  stringType,
  verbose
} : 
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
  error :
  (string * {fileName:string, line:int, col:int} * {fileName:string, line:int, col:int}) -> unit,
  fileName:string, 
  linePos:int ref (* file position at the last nl *),
  ln:int ref, (*  current line number *)
  promptMode:bool, 
  stream:TextIO.instream, 
  stringBuf:string list ref,
  stringStart:{fileName:string, line:int, col:int} ref,
  stringType:bool ref,
  verbose : bool ref
});

idchars=[A-Za-z'_0-9];
id=[A-Za-z]{idchars}*;
ws=("\012"|[\t\ ])*;
nrws=("\012"|[\t\ ])+;
eol=("\013\010"|"\010"|"\013");
some_sym=[!%&$+/:<=>?@~|#*]|\-|\^;
sym={some_sym}|"\\";
quote="`";
full_sym={sym}|{quote};
num=[0-9]+;
frac="."{num};
exp=[eE](~?){num};
real=(~?)(({num}{frac}?{exp})|({num}{frac}{exp}?));
hexnum=[0-9a-fA-F]+;
%%
<INITIAL>{eol}	=> (ln := !ln + 1; linePos := yypos; continue());
<INITIAL>exit	=> (Tokens.EXIT(left(yypos,args), right(yypos,size yytext,args)));
<INITIAL>print	=> (Tokens.PRINT(left(yypos, args), right(yypos,size yytext,args)));
<INITIAL>set	=> (Tokens.SET(left(yypos, args), right(yypos,size yytext,args)));
<INITIAL>use	=> (Tokens.USE(left(yypos, args), right(yypos,size yytext,args)));
<INITIAL>\"          => (stringBuf := [""]; stringStart := left(yypos,args);
                    stringType := true; YYBEGIN S; continue());
<INITIAL>"\\n"  => (Tokens.NEWLINE(left(yypos, args), right(yypos,size yytext,args)));
<INITIAL>("~")?{num}"["    => (Tokens.STARTOFINDENT(atoi(yytext, 0), left(yypos,args), right(yypos,size yytext,args)));
<INITIAL>"+"         => (Tokens.FORMATINDICATOR({space = true, newline = NONE}, left(yypos,args),right(yypos,size yytext,args)));
<INITIAL>"+"?("d"|{num})  =>
   (let
      val space = String.sub (yytext, 0) = #"+"
      val priorityText =
          if space then String.extract (yytext, 1, NONE) else yytext
      val priority =
          if priorityText = "d"
          then SMLFormat.FormatExpression.Deferred
          else SMLFormat.FormatExpression.Preferred (atoi(priorityText, 0))
      val indicatorArg =
          {space = space, newline = SOME{priority = priority}}
    in
      Tokens.FORMATINDICATOR
      (indicatorArg, left(yypos,args), right(yypos,size yytext, args))
    end);
<INITIAL>"!"?[LRN]("~")?{num}         => 
      (let
         val (cut, directionCharPos, numStartPos) =
             if #"!" = String.sub (yytext, 0)
             then (true, 1, 2)
             else (false, 0, 1)
         val direction =
             case String.sub (yytext, directionCharPos)
              of #"L" => SMLFormat.FormatExpression.Left
               | #"R" => SMLFormat.FormatExpression.Right
               | #"N" => SMLFormat.FormatExpression.Neutral
         val strength = atoi (yytext, numStartPos)
       in
         Tokens.ASSOCINDICATOR
         ({
            cut = cut,
            direction = direction,
            strength = strength
          },
          left(yypos,args),
          right(yypos,size yytext,args))
       end);
<INITIAL>";"  => (Tokens.SEMICOLON(left(yypos,args),right(yypos,size yytext,args)));
<INITIAL>"{"   => (Tokens.LBRACE(left(yypos,args),right(yypos,1,args)));
<INITIAL>"}"   => (Tokens.RBRACE(left(yypos,args),right(yypos,1,args)));
<INITIAL>"]"   => (Tokens.RBRACKET(left(yypos,args),right(yypos,1,args)));
<INITIAL>{id}  => (Tokens.ID(yytext,left(yypos,args),right(yypos,size yytext,args)));
<INITIAL>{ws}  => (continue());
<INITIAL>.           => (error 
		       ("ml lexer: bad character:"^yytext,
                        left(yypos, args), right(yypos,1,args))
		       ;
                    continue());
<INITIAL>"(*"	=> (YYBEGIN A; comLevel := 1; continue());
<A>"(*"		=> (comLevel := !comLevel + 1; continue());
<A>"*)" => (comLevel := !comLevel - 1; if !comLevel=0 then YYBEGIN INITIAL else (); continue());
<A>.		=> (continue());

<S>\"	        => (let val s = makeString stringBuf
                        val s = if size s <> 1 andalso not(!stringType)
                                 then (error
                                      ("character constant not length 1",
                                       left(yypos, args), right(yypos,1,args));
                                       substring(s^"x",0,1))
                                 else s
                        val t = (s,!stringStart,right(yypos,1,args))
                    in YYBEGIN INITIAL;
                    Tokens.STRING t
                    end);
<S>{eol}	=> (error ("unclosed string",left(yypos,args),right(yypos,1,args));
		    YYBEGIN INITIAL;
                    Tokens.STRING(makeString stringBuf,!stringStart,right(yypos,1,args)));
<S>\\{eol}     	=> (ln := !ln + 1; 
                    linePos := yypos;
		    error ("unclosed string", left(yypos,args),right(yypos,1,args));
                    continue());
<S>\\{ws}   	=> (error ("unclosed string",left(yypos,args),right(yypos,1,args));
                    continue());
<S>\\a		=> (addString(stringBuf, "\007"); continue());
<S>\\b		=> (addString(stringBuf, "\008"); continue());
<S>\\f		=> (addString(stringBuf, "\012"); continue());
<S>\\n		=> (addString(stringBuf, "\010"); continue());
<S>\\r		=> (addString(stringBuf, "\013"); continue());
<S>\\t		=> (addString(stringBuf, "\009"); continue());
<S>\\v		=> (addString(stringBuf, "\011"); continue());
<S>\\\\		=> (addString(stringBuf, "\\"); continue());
<S>\\\"		=> (addString(stringBuf, "\""); continue());
<S>\\\^[@-_]	=> (addChar(stringBuf,
		    Char.chr(Char.ord(String.sub(yytext,2))-Char.ord #"@"));
		    continue());
<S>\\\^.	=>
	(error ("illegal control escape; must be one of \
	  \@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_", left(yypos,args),right(yypos,2,args));
	 continue());
<S>\\[0-9]{3}	=>
 (let val x = Char.ord(String.sub(yytext,1))*100
	     +Char.ord(String.sub(yytext,2))*10
	     +Char.ord(String.sub(yytext,3))
	     -((Char.ord #"0")*111)
  in (if x>255
      then error ("illegal ascii escape",left(yypos,args),right(yypos,1,args))
      else addChar(stringBuf, Char.chr x);
      continue())
  end);
<S>\\		=> (error ("illegal string escape",left(yypos,args),right(yypos,1,args));
		    continue());


<S>[\000-\031]  =>
            (error ("illegal non-printing character in string",left(yypos,args),right(yypos,1,args));
             continue());
<S>({idchars}|{some_sym}|\[|\]|\(|\)|{quote}|[,.;^{}])+|.  => (addString(stringBuf,yytext); continue());
