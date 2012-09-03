(* -*- sml-lex -*-
 * lexical structures of Core ML
 *   the part of constant specifications is based on 
 *   that of the SML New Jersye implementation
 * Copyright 2001
 * Atsushi Ohori 
 * JAIST, Ishikawa Japan. 
 *)

structure Tokens = Tokens

type svalue = Tokens.svalue
type ('a,'b) token = ('a,'b) Tokens.token
type pos = {fileName:string, line:int, col:int}
type lexresult= (svalue,pos) token

type arg = {
  columns : int ref,
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
%%
%s A S F;
%header (functor CoreMLLexFun(structure Tokens: CoreML_TOKENS));
%arg (args as 
{
  columns,
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

quote="'";
underscore="\_";
alpha=[A-Za-z];
digit=[0-9];
idchars={alpha}|{digit}|{quote}|{underscore};
id={alpha}{idchars}*;
ws=("\012"|[\t\ ])*;
eol=("\013\010"|"\010"|"\013");
sym=[!%&$+/:<=>?@~|#*\\]|\-|\^;
symbol={sym}|\\;
num=[0-9]+;
frac="."{num};
exp=[eE](~?){num};
real=(~?)(({num}{frac}?{exp})|({num}{frac}{exp}?));
hexnum=[0-9a-fA-F]+;
%%
<INITIAL>{ws}		=> (continue());
<INITIAL>{eol}		=> (ln := !ln + 1; linePos := yypos; continue ());
<INITIAL>"andalso"	=> (Tokens.ANDALSO (left(yypos,args),right(yypos,7,args)));
<INITIAL>"and"	        => (Tokens.AND (left(yypos,args),right(yypos,3,args)));
<INITIAL>"as"		=> (Tokens.AS (left(yypos,args),right(yypos,2,args)));
<INITIAL>"case"		=> (Tokens.CASE (left(yypos,args),right(yypos,4,args)));
<INITIAL>"datatype"	=> (Tokens.DATATYPE (left(yypos,args),right(yypos,1,args)));
<INITIAL>"do"		=> (Tokens.DO (left(yypos,args),right(yypos,1,args)));
<INITIAL>"else"		=> (Tokens.ELSE (left(yypos,args),right(yypos,1,args)));
<INITIAL>"end"		=> (Tokens.END (left(yypos,args),right(yypos,1,args)));
<INITIAL>"exception"	=> (Tokens.EXCEPTION (left(yypos,args),right(yypos,1,args)));
<INITIAL>"fn"		=> (Tokens.FN (left(yypos,args),right(yypos,1,args)));
<INITIAL>"fun"		=> (Tokens.FUN (left(yypos,args),right(yypos,1,args)));
<INITIAL>"handle"	=> (Tokens.HANDLE (left(yypos,args),right(yypos,1,args)));
<INITIAL>"if"		=> (Tokens.IF (left(yypos,args),right(yypos,1,args)));
<INITIAL>"in"		=> (Tokens.IN (left(yypos,args),right(yypos,1,args)));
<INITIAL>"infix"	=> (Tokens.INFIX (left(yypos,args),right(yypos,1,args)));
<INITIAL>"infixr"	=> (Tokens.INFIXR (left(yypos,args),right(yypos,1,args)));
<INITIAL>"nonfix"	=> (Tokens.NONFIX (left(yypos,args),right(yypos,1,args)));
<INITIAL>"let"		=> (Tokens.LET (left(yypos,args),right(yypos,1,args)));
<INITIAL>"local"	=> (Tokens.LOCAL (left(yypos,args),right(yypos,1,args)));
<INITIAL>"of"		=> (Tokens.OF (left(yypos,args),right(yypos,1,args)));
<INITIAL>"op"		=> (Tokens.OP (left(yypos,args),right(yypos,1,args)));
<INITIAL>"orelse"	=> (Tokens.ORELSE (left(yypos,args),right(yypos,1,args)));
<INITIAL>"raise"	=> (Tokens.RAISE (left(yypos,args),right(yypos,1,args)));
<INITIAL>"rec"	        => (Tokens.REC (left(yypos,args),right(yypos,1,args)));
<INITIAL>"then"		=> (Tokens.THEN (left(yypos,args),right(yypos,1,args)));
<INITIAL>"type"		=> (Tokens.TYPE (left(yypos,args),right(yypos,1,args)));
<INITIAL>"use"		=> (Tokens.USE (left(yypos,args),right(yypos,1,args)));
<INITIAL>"set"	        => (Tokens.SET (left(yypos,args),right(yypos,1,args)));
<INITIAL>"exit"	        => (Tokens.EXIT(left(yypos,args),right(yypos,1,args)));
<INITIAL>"val"		=> (Tokens.VAL (left(yypos,args),right(yypos,1,args)));
<INITIAL>"while"	=> (Tokens.WHILE (left(yypos,args),right(yypos,1,args)));
<INITIAL>"*"		=> (Tokens.ASTERISK(left(yypos,args),right(yypos,1,args)));
<INITIAL>"#"		=> (Tokens.HASH(left(yypos,args),right(yypos,1,args)));
<INITIAL>"("		=> (Tokens.LPAREN(left(yypos,args),right(yypos,1,args)));
<INITIAL>")"		=> (Tokens.RPAREN(left(yypos,args),right(yypos,1,args)));
<INITIAL>","		=> (Tokens.COMMA(left(yypos,args),right(yypos,1,args)));
<INITIAL>"->"		=> (Tokens.ARROW (left(yypos,args),right(yypos,2,args)));
<INITIAL>"."		=> (Tokens.PERIOD (left(yypos,args),right(yypos,1,args)));
<INITIAL>"..."		=> (Tokens.PERIODS (left(yypos,args),right(yypos,3,args)));
<INITIAL>":"		=> (Tokens.COLON(left(yypos,args),right(yypos,1,args)));
<INITIAL>";"		=> (Tokens.SEMICOLON(left(yypos,args),right(yypos,1,args)));
<INITIAL>"="		=> (Tokens.EQ(left(yypos,args),right(yypos,1,args)));
<INITIAL>"=>"		=> (Tokens.DARROW (left(yypos,args),right(yypos,1,args)));
<INITIAL>"["		=> (Tokens.LBRACKET(left(yypos,args),right(yypos,1,args)));
<INITIAL>"]"		=> (Tokens.RBRACKET(left(yypos,args),right(yypos,1,args)));
<INITIAL>"_"		=> (Tokens.UNDERBAR(left(yypos,args),right(yypos,1,args)));
<INITIAL>"{"		=> (Tokens.LBRACE(left(yypos,args),right(yypos,1,args)));
<INITIAL>"|"		=> (Tokens.BAR(left(yypos,args),right(yypos,1,args)));
<INITIAL>"}"		=> (Tokens.RBRACE(left(yypos,args),right(yypos,1,args)));
<INITIAL>"'"{id}	=> (Tokens.TYVAR(yytext,left(yypos,args),right(yypos,String.size yytext,args)));
<INITIAL>{id}		=> (Tokens.ID( yytext,left(yypos,args),right(yypos,String.size yytext,args)));
<INITIAL>{num}		=> (Tokens.INT(atoi(yytext, 0),left(yypos,args),right(yypos,String.size yytext,args)));
<INITIAL>~{num}	        => (Tokens.INT(atoi(yytext, 0),left(yypos,args),right(yypos,String.size yytext,args)));
<INITIAL>{symbol}+	=> (Tokens.ID(yytext,left(yypos,args),right(yypos,String.size yytext,args)));
<INITIAL>{real}	        => (Tokens.REAL(yytext,left(yypos,args),right(yypos,String.size yytext,args)));
<INITIAL>"0x"{hexnum}   => (Tokens.INT(xtoi(yytext, 2),left(yypos,args),right(yypos,String.size yytext,args)));
<INITIAL>"~0x"{hexnum} => (Tokens.INT(~(xtoi(yytext, 3)),left(yypos,args),right(yypos,String.size yytext,args)));
<INITIAL>\"	=> (stringBuf := nil; 
                    stringStart := left(yypos,args) ;
                    stringType := true; 
                    YYBEGIN S; continue());
<INITIAL>\#\"	=> (stringBuf := nil; 
                    stringStart := left(yypos,args) ;
                    stringType := false; 
                    YYBEGIN S; continue());
<INITIAL>"(*"	=> (YYBEGIN A; comLevel := 1; continue());
<INITIAL>"*)"	=> (error ("unmatched close comment",left(yypos,args),right(yypos,1,args));
		    continue());
<INITIAL>\h	=> (error ("non-Ascii character",left(yypos,args),right(yypos,1,args));
		    continue());
<INITIAL>.	=> (error ("illegal token",left(yypos,args),right(yypos,1,args));
		    continue());
<A>"(*"		=> (comLevel := !comLevel + 1; continue());
<A>{eol}	=> (#ln args := !(#ln args) + 1; 
                    #linePos args := yypos; continue ());
<A>"*)" => (comLevel := !comLevel - 1; if !comLevel=0 then YYBEGIN INITIAL else (); continue());
<A>.		=> (continue());
<S>\"	        => (let val s = makeString stringBuf
                        val s = if size s <> 1 andalso not(!stringType)
                                   then (error ("character constant not length 1",
				                left(yypos,args),right(yypos,1,args));
                                         s)
                                 else s
                        val t = (s,!stringStart,right(yypos,1,args))
                    in YYBEGIN INITIAL;
                       if !stringType then Tokens.STRING t else Tokens.CHAR t
                    end);
<S>{eol}	=> (error ("unclosed string",left(yypos,args),right(yypos,1,args));
                    ln := !ln + 1; linePos := yypos; 
		    YYBEGIN INITIAL; Tokens.STRING(makeString stringBuf,!stringStart,right(yypos,1,args)));
<S>\\{eol}     	=> (ln := !ln + 1; linePos := yypos; 
		    YYBEGIN F; continue());
<S>\\{ws}   	=> (YYBEGIN F; continue());
<S>\\a		=> (addString(stringBuf, "\\a"(*"\007"*)); continue());
<S>\\b		=> (addString(stringBuf, "\\b"(*"\008"*)); continue());
<S>\\f		=> (addString(stringBuf, "\\f"(*"\012"*)); continue());
<S>\\n		=> (addString(stringBuf, "\\n"(*"\010"*)); continue());
<S>\\r		=> (addString(stringBuf, "\\r"(*"\013"*)); continue());
<S>\\t		=> (addString(stringBuf, "\\t"(*"\009"*)); continue());
<S>\\v		=> (addString(stringBuf, "\\v"(*"\011"*)); continue());
<S>\\\\		=> (addString(stringBuf, "\\\\"(*"\\"*)); continue());
<S>\\\"		=> (addString(stringBuf, "\\\""(*"\""*)); continue());
<S>\\\^[@-_]	=> (addChar(stringBuf,
			Char.chr(Char.ord(String.sub(yytext,2))-Char.ord #"@"));
		    continue());
<S>\\\^.	=>
	(error("illegal control escape; must be one of \
	  \@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_",left(yypos,args),right(yypos,1,args));
	 continue());
<S>\\[0-9]{3}	=>
 (let val x = Char.ord(String.sub(yytext,1))*100
	     +Char.ord(String.sub(yytext,2))*10
	     +Char.ord(String.sub(yytext,3))
	     -((Char.ord #"0")*111)
  in (if x>255
      then (error ("illegal ascii escape",left(yypos,args),right(yypos,1,args)))
      else addChar(stringBuf, Char.chr x);
      continue())
  end);
<S>\\		=> (error ("illegal string escape",left(yypos,args),right(yypos,1,args));
		    continue());
<S>[\000-\031]  => (error ("illegal non-printing character in string",left(yypos,args),right(yypos,1,args));
                    continue());
<S>({idchars}|{sym}|\[|\]|\(|\)|{quote}|[,.;^{}])+|.  => (addString(stringBuf,yytext); continue());
<F>{eol}	=> (ln := !ln + 1; linePos := yypos; continue());
<F>{ws}		=> (continue());
<F>\\		=> (YYBEGIN S; continue());
<F>.		=> (error ("unclosed string",left(yypos,args),right(yypos,1,args));
		    YYBEGIN INITIAL; Tokens.STRING(makeString stringBuf,!stringStart,right(yypos,1,args)));
.       => (Tokens.SPECIAL(yytext,left(yypos,args),right(yypos,1,args)));
