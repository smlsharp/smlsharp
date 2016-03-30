(*
 * lexical structures of the SML# interface language.
 *   the part of constant specifications is based on
 *   that of the SML New Jersey implementation
 * @copyright (c) 2015, Tohoku University.
 * @author Atsushi Ohori
 *)

structure T = InterfaceLrVals.Tokens

type token = T.token
type pos = Loc.pos
type lexresult = T.token

(* if you use ml-lex of SML/NJ, you need to specify this to 2. *)
val INITIAL_POS_OF_LEXER = 0

type arg =
    {
      filename : string,
      line : {count : int, begin : int} ref,
      error : string * pos * pos -> unit,
      comment : pos list ref,
      string : {buf : string list ref, startPos : pos option ref},
      allow8bitId : bool
    }

fun initArg {sourceName, lexErrorFn, initialLineno, allow8bitId} =
    {
      filename = sourceName,
      line = ref {count = initialLineno, begin = INITIAL_POS_OF_LEXER},
      error = lexErrorFn,
      comment = ref nil,
      string = {buf = ref nil, startPos = ref NONE},
      allow8bitId = allow8bitId
    } : arg

fun newline (pos, yytext, {line as ref {count, begin}, ...} : arg) =
    line := {count = count + 1, begin = pos + size yytext}

fun pos (yypos, {filename, line = ref {count, begin}, ...}:arg) =
    Loc.makePos {fileName = filename, line = count, col = yypos - begin}

val left = pos

fun right (yypos, len, arg) = pos (yypos + len - 1, arg)

fun string (yytext, yypos, arg) =
    (yytext, pos (yypos, arg), pos (yypos + size yytext - 1, arg))

fun startComment (yypos, arg as {comment,...}) =
    comment := pos (yypos, arg) :: !comment

fun closeComment ({comment,...}:arg) =
    case !comment of
      nil => raise Bug.Bug "closeComment"
    | h::t => (comment := t; case t of nil => true | _::_ => false)

fun startString (yypos, arg as {string={buf,startPos},...}) =
    (buf := nil; startPos := SOME (pos (yypos, arg)))

fun closeString (yypos, arg as {string={buf,startPos},...}:arg) =
    case !startPos of
      NONE => raise Bug.Bug "closeString"
    | SOME p => (String.concat (rev (!buf)), p, pos (yypos, arg))
                before (buf := nil; startPos := NONE)

fun addString (s, {string={buf,startPos},...}:arg) =
    buf := s :: !buf

fun eof ({string, comment, error, ...} : arg) =
    (case !(#startPos string) of
       SOME pos => error ("unclosed string", pos, Loc.nopos)
     | NONE => ();
     case !comment of
       pos::_ => error ("unclosed comment", pos, Loc.nopos)
     | nil => ();
     T.EOF (Loc.nopos, Loc.nopos))

fun check8bitId (arg:arg) (yytext, yypos) =
    if #allow8bitId arg orelse CharVector.all (fn x => ord x < 128) yytext
    then ()
    else #error arg ("8 bit characters in ID is not permitted",
                     left (yypos, arg),
                     right (yypos, size yytext, arg))
(*
以下の
alpha=[A-Za-z\127-\255]
は，
alpha=[A-Za-z\128-\255]
ではないのか？
*)

%%

%full
%s COMM STR SKIP;
%header (structure InterfaceLex);
%arg (arg);

