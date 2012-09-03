(* -*- sml-lex -*-
 *
 * cm.lex
 *
 * lexical analysis (ML-Lex specification) for CM description files
 *
 * (C) 1999 Lucent Technologies, Bell Laboratories
 *
 * Author: Matthias Blume (blume@kurims.kyoto-u.ac.jp)
 *)

structure S = CMSemantic

type svalue = Tokens.svalue
type pos = int

type ('a, 'b) token = ('a, 'b) Tokens.token
type lexresult = (svalue, pos) token

type lexarg = {
	       enterC: unit -> unit,
	       leaveC: unit -> bool,
	       newS: pos -> unit,
	       addS: char -> unit,
	       addSC: string * int -> unit,
	       addSN: string * pos -> unit,
	       getS: pos * (string * pos * pos -> lexresult) -> lexresult,
	       handleEof: unit -> pos,
               commonOperations : ParserUtil.PositionMap.operations,
               error : (string * int * int) -> unit
	      }

type arg = lexarg

fun eof (arg: lexarg) = let
    val pos = #handleEof arg ()
in
    Tokens.EOF (pos, pos)
end

fun errorTok (t, p) = Tokens.ERROR ("error is ignored.", p + 1, p + size t)

val cm_ids = [("Group", Tokens.GROUP),
	      ("GROUP", Tokens.GROUP),
	      ("group", Tokens.GROUP),
	      ("Library", Tokens.LIBRARY),
	      ("LIBRARY", Tokens.LIBRARY),
	      ("library", Tokens.LIBRARY),
	      ("alias", Tokens.ALIAS),
	      ("Alias", Tokens.ALIAS),
	      ("ALIAS", Tokens.ALIAS),
              ("IS", Tokens.IS),
	      ("is", Tokens.IS),
	      ("*", Tokens.STAR),
	      ("-", Tokens.DASH),
	      ("Source", Tokens.SOURCE),
	      ("SOURCE", Tokens.SOURCE),
	      ("source", Tokens.SOURCE)]

val ml_ids = [("structure", Tokens.STRUCTURE),
	      ("signature", Tokens.SIGNATURE),
	      ("functor", Tokens.FUNCTOR),
	      ("funsig", Tokens.FUNSIG)]

val pp_ids = [("defined", Tokens.DEFINED),
	      ("div", fn (x, y) => Tokens.MULSYM (S.DIV, x, y)),
	      ("mod", fn (x, y) => Tokens.MULSYM (S.MOD, x, y)),
	      ("andalso", Tokens.ANDALSO),
	      ("orelse", Tokens.ORELSE),
	      ("not", Tokens.NOT)]

fun idToken (t, p, idlist, default, chstate) =
    case List.find (fn (id, _) => id = t) ml_ids of
	SOME (_, tok) => (chstate (); tok (p, p + size t))
      | NONE =>
	    (case List.find (fn (id, _) => id = t) idlist of
		 SOME (_, tok) => tok (p, p + size t)
	       | NONE => default (t, p, p + size t))

(* states:

     INITIAL -> C
       |
       +------> P -> PC
       |        |
       |        +--> PM -> PMC
       |
       +------> M -> MC
       |
       +------> S -> SS

   "C"  -- COMMENT
   "P"  -- PREPROC
   "M"  -- MLSYMBOL
   "S"  -- STRING
   "SS" -- STRINGSKIP
*)

%%

%s C P PC PM PMC M MC S SS;

%header(functor CMLexFun (structure Tokens: CM_TOKENS));

%arg ({ enterC, leaveC,
        newS, addS, addSC, addSN, getS,
        handleEof,
        commonOperations = {onNewLine, ...} : ParserUtil.PositionMap.operations,
	error});

