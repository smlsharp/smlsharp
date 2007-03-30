(* -*- sml-lex -*-
 * ml.lex
 *
 * Copyright 1989 by AT&T Bell Laboratories
 *)

structure TokTable = TokenTable(Tokens);

type svalue = Tokens.svalue
type ('a,'b) token = ('a,'b) Tokens.token
type pos = int
type lexresult= (svalue, pos) token

type arg =
     {
       comLevel : int ref,
       commonOperations : ParserUtil.PositionMap.operations,
       docComments : (string * int * int) list ref,
       error : (string * int * int) -> unit,
       stringBuf : string list ref,
       stringStart : pos ref,
       stringType : bool ref
     }

fun addString (buf, s) = buf := (s::(!buf))
fun addChar (buf, s) = buf := (Char.toString s)::(!buf)
fun makeString (buf) = concat (rev (!buf)) before buf := nil

val eof = fn ({comLevel, error, stringStart, ...}:arg) =>
             let
               val pos = !stringStart+2
             in
               if 0 < !comLevel
               then error ("unclosed comment", !stringStart, pos)
               else ();
               Tokens.EOF(pos,pos)
             end

local
  fun cvt radix (s, i) =
      #1(valOf(Int.scan radix Substring.getc (Substring.triml i (Substring.all s))))
      handle Overflow => ((* print "overflow ignored.\n"; *) 0)
in
val atoi = cvt StringCvt.DEC
val xtoi = cvt StringCvt.HEX
end (* local *)
fun inc (ri as ref i) = (ri := i+1)
fun dec (ri as ref i) = (ri := i-1)
%% 
%reject
%s A DC S F;
%header (functor MLLexFun(structure Tokens : ML_TOKENS));
%arg (arg as 
{
  comLevel,
  commonOperations = {onNewLine, ...},
  docComments,
  error,
  stringBuf,
  stringStart,
  stringType
} : 
{
  comLevel : int ref,
  commonOperations : ParserUtil.PositionMap.operations,
  docComments : (string * int * int) list ref,
  error : (string * int * int) -> unit,
  stringBuf : string list ref,
  stringStart : int ref,
  stringType : bool ref
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
<INITIAL>"_overload" => (Tokens.OVERLOAD(yypos,yypos+size yytext));
<INITIAL>"_"	=> (Tokens.WILD(yypos,yypos+1));
<INITIAL>","	=> (Tokens.COMMA(yypos,yypos+1));
<INITIAL>"{"	=> (Tokens.LBRACE(yypos,yypos+1));
<INITIAL>"}"	=> (Tokens.RBRACE(yypos,yypos+1));
<INITIAL>"["	=> (Tokens.LBRACKET(yypos,yypos+1));
<INITIAL>"#["	=> (Tokens.VECTORSTART(yypos,yypos+1));
<INITIAL>"]"	=> (Tokens.RBRACKET(yypos,yypos+1));
<INITIAL>";"	=> (Tokens.SEMICOLON(yypos,yypos+1));
<INITIAL>"("	=> (inc comLevel; Tokens.LPAREN(yypos,yypos+1));
<INITIAL>")"	=> (dec comLevel; Tokens.RPAREN(yypos,yypos+1));
<INITIAL>"."		=> (Tokens.DOT(yypos,yypos+1));
<INITIAL>"..."		=> (Tokens.DOTDOTDOT(yypos,yypos+3));
<INITIAL>"'"("'"?)("_"|{num})?{id}
			=> (TokTable.checkTyvar(yytext,yypos));
<INITIAL>{id}	        => (TokTable.checkId(yytext, yypos));
<INITIAL>"_atom"        => (TokTable.checkId(yytext, yypos));
<INITIAL>"_boxed"       => (TokTable.checkId(yytext, yypos));
<INITIAL>"_cast"        => (TokTable.checkId(yytext, yypos));
<INITIAL>"_cdecl"       => (TokTable.checkId(yytext, yypos));
<INITIAL>"_double"      => (TokTable.checkId(yytext, yypos));
<INITIAL>"_export"      => (TokTable.checkId(yytext, yypos));
<INITIAL>"_ffiapply"    => (TokTable.checkId(yytext, yypos));
<INITIAL>"_import"      => (TokTable.checkId(yytext, yypos));
<INITIAL>"_sizeof"      => (TokTable.checkId(yytext, yypos));
<INITIAL>"_stdcall"     => (TokTable.checkId(yytext, yypos));
<INITIAL>"_useobj"      => (TokTable.checkId(yytext, yypos));
<INITIAL>{full_sym}+    => (TokTable.checkSymId(yytext,yypos));
<INITIAL>{sym}+         => (TokTable.checkSymId(yytext,yypos));
<INITIAL>{real}	=> (Tokens.REAL(yytext,yypos,yypos+size yytext));
<INITIAL>[1-9][0-9]* => (Tokens.INT(atoi(yytext, 0),yypos,yypos+size yytext));
<INITIAL>{num}	=> (Tokens.INT0(atoi(yytext, 0),yypos,yypos+size yytext));
<INITIAL>~{num}	=> (Tokens.INT0(atoi(yytext, 0),yypos,yypos+size yytext));
<INITIAL>"0x"{hexnum} =>
                (Tokens.INT0(xtoi(yytext, 2),yypos,yypos+size yytext));
<INITIAL>"~0x"{hexnum} =>
                (Tokens.INT0(Int.~(xtoi(yytext, 3)),yypos,yypos+size yytext));
<INITIAL>"0w"{num} => (Tokens.WORD(atoi(yytext, 2),yypos,yypos+size yytext));
<INITIAL>"0wx"{hexnum} =>
                (Tokens.WORD(xtoi(yytext, 3),yypos,yypos+size yytext));
<INITIAL>\"	=> (stringBuf := [""]; stringStart := yypos;
                    stringType := true; YYBEGIN S; continue());
<INITIAL>\#\"	=> (stringBuf := [""]; stringStart := yypos;
                    stringType := false; YYBEGIN S; continue());
