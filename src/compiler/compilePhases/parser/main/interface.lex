(*
 * lexical structures of the SML# interface language.
 *   the part of constant specifications is based on
 *   that of the SML New Jersey implementation
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)

structure T = Interface.Tokens

type token = T.token
type pos = Loc.pos
type lexresult = T.token

(* if you use ml-lex of SML/NJ, you need to specify this to 2. *)
val INITIAL_POS_OF_LEXER = 0

type arg =
    {
      source : Loc.source,
      line : {count : int, begin : int} ref,
      error : string * pos * pos -> unit,
      comment : pos list ref,
      string : {buf : string list ref, startPos : pos option ref},
      prevPos : int ref,
      allow8bitId : bool
    }

fun initArg {source, lexErrorFn, initialLineno, allow8bitId} =
    {
      source = source,
      line = ref {count = initialLineno, begin = INITIAL_POS_OF_LEXER},
      error = lexErrorFn,
      comment = ref nil,
      string = {buf = ref nil, startPos = ref NONE},
      prevPos = ref INITIAL_POS_OF_LEXER,
      allow8bitId = allow8bitId
    } : arg

fun newline (pos, yytext, {line as ref {count, begin}, ...} : arg) =
    line := {count = count + 1, begin = pos + size yytext}

fun pos (yypos, {source, line = ref {count, begin}, prevPos, ...}:arg) =
    Loc.POS {source = source, line = count, col = yypos - begin,
             pos = yypos - INITIAL_POS_OF_LEXER, gap = yypos - !prevPos}

val left = pos

fun right (yypos, len, arg) = pos (yypos + len - 1, arg)

fun keyword (yytext, yypos, arg as {prevPos, ...}) =
    (left (yypos, arg), right (yypos, size yytext, arg))
    before prevPos := yypos + size yytext

fun string (yytext, yypos, arg) =
    case keyword (yytext, yypos, arg) of (l, r) => (yytext, l, r)

fun startComment (yypos, arg as {comment,...}) =
    comment := pos (yypos, arg) :: !comment

fun closeComment ({comment,...}:arg) =
    case !comment of
      nil => raise Bug.Bug "closeComment"
    | h::t => (comment := t; case t of nil => true | _::_ => false)

fun startString (yypos, arg as {string = {buf, startPos}, ...}) =
    (buf := nil; startPos := SOME (pos (yypos, arg)))

fun closeString (yypos, arg as {string = {buf, startPos}, ...} : arg) =
    case !startPos of
      NONE => raise Bug.Bug "closeString"
    | SOME l =>
      let
        val r = pos (yypos, arg)
        val s = String.concat (rev (!buf))
      in
        buf := nil;
        startPos := NONE;
        #prevPos arg := yypos + 1;
        (T.STRING (s, l, r), l, r)
      end

fun addString (s, {string = {buf, startPos}, ...}:arg) =
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
prefixedlabel={int}"_"({id}|{symid});

%%

