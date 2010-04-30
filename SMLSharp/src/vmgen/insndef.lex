(* -*- sml -*- *)

structure T = Tokens

type svalue = T.svalue
type pos = int
type ('a,'b) token = ('a,'b) T.token
type lexresult = (svalue, pos) token

type arg =
    {
      source: InsnDef.source,
      error: string * pos * pos -> unit,
      startPos: int ref,
      commentLevel: int ref,
      stringToken: string ref
    }

fun newline ({source = {lineStartPos, ...}, ...}:arg, pos) =
    lineStartPos := pos :: (!lineStartPos)

fun toInt s =
    valOf (StringCvt.scanString (Int.scan StringCvt.DEC) s)

fun inc r = r := !r + 1
fun dec r = r := !r - 1

fun eof ({error, startPos, commentLevel, ...}:arg) =
    (
      if !startPos >= 0
      then if !commentLevel > 0
           then error ("unclosed comment", !startPos, ~1)
           else error ("unclosed string", !startPos, ~1)
      else ();
      Tokens.EOF (~1, ~1)
    )

(*
<INITIAL>"then" => (Tokens.THEN (yypos, yypos + size yytext));
*) 

%%

%header (functor InsnLexFun(structure Tokens : Insn_TOKENS));
%arg (arg as {startPos, stringToken, commentLevel, ...});
%s COMM STR;

nl=("\r\n"|"\n"|"\r");
ws=[\012\t\ ];

%%

<INITIAL>"/*" => (YYBEGIN COMM; startPos := yypos; 
                  inc commentLevel; continue ());
<COMM>"/*" => (inc commentLevel; continue ());
<COMM>"*/" => (dec commentLevel;
               if !commentLevel = 0
               then (YYBEGIN INITIAL; startPos := ~1) else ();
               continue ());
<COMM>{nl} => (newline (arg, yypos + size yytext); continue ());
<COMM>. => (continue ());

<INITIAL>\" => (YYBEGIN STR;
                startPos := yypos; stringToken := ""; continue ());
<STR>\" => (YYBEGIN INITIAL;
            T.STRING (!stringToken, !startPos, yypos + size yytext)
            before startPos := ~1);
<STR>{nl} => (newline (arg, yypos + size yytext);
              stringToken := (!stringToken) ^ "\n";
              continue ());
<STR>. => (stringToken := (!stringToken) ^ yytext; continue ());

<INITIAL>{ws}+ => (continue ());
<INITIAL>{nl} => (newline (arg, yypos + size yytext); continue ());

<INITIAL>"b" => (Tokens.B (yypos, yypos + size yytext));
<INITIAL>"h" => (Tokens.H (yypos, yypos + size yytext));
<INITIAL>"w" => (Tokens.W (yypos, yypos + size yytext));
<INITIAL>"l" => (Tokens.L (yypos, yypos + size yytext));
<INITIAL>"n" => (Tokens.N (yypos, yypos + size yytext));
<INITIAL>"nl" => (Tokens.NL (yypos, yypos + size yytext));
<INITIAL>"fs" => (Tokens.FS (yypos, yypos + size yytext));
<INITIAL>"f" => (Tokens.F (yypos, yypos + size yytext));
<INITIAL>"fl" => (Tokens.FL (yypos, yypos + size yytext));
<INITIAL>"p" => (Tokens.P (yypos, yypos + size yytext));
<INITIAL>"sz" => (Tokens.SZ (yypos, yypos + size yytext));
<INITIAL>"sh" => (Tokens.SH (yypos, yypos + size yytext));
<INITIAL>"lsz" => (Tokens.LSZ (yypos, yypos + size yytext));