<INITIAL>"(*"	=>
                (YYBEGIN A; stringStart := yypos; comLevel := 1; continue());
<INITIAL>"(**"{eol}	=>
                (onNewLine yypos;
                 YYBEGIN DC;
                 stringStart := yypos + 3;
                 comLevel := 1; continue());
<INITIAL>"(**"{nrws}	=>
                (YYBEGIN DC;
                 stringStart := yypos + 3;
                 comLevel := 1; continue());
<INITIAL>"*)"	=> (error ("unmatched close comment",yypos,yypos+1);
                    continue());
<INITIAL>\h	=> (error ("non-Ascii character",yypos,yypos); continue());
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

<DC>"(*"	=> (inc comLevel; continue());
<DC>{eol}	=> (onNewLine yypos; addString(stringBuf, "\n"); continue());
<DC>"*)" => (
              dec comLevel;
              if !comLevel=0
              then
                (YYBEGIN INITIAL;
                 docComments :=
                 (makeString stringBuf, !stringStart, yypos-1)::(!docComments))
              else ();
              continue()
            );
<DC>.		=> (addString(stringBuf, yytext); continue());

<S>\"	        => (let
                      val s = makeString stringBuf
(*
                      val s = if size s <> 1 andalso not(!stringType)
                              then (error
                                    (
                                      "character constant not length 1",
                                      !stringStart, yypos
                                    );
                                    substring(s^"x",0,1))
                              else s
*)
                      val t = (s,!stringStart,yypos+1)
                    in
                      YYBEGIN INITIAL;
                      if !stringType then Tokens.STRING t else Tokens.CHAR t
                    end);
<S>{eol}	=> (error ("unclosed string",!stringStart,yypos);
		    onNewLine yypos;
		    YYBEGIN INITIAL;
                    Tokens.STRING(makeString stringBuf,!stringStart,yypos));
<S>\\{eol}     	=> (onNewLine (yypos+1);YYBEGIN F; continue());
<S>\\{ws}   	=> (YYBEGIN F; continue());
<S>\\a		=> (addString(stringBuf, "\007"); continue());
<S>\\b		=> (addString(stringBuf, "\008"); continue());
<S>\\f		=> (addString(stringBuf, "\012"); continue());
<S>\\n		=> (addString(stringBuf, "\010"); continue());
<S>\\r		=> (addString(stringBuf, "\013"); continue());
<S>\\t		=> (addString(stringBuf, "\009"); continue());
<S>\\v		=> (addString(stringBuf, "\011"); continue());
<S>\\\\		=> (addString(stringBuf, "\\"); continue());
<S>\\\"		=> (addString(stringBuf, "\""); continue());
<S>\\\^[@-_]	=> (addChar
                    (
                      stringBuf,
		      Char.chr(Char.ord(String.sub(yytext,2))-Char.ord #"@")
                    );
		    continue());
<S>\\\^.	=>
	(error("illegal control escape; must be one of \
	  \@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_",yypos,yypos+2);
	 continue());
<S>\\[0-9]{3}	=>
 (let
    val x = Char.ord(String.sub(yytext,1))*100
	    +Char.ord(String.sub(yytext,2))*10
	    +Char.ord(String.sub(yytext,3))
	    -((Char.ord #"0")*111)
  in
    if x>255
    then error ("illegal ascii escape",yypos,yypos+4)
    else addChar(stringBuf, Char.chr x);
    continue()
  end);
<S>\\	=> (error ("illegal string escape",yypos,yypos+1); continue());
<S>[\000-\031]  =>
        (error ("illegal non-printing character in string",yypos,yypos+1);
             continue());
<S>({idchars}|{some_sym}|\[|\]|\(|\)|{quote}|[,.;^{}])+|.  =>
                   (addString(stringBuf,yytext); continue());

<F>{eol}	=> (onNewLine yypos; continue());
<F>{ws}		=> (continue());
<F>\\		=> (YYBEGIN S; stringStart := yypos; continue());
<F>.		=> (error ("unclosed string",!stringStart,yypos);
		    YYBEGIN INITIAL;
                    Tokens.STRING(makeString stringBuf,!stringStart,yypos+1));