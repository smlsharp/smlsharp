(* -*- sml-lex -*- 
 * ml.lex
 * Copyright 1989 by AT&T Bell Laboratories
 *)

structure Tokens = MLLrVals.Tokens
type pos = Tokens.pos
type lexresult = Tokens.token
type lexarg = 
     {
       brack_stack : pos ref list ref,
       comLevel : int ref,
       currentLineNumber : int ref,
       error : (string * pos * pos) -> unit,
       inFormatComment : bool ref,
       lineMap : (int * (pos * pos)) list ref,
       lastNewLinePos : pos ref,
       stream : TextIO.instream, 
       stringBuf : string list ref,
       stringStart : pos ref,
       stringType : bool ref
     }
type arg = lexarg
type token = MLLrVals.Tokens.token

fun newline (arg:arg) yypos =
    (#lineMap arg :=
     (!(#currentLineNumber arg), (!(#lastNewLinePos arg) + 1, yypos))::
     (!(#lineMap arg));
     #currentLineNumber arg := !(#currentLineNumber arg) + 1;
     #lastNewLinePos arg := yypos)
val eof = fn ({comLevel, error, stringStart, lastNewLinePos, ...}:arg) =>
             let
               val pos = Int.max(!stringStart+2, !lastNewLinePos)
             in
               if 0 < !comLevel
               then error ("unclosed comment", !stringStart, pos)
               else ();
               Tokens.EOF(pos,pos)
             end
fun addString (stringBuf,s:string) = stringBuf := s :: (!stringBuf)
fun addChar (stringBuf, c:char) = addString(stringBuf, String.str c)
fun makeString stringBuf = (concat(rev(!stringBuf)) before stringBuf := nil)

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
%s A FC FCC S F Q AQ L LL LLC LLCQ;
%header (
structure MLLex : ARG_LEXER
);
%arg (arg as 
{
  brack_stack,
  comLevel,
  currentLineNumber,
  error,
  inFormatComment,
  lineMap,
  lastNewLinePos,
  stream, 
  stringBuf,
  stringStart,
  stringType
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
positive=[1-9][0-9]*;
frac="."{num};
exp=[eE](~?){num};
real=(~?)(({num}{frac}?{exp})|({num}{frac}{exp}?));
hexnum=[0-9a-fA-F]+;
%%
<INITIAL>{ws}	=> (continue());
<INITIAL>{eol}	=> (newline arg yypos; continue());
<INITIAL>"_overload" => (REJECT());
<INITIAL>"_atom"   => (Tokens.ATOM(yypos,yypos+5));
<INITIAL>"_boxed"   => (Tokens.BOXED(yypos,yypos+6));
<INITIAL>"_cast"   => (Tokens.CAST(yypos,yypos+5));
<INITIAL>"_cdecl"   => (Tokens.CDECL(yypos,yypos+6));
<INITIAL>"_double"   => (Tokens.DOUBLE(yypos,yypos+7));
<INITIAL>"_export"   => (Tokens.EXPORT(yypos,yypos+7));
<INITIAL>"_external"   => (Tokens.EXTERNAL(yypos,yypos+9));
<INITIAL>"_ffiapply"   => (Tokens.FFIAPPLY(yypos,yypos+9));
<INITIAL>"_import"   => (Tokens.IMPORT(yypos,yypos+7));
<INITIAL>"_sizeof"   => (Tokens.SIZEOF(yypos,yypos+7));
<INITIAL>"_stdcall"   => (Tokens.STDCALL(yypos,yypos+8));
<INITIAL>"_useobj"   => (Tokens.USEOBJ(yypos,yypos+7));
<INITIAL>"_"	=> (Tokens.WILD(yypos,yypos+1));
<INITIAL>","	=> (Tokens.COMMA(yypos,yypos+1));
<INITIAL>"{"	=> (Tokens.LBRACE(yypos,yypos+1));
<INITIAL>"}"	=> (Tokens.RBRACE(yypos,yypos+1));
<INITIAL>"["	=> (Tokens.LBRACKET(yypos,yypos+1));
<INITIAL>"#["	=> (Tokens.VECTORSTART(yypos,yypos+1));
<INITIAL>"]"	=> (Tokens.RBRACKET(yypos,yypos+1));
<INITIAL>";"	=> (Tokens.SEMICOLON(yypos,yypos+1));
<INITIAL>"("	=> (if (null(!brack_stack))
                    then ()
                    else inc (hd (!brack_stack));
                    Tokens.LPAREN(yypos,yypos+1));
<INITIAL>")"	=> (if (null(!brack_stack))
                    then ()
                    else if (!(hd (!brack_stack)) = 1)
                         then ( brack_stack := tl (!brack_stack);
                                stringBuf := [];
                                YYBEGIN Q)
                         else dec (hd (!brack_stack));
                    Tokens.RPAREN(yypos,yypos+1));
<INITIAL>"..."		=> (Tokens.DOTDOTDOT(yypos,yypos+3));
<INITIAL>"."		=> (Tokens.DOT(yypos,yypos+1));
<INITIAL>"'"("'"?)("_"|{num})?{id}
			=> (TokenTable.checkTyvar(yytext,yypos));
<INITIAL>{id}	        => (TokenTable.checkId(yytext, yypos));
<INITIAL>{full_sym}+    => (TokenTable.checkSymId(yytext,yypos));
<INITIAL>{sym}+         => (TokenTable.checkSymId(yytext,yypos));
<INITIAL>{quote}        =>
    (error("quotation implementation error", yypos, yypos+1);
     Tokens.BEGINQ(yypos,yypos+1));
<INITIAL>{real}	=> (Tokens.REAL(yytext,yypos,yypos+size yytext));
<INITIAL>[1-9][0-9]* => (Tokens.INT(atoi(yytext, 0),yypos,yypos+size yytext));
<INITIAL>{num}	=> (Tokens.INT0(atoi(yytext, 0),yypos,yypos+size yytext));
<INITIAL>~{num}	=> (Tokens.INT0(atoi(yytext, 0),yypos,yypos+size yytext));
<INITIAL>"0x"{hexnum} => (Tokens.INT0(xtoi(yytext, 2),yypos,yypos+size yytext));
<INITIAL>"~0x"{hexnum} => (Tokens.INT0(Int.~(xtoi(yytext, 3)),yypos,yypos+size yytext));
<INITIAL>"0w"{num} => (Tokens.WORD(atoi(yytext, 2),yypos,yypos+size yytext));
<INITIAL>"0wx"{hexnum} => (Tokens.WORD(xtoi(yytext, 3),yypos,yypos+size yytext));
<INITIAL>\"	=> (stringBuf := [""]; stringStart := yypos;
                    stringType := true; YYBEGIN S; continue());
<INITIAL>\#\"	=> (stringBuf := [""]; stringStart := yypos;
                    stringType := false; YYBEGIN S; continue());
<INITIAL>"(*"	=> (YYBEGIN A; stringStart := yypos; comLevel := 1; continue());
<INITIAL>"(*%"	=> (YYBEGIN FC; inFormatComment := true; stringStart := yypos; comLevel := 1; Tokens.FORMATCOMMENTSTART(yypos, yypos+size yytext));
<INITIAL>"*)"	=>
    (error("unmatched close comment", yypos,yypos+1); continue());
<INITIAL>\h	=>
    (error ("non-Ascii character", yypos,yypos); continue());
<INITIAL>.	=>
    (error ("illegal token", yypos,yypos); continue());
<FC>"(*"	=> (YYBEGIN FCC; inc comLevel; continue());
<A,FCC>"(*"	=> (inc comLevel; continue());
<A,FC>{eol}	=> (newline arg yypos; continue());
<A,FCC>{eol}	=> (newline arg yypos; continue());
<A>"*)" =>
    (dec comLevel;
     if !comLevel=0 then (inFormatComment := false; YYBEGIN INITIAL) else ();
     continue());
<FCC>"*)" => (dec comLevel; if !comLevel=1 then YYBEGIN FC else (); continue());
<FC>"*)" =>
    (dec comLevel;
     if !comLevel=0
     then
       (inFormatComment := false;
        YYBEGIN INITIAL;
        Tokens.FORMATCOMMENTEND(yypos,yypos+size yytext))
     else continue());
<A,FCC>. => (continue());

<FC>^{ws}*"*)" =>
    (dec comLevel;
     if !comLevel=0
     then
       (inFormatComment := false;
        YYBEGIN INITIAL;
        Tokens.FORMATCOMMENTEND(yypos,yypos+size yytext))
     else continue());
<FC>^{ws}*"*" => (continue());
<FC>\"          => (stringBuf := [""]; stringStart := yypos;
                    stringType := true; YYBEGIN S; continue());
<FC>"@ditto"  => (Tokens.DITTOTAG(yypos,yypos+size yytext));
<FC>"@prefix"   => (Tokens.PREFIXTAG(yypos,yypos+size yytext));
<FC>"@formatter"   => (Tokens.FORMATTERTAG(yypos,yypos+size yytext));
<FC>"@params"   => (Tokens.FORMATPARAMSTAG(yypos,yypos+size yytext));
<FC>"@destination" => (Tokens.DESTINATIONTAG(yypos,yypos+size yytext));
<FC>"@header" => (Tokens.HEADERTAG(yypos,yypos+size yytext));
<FC>"@format"   => (Tokens.FORMATTAG(yypos,yypos+size yytext));
<FC>"@format:"{id} => (Tokens.LOCALFORMATTAG(String.extract (yytext, 8, NONE),yypos,yypos+size yytext));
<FC>"\\n" => (Tokens.NEWLINE(yypos,yypos+size yytext));
<FC>("~")?{num}"["    => (Tokens.STARTOFINDENT(atoi(yytext, 0), yypos, yypos+size yytext));
<FC>"+"         => (Tokens.FORMATINDICATOR({space = true, newline = NONE}, yypos,yypos+size yytext));
<FC>"+"?("d"|{positive}) => 
   (let
      val space = String.sub (yytext, 0) = #"+"
      val priorityText =
          if space then String.extract (yytext, 1, NONE) else yytext
      val priority =
          if priorityText = "d"
          then FormatTemplate.Deferred
          else FormatTemplate.Preferred (atoi(priorityText, 0))
      val indicatorArg =
          {space = space, newline = SOME{priority = priority}}
    in
      Tokens.FORMATINDICATOR
      (indicatorArg, yypos, yypos+size yytext)
    end);
<FC>"!"?[LRN]("~")?{num}         => 
      (let
         val (cut, directionCharPos, numStartPos) =
             if #"!" = String.sub (yytext, 0)
             then (true, 1, 2)
             else (false, 0, 1)
         val direction =
             case String.sub (yytext, directionCharPos)
              of #"L" => FormatTemplate.Left
               | #"R" => FormatTemplate.Right
               | #"N" => FormatTemplate.Neutral
               | _ => raise Fail "BUG: illeagal direction"
         val strength = atoi (yytext, numStartPos)
       in
         Tokens.ASSOCINDICATOR
         ({
            cut = cut,
            strength = strength,
            direction = direction
          },
          yypos,
          yypos+size yytext)
       end);
<FC>{id}        => (Tokens.ID(yytext,yypos,yypos+size yytext));
<FC>"'"({id}|{num})"'"  =>
        (Tokens.ID(String.substring(yytext,1,(size yytext)-2),
                   yypos,
                   yypos+size yytext));
<FC>"*"         => (Tokens.ASTERISK(yypos,yypos+size yytext));
<FC>":"         => (Tokens.COLON(yypos,yypos+size yytext));
<FC>","	        => (Tokens.COMMA(yypos,yypos+1));
<FC>"..."	=> (Tokens.DOTDOTDOT(yypos,yypos+3));
<FC>"."		=> (Tokens.DOT(yypos,yypos+1));
<FC>"{"	        => (Tokens.LBRACE(yypos,yypos+1));
<FC>"}"	        => (Tokens.RBRACE(yypos,yypos+1));
<FC>"]"	        => (Tokens.RBRACKET(yypos,yypos+1));
<FC>"("	        => (Tokens.LPAREN(yypos,yypos+1));
<FC>")"	        => (Tokens.RPAREN(yypos,yypos+1));
<FC>"_"         => (Tokens.WILD(yypos,yypos+size yytext));
<FC>{ws}	=> (continue());
<FC>{eol}	=> (newline arg yypos; continue());
<FC>.           =>
   (error("ml lexer: bad character in format comment:"^yytext, yypos,yypos+1);
    continue());

<S>\"	        =>
    (let
       val s = makeString stringBuf
       val s = if size s <> 1 andalso not(!stringType)
               then
                 (error("character constant not length 1", !stringStart,yypos);
                  substring(s^"x",0,1))
               else s
       val t = (s,!stringStart,yypos+1)
     in
       if !inFormatComment then YYBEGIN FC else YYBEGIN INITIAL;
       if !stringType then Tokens.STRING t else Tokens.CHAR t
     end);
<S>{eol}	=> (error ("unclosed string", !stringStart, yypos);
		    newline arg yypos;
		    YYBEGIN INITIAL;
                    Tokens.STRING(makeString stringBuf,!stringStart,yypos));
<S>\\{eol}     	=> (newline arg (yypos+1);
		    YYBEGIN F; continue());
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
<S>\\\^[@-_]	=>
    (addChar(stringBuf, Char.chr(Char.ord(String.sub(yytext,2))-Char.ord #"@"));
     continue());
<S>\\\^.	=>
	(error("illegal control escape; must be one of \
	  \@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_", yypos,yypos+2);
	 continue());
<S>\\[0-9]{3}	=>
 (let val x = Char.ord(String.sub(yytext,1))*100
	     +Char.ord(String.sub(yytext,2))*10
	     +Char.ord(String.sub(yytext,3))
	     -((Char.ord #"0")*111)
  in (if x>255
      then error ("illegal ascii escape", yypos, yypos+4)
      else addChar(stringBuf, Char.chr x);
      continue())
  end);
<S>\\		=>
     (error ("illegal string escape", yypos, yypos+1); continue());

<S>[\000-\031]  =>
    (error ("illegal non-printing character in string", yypos,yypos+1);
     continue());
<S>({idchars}|{some_sym}|\[|\]|\(|\)|{quote}|[,.;^{}])+|.  =>
    (addString(stringBuf,yytext); continue());
<F>{eol}	=> (newline arg yypos; continue());
<F>{ws}		=> (continue());
<F>\\		=> (YYBEGIN S; stringStart := yypos; continue());
<F>.		=> (error ("unclosed string", !stringStart,yypos);
		    YYBEGIN INITIAL;
                    Tokens.STRING(makeString stringBuf,!stringStart,yypos+1));
<Q>"^`"	=> (addString(stringBuf, "`"); continue());
<Q>"^^"	=> (addString(stringBuf, "^"); continue());
<Q>"^"          => (YYBEGIN AQ;
                    let val x = makeString stringBuf
                    in
                    Tokens.OBJL(x,yypos,yypos+(size x))
                    end);
<Q>"`"          => ((* a closing quote *)
                    YYBEGIN INITIAL;
                    let val x = makeString stringBuf
                    in
                      Tokens.ENDQ(x,yypos,yypos+(size x))
                    end);
<Q>{eol}        => (newline arg yypos; addString(stringBuf,"\n"); continue());
<Q>.            => (addString(stringBuf,yytext); continue());

<AQ>{eol}       => (newline arg yypos; continue());
<AQ>{ws}        => (continue());
<AQ>{id}        => (YYBEGIN Q; Tokens.AQID(yytext, yypos,yypos+(size yytext)));
<AQ>{sym}+      => (YYBEGIN Q; Tokens.AQID(yytext, yypos,yypos+(size yytext)));
<AQ>"("         => (YYBEGIN INITIAL;
                    brack_stack := ((ref 1)::(!brack_stack));
                    Tokens.LPAREN(yypos,yypos+1));
<AQ>.           =>
    (error ("ml lexer: bad character after antiquote "^yytext, yypos,yypos+1);
     Tokens.AQID("",yypos,yypos));