<INITIAL>"varA" => (Tokens.VARA (yypos, yypos + size yytext));
<INITIAL>"varB" => (Tokens.VARB (yypos, yypos + size yytext));
<INITIAL>"varC" => (Tokens.VARC (yypos, yypos + size yytext));
<INITIAL>"varD" => (Tokens.VARD (yypos, yypos + size yytext));
<INITIAL>"size" => (Tokens.SIZE (yypos, yypos + size yytext));
<INITIAL>"scale" => (Tokens.SCALE (yypos, yypos + size yytext));
<INITIAL>"shift" => (Tokens.SHIFT (yypos, yypos + size yytext));
<INITIAL>"ty" => (Tokens.TY (yypos, yypos + size yytext));
<INITIAL>"displacement" => (Tokens.DISPLACEMENT (yypos, yypos + size yytext));
<INITIAL>"imm" => (Tokens.IMM (yypos, yypos + size yytext));
<INITIAL>"label" => (Tokens.LABEL (yypos, yypos + size yytext));
<INITIAL>"externA" => (Tokens.EXTERNA (yypos, yypos + size yytext));
<INITIAL>"externB" => (Tokens.EXTERNB (yypos, yypos + size yytext));
<INITIAL>"lsizeA" => (Tokens.LSIZEA (yypos, yypos + size yytext));
<INITIAL>"lsizeB" => (Tokens.LSIZEB (yypos, yypos + size yytext));
<INITIAL>"IP" => (Tokens.IP (yypos, yypos + size yytext));
<INITIAL>"SP" => (Tokens.SP (yypos, yypos + size yytext));
<INITIAL>"HR" => (Tokens.HR (yypos, yypos + size yytext));

<INITIAL>"suffix" => (Tokens.SUFFIX (yypos, yypos + size yytext));
<INITIAL>"syntax" => (Tokens.SYNTAX (yypos, yypos + size yytext));
<INITIAL>"preprocess" => (Tokens.PREPROCESS (yypos, yypos + size yytext));
<INITIAL>"semantics" => (Tokens.SEMANTICS (yypos, yypos + size yytext));
<INITIAL>"alternate" => (Tokens.ALTERNATE (yypos, yypos + size yytext));
<INITIAL>"tmpvar" => (Tokens.TMPVAR (yypos, yypos + size yytext));
<INITIAL>":" => (Tokens.COLON (yypos, yypos + size yytext));
<INITIAL>"#if" => (Tokens.METAIF (yypos, yypos + size yytext));
<INITIAL>"#elif" => (Tokens.METAELIF (yypos, yypos + size yytext));
<INITIAL>"#else" => (Tokens.METAELSE (yypos, yypos + size yytext));
<INITIAL>"#variations" => (Tokens.METAVARIATIONS (yypos, yypos + size yytext));
<INITIAL>"if" => (Tokens.IF (yypos, yypos + size yytext));
<INITIAL>"else" => (Tokens.ELSE (yypos, yypos + size yytext));

<INITIAL>"(" => (Tokens.LPAREN (yypos, yypos + size yytext));
<INITIAL>")" => (Tokens.RPAREN (yypos, yypos + size yytext));
<INITIAL>"{" => (Tokens.LBRACE (yypos, yypos + size yytext));
<INITIAL>"}" => (Tokens.RBRACE (yypos, yypos + size yytext));
<INITIAL>"[" => (Tokens.LBRACKET (yypos, yypos + size yytext));
<INITIAL>"]" => (Tokens.RBRACKET (yypos, yypos + size yytext));
<INITIAL>"," => (Tokens.COMMA (yypos, yypos + size yytext));
<INITIAL>";" => (Tokens.SEMICOLON (yypos, yypos + size yytext));
<INITIAL>":" => (Tokens.COLON (yypos, yypos + size yytext));
<INITIAL>"=" => (Tokens.EQ (yypos, yypos + size yytext));

