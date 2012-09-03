(* -*- sml-lex -*-
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

type svalue = Tokens.svalue
type ('a,'b) token = ('a,'b) Tokens.token
type pos = int
type lexresult= (svalue, pos) token

type arg =
     {
       comLevel : int ref,
       commonOperations : ParserUtil.PositionMap.operations,
       error : (string * int * int) -> unit,
       stringStart : int ref
     }

val eof = fn ({comLevel, error, stringStart, ...}:arg) =>
             let
               val pos = !stringStart+2
             in
               if 0 < !comLevel
               then error ("unclosed comment", !stringStart, pos)
               else ();
               Tokens.EOF(pos,pos)
             end

fun inc (ri as ref i) = (ri := i+1)
fun dec (ri as ref i) = (ri := i-1)
%% 
%reject
%s A;
%header (functor LinkFileLexFun(structure Tokens : LinkFile_TOKENS));
%arg (arg as 
{
  comLevel,
  commonOperations = {onNewLine, ...},
  error,
  stringStart
} : 
{
  comLevel : int ref,
  commonOperations : ParserUtil.PositionMap.operations,
  error : (string * int * int) -> unit,
  stringStart : int ref
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
<INITIAL>{ws}	=> (continue());
<INITIAL>{eol}	=> (onNewLine yypos; continue());
<INITIAL>"."		=> (Tokens.DOT(yypos,yypos+1));
<INITIAL>"="		=> (Tokens.EQUALOP(yypos,yypos+1));
<INITIAL>"*"		=> (Tokens.ASTERISK(yypos,yypos+1));
<INITIAL>"=>"		=> (Tokens.DARROW(yypos,yypos+2));
<INITIAL>"{"		=> (Tokens.LBRACE(yypos,yypos+1));
<INITIAL>"}"		=> (Tokens.RBRACE(yypos,yypos+1));
<INITIAL>"structure"	=> (Tokens.STRUCTURE(yypos,yypos+size yytext));
<INITIAL>"signature"	=> (Tokens.SIGNATURE(yypos,yypos+size yytext));
<INITIAL>"functor"	=> (Tokens.FUNCTOR(yypos,yypos+size yytext));
<INITIAL>"funsig"	=> (Tokens.FUNSIG(yypos,yypos+size yytext));
<INITIAL>"type"	        => (Tokens.TYPE(yypos,yypos+size yytext));
<INITIAL>"val"	        => (Tokens.VAL(yypos,yypos+size yytext));
<INITIAL>"exception"    => (Tokens.EXCEPTION(yypos,yypos+size yytext));
<INITIAL>{id}	        => (Tokens.ID(yytext,yypos,yypos+size yytext));
<INITIAL>{full_sym}+    => (Tokens.ID(yytext,yypos,yypos+size yytext));
<INITIAL>{sym}+         => (Tokens.ID(yytext,yypos,yypos+size yytext));
<INITIAL>"(*"	=>
                (YYBEGIN A; stringStart := yypos; comLevel := 1; continue());
<INITIAL>"*)"	=> (error ("unmatched close comment",yypos,yypos+1);
                    continue());
<INITIAL>.	=> (error ("illegal token(" ^ yytext ^ ")",yypos,yypos+1);
                    continue());
<A>"(*"		=> (inc comLevel; continue());
<A>{eol}	=> (onNewLine yypos; continue());
<A>"*)" => (
             dec comLevel;
             if !comLevel=0 then YYBEGIN INITIAL else ();
             continue()
           );
<A>.		=> (continue());

