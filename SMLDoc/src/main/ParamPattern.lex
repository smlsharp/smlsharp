(* -*- sml-lex -*-
 *)
(**
 * lexer of parameter pattern in @params tag of doc comment.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ParamPattern.lex,v 1.2 2007/04/02 09:42:28 katsu Exp $
 *)

type svalue = Tokens.svalue
type ('a,'b) token = ('a,'b) Tokens.token
type pos = int
type lexresult= (svalue, pos) token

type arg = 
     {
       error : (string * int * int) -> unit
     }

val eof = fn _ => Tokens.EOF(0, 0)

%%
%reject
%header (functor ParamPatternLexFun(structure Tokens : ParamPattern_TOKENS));
%arg (arg as 
{
  error
} : 
{
  error : (string * int * int) -> unit
});

idchars=[A-Za-z'_0-9];
id=[A-Za-z]{idchars}*;
ws=("\012"|[\t\ ])*;
nrws=("\012"|[\t\ ])+;
eol=("\013\010"|"\010"|"\013");
%%
<INITIAL>{ws}	=> (continue());
<INITIAL>{eol}	=> (continue());
<INITIAL>"="	=> (Tokens.EQUALOP(yypos,yypos+1));
<INITIAL>","	=> (Tokens.COMMA(yypos,yypos+1));
<INITIAL>"{"	=> (Tokens.LBRACE(yypos,yypos+1));
<INITIAL>"}"	=> (Tokens.RBRACE(yypos,yypos+1));
<INITIAL>"("	=> (Tokens.LPAREN(yypos,yypos+1));
<INITIAL>")"	=> (Tokens.RPAREN(yypos,yypos+1));
<INITIAL>"."	=> (Tokens.DOT(yypos,yypos+1));
<INITIAL>"*"	=> (Tokens.ASTERISK(yypos,yypos+1));
<INITIAL>{id}	=> (Tokens.ID(yytext, yypos, yypos+size yytext));
<INITIAL>.	=> (error ("illegal token(" ^ yytext ^ ")", yypos, yypos+1);
                    continue());