<INITIAL>"+" => (Tokens.PLUS (yypos, yypos + size yytext));
<INITIAL>"-" => (Tokens.MINUS (yypos, yypos + size yytext));
<INITIAL>"*" => (Tokens.STAR (yypos, yypos + size yytext));
<INITIAL>"`div`" => (Tokens.DIV (yypos, yypos + size yytext));
<INITIAL>"`divo`" => (Tokens.DIVO (yypos, yypos + size yytext));
<INITIAL>"`mod`" => (Tokens.MOD (yypos, yypos + size yytext));
<INITIAL>"`dvmd`" => (Tokens.DVMD (yypos, yypos + size yytext));
<INITIAL>"`quot`" => (Tokens.QUOT (yypos, yypos + size yytext));
<INITIAL>"`quoto`" => (Tokens.QUOTO (yypos, yypos + size yytext));
<INITIAL>"`rem`" => (Tokens.REM (yypos, yypos + size yytext));
<INITIAL>"`qtrm`" => (Tokens.QTRM (yypos, yypos + size yytext));
<INITIAL>"`addo`" => (Tokens.ADDO (yypos, yypos + size yytext));
<INITIAL>"`subo`" => (Tokens.SUBO (yypos, yypos + size yytext));
<INITIAL>"`mulo`" => (Tokens.MULO (yypos, yypos + size yytext));
<INITIAL>"`divo`" => (Tokens.DIVO (yypos, yypos + size yytext));
<INITIAL>"`dvmdo`" => (Tokens.DVMDO (yypos, yypos + size yytext));
<INITIAL>"`qtrmo`" => (Tokens.QTRMO (yypos, yypos + size yytext));
<INITIAL>"<<" => (Tokens.LSHIFT (yypos, yypos + size yytext));
<INITIAL>">>" => (Tokens.RSHIFT (yypos, yypos + size yytext));
<INITIAL>">>>" => (Tokens.RASHIFT (yypos, yypos + size yytext));
<INITIAL>"&&" => (Tokens.ANDAND (yypos, yypos + size yytext));
<INITIAL>"||" => (Tokens.OROR (yypos, yypos + size yytext));
<INITIAL>"&" => (Tokens.ANDB (yypos, yypos + size yytext));
<INITIAL>"|" => (Tokens.ORB (yypos, yypos + size yytext));
<INITIAL>"~" => (Tokens.NOTB (yypos, yypos + size yytext));
<INITIAL>"^" => (Tokens.XORB (yypos, yypos + size yytext));
<INITIAL>"==" => (Tokens.EQEQ (yypos, yypos + size yytext));
<INITIAL>">=" => (Tokens.GE (yypos, yypos + size yytext));
<INITIAL>"<=" => (Tokens.LE (yypos, yypos + size yytext));
<INITIAL>">" => (Tokens.GT (yypos, yypos + size yytext));
<INITIAL>"<" => (Tokens.LT (yypos, yypos + size yytext));
<INITIAL>"ABS" => (Tokens.ABS (yypos, yypos + size yytext));
<INITIAL>"ABSO" => (Tokens.ABSO (yypos, yypos + size yytext));
<INITIAL>"ALLOC" => (Tokens.ALLOC (yypos, yypos + size yytext));
<INITIAL>"sizeof" => (Tokens.SIZEOF (yypos, yypos + size yytext));
<INITIAL>"FFEXPORT" => (Tokens.FFEXPORT (yypos, yypos + size yytext));
<INITIAL>"NULL" => (Tokens.NULL (yypos, yypos + size yytext));

<INITIAL>"COPY" => (Tokens.COPY (yypos, yypos + size yytext));
<INITIAL>"VAR" => (Tokens.VAR (yypos, yypos + size yytext));
<INITIAL>"REG" => (Tokens.REG (yypos, yypos + size yytext));
<INITIAL>"LOCAL" => (Tokens.LOCAL (yypos, yypos + size yytext));
<INITIAL>"LABEL" => (Tokens.LABELREF (yypos, yypos + size yytext));
<INITIAL>"BARRIER" => (Tokens.BARRIER (yypos, yypos + size yytext));
<INITIAL>"UNWIND" => (Tokens.UNWIND (yypos, yypos + size yytext));
<INITIAL>"ENTER" => (Tokens.ENTER (yypos, yypos + size yytext));
<INITIAL>"LEAVE" => (Tokens.LEAVE (yypos, yypos + size yytext));
<INITIAL>"FFCALL" => (Tokens.FFCALL (yypos, yypos + size yytext));
<INITIAL>"FUNCALL" => (Tokens.FUNCALL (yypos, yypos + size yytext));
<INITIAL>"SYSCALL" => (Tokens.SYSCALL (yypos, yypos + size yytext));
<INITIAL>"PUSHTRAP" => (Tokens.PUSHTRAP (yypos, yypos + size yytext));
<INITIAL>"POPTRAP" => (Tokens.POPTRAP (yypos, yypos + size yytext));
<INITIAL>"RAISE" => (Tokens.RAISE (yypos, yypos + size yytext));
<INITIAL>"NEXT" => (Tokens.NEXT (yypos, yypos + size yytext));
<INITIAL>"CONTINUE" => (Tokens.CONTINUE (yypos, yypos + size yytext));

<INITIAL>"0"|[1-9][0-9]* => (Tokens.NUM (toInt yytext,
                                         yypos, yypos + size yytext));
<INITIAL>[A-Za-z][A-Za-z_0-9]* => (Tokens.SYM (yytext,
                                               yypos, yypos + size yytext));

<INITIAL>. => (Tokens.INVAL (yytext, yypos, yypos + size yytext));