quote="'";
underscore="\_";
alpha=[A-Za-z\127-\255];
digit=[0-9];
xdigit=[0-9a-fA-F];
alnum=({alpha}|{digit}|{underscore});
tyvar=("'"({alnum}({alnum}|{quote})*)?);
eqtyvar=("''"({alnum}|{quote})*);
id=({alpha}({alnum}|{quote})*);
ws=("\012"|[\t\ ]);
eol=("\013\010"|"\010"|"\013");
symid=([-!%&$#+/:<=>?@\\~`^|*]+);
int0=(0{digit}*);
int=([1-9]{digit}*);

%%

<INITIAL>{ws} => (continue ());
<INITIAL>{eol} => (newline (yypos, yytext, arg); continue ());
<INITIAL>"and" => (T.AND (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"_builtin" => (T.BUILTIN (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"case" => (T.CASE (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"datatype" => (T.DATATYPE (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"end" => (T.END (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"eqtype" => (T.EQTYPE (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"exception" => (T.EXCEPTION (left(yypos,arg),right(yypos,9,arg)));
<INITIAL>"functor" => (T.FUNCTOR (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"in" => (T.IN (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"include" => (T.INCLUDE (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"infix" => (T.INFIX (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"infixr" => (T.INFIXR (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"_interface" => (T.INTERFACE (left(yypos,arg),right(yypos,10,arg)));
<INITIAL>"local" => (T.LOCAL (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"of" => (T.OF (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"op" => (T.OP (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"_require" => (T.REQUIRE (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"sharing" => (T.SHARING (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"sig"=> (T.SIG (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"signature" => (T.SIGNATURE (left(yypos,arg),right(yypos,9,arg)));
<INITIAL>"struct" => (T.STRUCT (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"structure" => (T.STRUCTURE (left(yypos,arg),right(yypos,9,arg)));
<INITIAL>"type" => (T.TYPE (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"val" => (T.VAL (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"where" => (T.WHERE (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>":>" => (T.OPAQUE (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"*" => (T.ASTERISK (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"#" => (T.HASH (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"(" => (T.LPAREN (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>")" => (T.RPAREN (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"," => (T.COMMA (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"->" => (T.ARROW (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"." => (T.PERIOD (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>":" => (T.COLON (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>";" => (T.SEMICOLON (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"=" => (T.EQ (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"=>" => (T.DARROW (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"[" => (T.LBRACKET (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"]" => (T.RBRACKET (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"{" => (T.LBRACE (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"|" => (T.BAR (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"}" => (T.RBRACE (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>{eqtyvar} => (let val s = size yytext
                       in T.EQTYVAR (substring (yytext,2,s-2),
                                     left (yypos,arg), right (yypos,s,arg))
                       end);
<INITIAL>{tyvar} => (let val s = size yytext
                     in T.TYVAR (substring (yytext,1,s-1),
                                 left (yypos,arg), right (yypos,s,arg))
                     end);
<INITIAL>{id} => (T.ALPHABETICID (string (yytext, yypos, arg)));
<INITIAL>{symid} => (T.SYMBOLICID (string (yytext, yypos, arg)));
<INITIAL>{int0} => (T.INT ({radix=StringCvt.DEC, digits=yytext},
                           left (yypos,arg), right (yypos,size yytext,arg)));
<INITIAL>{int} => (T.INTLAB (string (yytext, yypos, arg)));
<INITIAL>\" => (startString (yypos, arg); YYBEGIN STR; continue ());
<INITIAL>"(*" => (startComment (yypos, arg); YYBEGIN COMM; continue ()
  (* Unlike "(*", unmatched "*)" should not cause parse error. It should
   * be regarded as two tokens "*" and ")". *)
);
<INITIAL>. => (#error arg
                 ("illegal character", left(yypos,arg), right(yypos,1,arg));
               continue ());

<COMM>{eol} => (newline (yypos, yytext, arg); continue ());
<COMM>"(*"  => (startComment (yypos, arg); continue ());
<COMM>"*)"  => (if closeComment arg then YYBEGIN INITIAL else (); continue ());
<COMM>.     => (continue ());

<STR>{eol} => (let val s as (_,l,r) = closeString (yypos, arg)
               in #error arg ("unclosed string", l, r);
                  newline (yypos, yytext, arg);
                  YYBEGIN INITIAL;
                  T.STRING s
               end);
<STR>\" => (YYBEGIN INITIAL; T.STRING (closeString (yypos, arg)));
<STR>\\{eol} => (newline (yypos, yytext, arg); YYBEGIN SKIP; continue ());
<STR>\\{ws} => (YYBEGIN SKIP; continue ());
<STR>\\a => (addString ("\007", arg); continue());
<STR>\\b => (addString ("\008", arg); continue());
<STR>\\f => (addString ("\012", arg); continue());
<STR>\\n => (addString ("\010", arg); continue());
<STR>\\r => (addString ("\013", arg); continue());
<STR>\\t => (addString ("\009", arg); continue());
<STR>\\v => (addString ("\011", arg); continue());
<STR>\\\\ => (addString ("\\", arg); continue());
<STR>\\\" => (addString ("\"", arg); continue());
<STR>\\\^[@-_] => (addString (str (chr (ord (String.sub (yytext, 2)) - 64)),
                              arg);
                   continue ());
<STR>\\\^. => (#error arg
                 ("illegal control escape; must be one of \
                  \@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_",
                  left(yypos, arg),
                  right(yypos, size yytext, arg));
               continue ());
<STR>\\[0-9]{3} =>
        (let
           val c = StringCvt.scanString
                     (Int.scan StringCvt.DEC)
                     (String.substring (yytext, 1, 3))
         in
           addString (str (chr (valOf c)), arg)
           handle _ => #error arg ("illegal ascii escape",
                                   left (yypos, arg),
                                   right (yypos, size yytext, arg));
           continue ()
         end);
<STR>\\u{xdigit}{4} =>
        (let
           val c = StringCvt.scanString
                     (Int.scan StringCvt.HEX)
                     (String.substring (yytext, 1, 4))
         in
           addString (str (chr (valOf c)), arg)
           handle _ => #error arg ("illegal ascii escape",
                                   left (yypos, arg),
                                   right (yypos, size yytext, arg));
           continue ()
         end);
<STR>\\ => (#error arg ("illegal string escape",
                        left(yypos, arg), right(yypos, 1, arg));
            continue ());
<STR>[^\000-\031\\\"\r\n]+ => (addString (yytext, arg); continue ());
<STR>. => (#error arg
             ("illegal non-printing character in string",
              left(yypos, arg), right(yypos, 1, arg));
           continue());

<SKIP>{eol} => (newline (yypos, yytext, arg); continue());
<SKIP>{ws} => (continue());
<SKIP>\\ => (YYBEGIN STR; continue ());
<SKIP>. => (#error arg
              ("unclosed string", left(yypos, arg), right(yypos, 1, arg));
            YYBEGIN STR;
            continue ());

. => (T.SPECIAL(yytext, left(yypos, arg), right(yypos, 1, arg)));