<INITIAL>{ws} => (continue ());
<INITIAL>{eol} => (newline (yypos, yytext, arg); continue ());
<INITIAL>"and" => (T.AND (keyword (yytext, yypos, arg)));
<INITIAL>"_builtin" => (T.BUILTIN (keyword (yytext, yypos, arg)));
<INITIAL>"case" => (T.CASE (keyword (yytext, yypos, arg)));
<INITIAL>"datatype" => (T.DATATYPE (keyword (yytext, yypos, arg)));
<INITIAL>"end" => (T.END (keyword (yytext, yypos, arg)));
<INITIAL>"eqtype" => (T.EQTYPE (keyword (yytext, yypos, arg)));
<INITIAL>"exception" => (T.EXCEPTION (keyword (yytext, yypos, arg)));
<INITIAL>"functor" => (T.FUNCTOR (keyword (yytext, yypos, arg)));
<INITIAL>"in" => (T.IN (keyword (yytext, yypos, arg)));
<INITIAL>"include" => (T.INCLUDE (keyword (yytext, yypos, arg)));
<INITIAL>"infix" => (T.INFIX (keyword (yytext, yypos, arg)));
<INITIAL>"infixr" => (T.INFIXR (keyword (yytext, yypos, arg)));
<INITIAL>"local" => (T.LOCAL (keyword (yytext, yypos, arg)));
<INITIAL>"of" => (T.OF (keyword (yytext, yypos, arg)));
<INITIAL>"op" => (T.OP (keyword (yytext, yypos, arg)));
<INITIAL>"_require" => (T.REQUIRE (keyword (yytext, yypos, arg)));
<INITIAL>"sharing" => (T.SHARING (keyword (yytext, yypos, arg)));
<INITIAL>"sig"=> (T.SIG (keyword (yytext, yypos, arg)));
<INITIAL>"signature" => (T.SIGNATURE (keyword (yytext, yypos, arg)));
<INITIAL>"struct" => (T.STRUCT (keyword (yytext, yypos, arg)));
<INITIAL>"structure" => (T.STRUCTURE (keyword (yytext, yypos, arg)));
<INITIAL>"type" => (T.TYPE (keyword (yytext, yypos, arg)));
<INITIAL>"_use" => (T.USE' (keyword (yytext, yypos, arg)));
<INITIAL>"val" => (T.VAL (keyword (yytext, yypos, arg)));
<INITIAL>"where" => (T.WHERE (keyword (yytext, yypos, arg)));
<INITIAL>"withtype" => (T.WITHTYPE (keyword (yytext, yypos, arg)));
<INITIAL>":>" => (T.OPAQUE (keyword (yytext, yypos, arg)));
<INITIAL>"*" => (T.ASTERISK (keyword (yytext, yypos, arg)));
<INITIAL>"#" => (T.HASH (keyword (yytext, yypos, arg)));
<INITIAL>"(" => (T.LPAREN (keyword (yytext, yypos, arg)));
<INITIAL>")" => (T.RPAREN (keyword (yytext, yypos, arg)));
<INITIAL>"," => (T.COMMA (keyword (yytext, yypos, arg)));
<INITIAL>"->" => (T.ARROW (keyword (yytext, yypos, arg)));
<INITIAL>"." => (T.PERIOD (keyword (yytext, yypos, arg)));
<INITIAL>":" => (T.COLON (keyword (yytext, yypos, arg)));
<INITIAL>";" => (T.SEMICOLON (keyword (yytext, yypos, arg)));
<INITIAL>"=" => (T.EQ (keyword (yytext, yypos, arg)));
<INITIAL>"=>" => (T.DARROW (keyword (yytext, yypos, arg)));
<INITIAL>"[" => (T.LBRACKET (keyword (yytext, yypos, arg)));
<INITIAL>"]" => (T.RBRACKET (keyword (yytext, yypos, arg)));
<INITIAL>"{" => (T.LBRACE (keyword (yytext, yypos, arg)));
<INITIAL>"|" => (T.BAR (keyword (yytext, yypos, arg)));
<INITIAL>"}" => (T.RBRACE (keyword (yytext, yypos, arg)));
<INITIAL>{eqtyvar} => (T.EQTYVAR (string (yytext, yypos, arg)));
<INITIAL>{tyvar} => (T.TYVAR (string (yytext, yypos, arg)));
<INITIAL>{id} => (T.ALPHABETICID (string (yytext, yypos, arg)));
<INITIAL>{symid} => (T.SYMBOLICID (string (yytext, yypos, arg)));
<INITIAL>{prefixedlabel} => (T.PREFIXEDLABEL (string (yytext, yypos, arg)));
<INITIAL>{int0} =>
         (let val (s, l, r) = string (yytext, yypos, arg)
          in T.INT ({radix = StringCvt.DEC, digits = s}, l, r)
          end);
<INITIAL>{int} => (T.INTLAB (string (yytext, yypos, arg)));
<INITIAL>\" => (startString (yypos, arg); YYBEGIN STR; continue ());
<INITIAL>"(*" => (startComment (yypos, arg); YYBEGIN COMM; continue ()
  (* Unlike "(*", unmatched "*)" should not cause parse error. It should
   * be regarded as two tokens "*" and ")". *)
);
<INITIAL>. => (T.SPECIAL (string (yytext, yypos, arg)));

<COMM>{eol} => (newline (yypos, yytext, arg); continue ());
<COMM>"(*"  => (startComment (yypos, arg); continue ());
<COMM>"*)"  => (if closeComment arg then YYBEGIN INITIAL else (); continue ());
<COMM>.     => (continue ());

<STR>{eol} => (let val (t, l, r) = closeString (yypos, arg)
               in #error arg ("unclosed string", l, r);
                  newline (yypos, yytext, arg);
                  YYBEGIN INITIAL;
                  t
               end);
<STR>\" => (YYBEGIN INITIAL; #1 (closeString (yypos, arg)));
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
           val x = valOf (StringCvt.scanString
                            (Word.scan StringCvt.HEX)
                            (String.substring (yytext, 1, 4)))
           fun byte (w, shift, mask, set) =
               Word.orb (Word.andb (Word.>> (x, shift), mask), set)
           fun str x =
               String.str (Char.chr (Word.toInt x))
         in
           (* UTF-8 encoding *)
           if x <= 0wx7f then
             (addString (str (byte (x,  0w0, 0wx7f, 0wx00)), arg))
           else if x <= 0wx7ff then
             (addString (str (byte (x,  0w6, 0wx1f, 0wxc0)), arg);
              addString (str (byte (x,  0w0, 0wx3f, 0wx80)), arg))
           else
             (addString (str (byte (x, 0w12, 0wx0f, 0wxe0)), arg);
              addString (str (byte (x,  0w6, 0wx3f, 0wx80)), arg);
              addString (str (byte (x,  0w0, 0wx3f, 0wx80)), arg));
           continue()
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