idchars=[A-Za-z'_0-9];
id=[A-Za-z]{idchars}*;
cmextrachars=[.;,!%&$+/<=>?@~|#*]|\-|\^;
cmidchars={idchars}|{cmextrachars};
cmid={cmidchars}+;
ws=("\012"|[\t\ ]);
eol=("\013\010"|"\013"|"\010");
neol=[^\013\010];
sym=[!%&$+/:<=>?@~|#*]|\-|\^|"\\";
digit=[0-9];
sharp="#";
%%

<INITIAL>"(*"           => (enterC (); YYBEGIN C; continue ());
<P>"(*"                 => (enterC (); YYBEGIN PC; continue ());
<PM>"(*"                => (enterC (); YYBEGIN PMC; continue ());
<M>"(*"                 => (enterC (); YYBEGIN MC; continue ());

<C,PC,PMC,MC>"(*"       => (enterC (); continue ());

<C>"*)"                 => (if leaveC () then YYBEGIN INITIAL else ();
			    continue ());
<PC>"*)"                => (if leaveC () then YYBEGIN P else ();
			    continue ());
<PMC>"*)"                => (if leaveC () then YYBEGIN PM else ();
			    continue ());
<MC>"*)"                => (if leaveC () then YYBEGIN M else ();
			    continue ());
<C,PC,PMC,MC>{eol}      => (onNewLine yypos; continue ());
<C,PC,PMC,MC>.          => (continue ());

<INITIAL,P,PM,M>"*)"	=> (error ("unmatched comment delimiter", yypos, yypos+2);
			    continue ());

<INITIAL>"\""		=> (YYBEGIN S; newS yypos; continue ());

<S>"\\"{eol}	        => (YYBEGIN SS; onNewLine (yypos + 1); continue ());

<S>"\""		        => (YYBEGIN INITIAL; getS (yypos, Tokens.FILE_NATIVE));
<S>{eol}		=> (onNewLine yypos;
			    error ("illegal linebreak in string",
                                   yypos, yypos + size yytext);
			    continue ());

<S>.		        => (addS (String.sub (yytext, 0)); continue ());

<SS>{eol}	        => (onNewLine yypos; continue ());
<SS>{ws}+	        => (continue ());
<SS>"\\"	        => (YYBEGIN S; continue ());
<SS>.		        => (error 
			     ("illegal character in stringskip " ^ yytext,
                              yypos, yypos+1);
			    continue ());

<INITIAL,P>"("		=> (Tokens.LPAREN (yypos, yypos + 1));
<INITIAL,P>")"		=> (Tokens.RPAREN (yypos, yypos + 1));
<INITIAL>":"		=> (Tokens.COLON (yypos, yypos + 1));
<P>"+"		        => (Tokens.ADDSYM (S.PLUS, yypos, yypos + 1));
<P>"-"		        => (Tokens.ADDSYM (S.MINUS, yypos, yypos + 1));
<P>"*"		        => (Tokens.MULSYM (S.TIMES, yypos, yypos + 1));
<P>"<>"		        => (Tokens.EQSYM (S.NE, yypos, yypos + 2));
<P>"!="                 => (Tokens.EQSYM (S.NE, yypos, yypos+2));
<P>"<="		        => (Tokens.INEQSYM (S.LE, yypos, yypos + 2));
<P>"<"		        => (Tokens.INEQSYM (S.LT, yypos, yypos + 1));
<P>">="		        => (Tokens.INEQSYM (S.GE, yypos, yypos + 2));
<P>">"		        => (Tokens.INEQSYM (S.GT, yypos, yypos + 1));
<P>"=="                 => (Tokens.EQSYM (S.EQ, yypos, yypos + 2));
<P>"="		        => (Tokens.EQSYM (S.EQ, yypos, yypos + 1));
<P>"~"		        => (Tokens.TILDE (yypos, yypos + 1));

<P>{digit}+	        => (Tokens.NUMBER
			     (valOf (Int.fromString yytext)
			      handle _ =>
				  (error 
				     ("number too large",
                                      yypos, yypos + size yytext);
				   0),
			      yypos, yypos + size yytext));

<P>{id}                 => (idToken (yytext, yypos, pp_ids, Tokens.CM_ID,
				     fn () => YYBEGIN PM));
<P>"/"                  => (Tokens.MULSYM (S.DIV, yypos, yypos + 1));
<P>"%"                  => (Tokens.MULSYM (S.MOD, yypos, yypos + 1));
<P>"&&"                 => (Tokens.ANDALSO (yypos, yypos + 2));
<P>"||"                 => (Tokens.ORELSE (yypos, yypos + 2));
<P>"!"                  => (Tokens.NOT (yypos, yypos + 1));

<M>({id}|{sym}+)        => (YYBEGIN INITIAL;
			    Tokens.ML_ID (yytext, yypos, yypos + size yytext));
<PM>({id}|{sym}+)       => (YYBEGIN P;
			    Tokens.ML_ID (yytext, yypos, yypos + size yytext));

<INITIAL,P>{eol}{sharp}{ws}*"if" => (YYBEGIN P;
				     onNewLine yypos;
				     Tokens.IF (yypos, yypos + size yytext));
<INITIAL,P>{eol}{sharp}{ws}*"elif" => (YYBEGIN P;
				     onNewLine yypos;
				     Tokens.ELIF (yypos, yypos + size yytext));
<INITIAL,P>{eol}{sharp}{ws}*"else" => (YYBEGIN P;
				     onNewLine yypos;
				     Tokens.ELSE (yypos, yypos + size yytext));
<INITIAL,P>{eol}{sharp}{ws}*"endif" => (YYBEGIN P;
				      onNewLine yypos;
				      Tokens.ENDIF (yypos,
						    yypos + size yytext));
<INITIAL,P>{eol}{sharp}{ws}*"error"{ws}+{neol}* => (onNewLine yypos;
						    errorTok (yytext, yypos));
<INITIAL,M,PM>{eol}     => (onNewLine yypos; continue ());
<P>{eol}                => (YYBEGIN INITIAL; onNewLine yypos; continue ());

<INITIAL,M,PM,P>{ws}+   => (continue ());

<M,PM>.                 => (error 
			    ("illegal character at start of ML symbol: " ^
			     yytext, yypos, yypos+1);
			    continue ());

<INITIAL>{cmid}		=> (idToken (yytext, yypos, cm_ids,
				     Tokens.FILE_STANDARD,
				     fn () => YYBEGIN M));


<INITIAL>.		=> (error 
			    ("illegal character: " ^ yytext, yypos, yypos+1);
			    continue ());

{eol}{sharp}{ws}*"line"{ws}+{neol}* => (onNewLine yypos;
					continue ());
