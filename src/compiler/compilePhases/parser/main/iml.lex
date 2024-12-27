(*
 * lexical structures of IML.
 *   the part of constant specifications is based on 
 *   that of the SML New Jersye implementation
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 * @author Katsuhiro Ueno
 * @version $Id: iml.lex,v 1.42.6.6 2010/01/22 09:19:06 hiro-en Exp $
 *)

structure T = ML.Tokens

type token = T.token
type pos = Loc.pos
type lexresult = T.token

(* if you use ml-lex of SML/NJ, you need to specify this to 2. *)
val INITIAL_POS_OF_LEXER = 0

datatype string_type = STRING | CHAR
type arg =
    {
      source : Loc.source,
      line : {count : int, begin : int} ref,
      error : string * pos * pos -> unit,
      comment : pos list ref,
      string : {buf : string list ref,
                startPos : pos option ref,
                ty : string_type ref},
      prevPos : int ref,
      allow8bitId : bool,
      enableMeta : bool
    }

fun initArg {source, enableMeta, lexErrorFn, initialLineno, allow8bitId} =
    {
      source = source,
      line = ref {count = initialLineno, begin = INITIAL_POS_OF_LEXER},
      error = lexErrorFn,
      comment = ref nil,
      string = {buf = ref nil, startPos = ref NONE, ty = ref STRING},
      prevPos = ref INITIAL_POS_OF_LEXER,
      allow8bitId = allow8bitId,
      enableMeta = enableMeta
    } : arg

fun isINITIAL (arg : arg) =
    case arg of
      {comment = ref nil, string = {startPos = ref NONE, ...}, ...} => true
    | _ => false

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

fun startString (yypos, strTy, arg as {string = {buf, startPos, ty}, ...}) =
    (buf := nil; startPos := SOME (pos (yypos, arg)); ty := strTy)

(*
fun closeString (yypos, arg as {string = {buf, startPos, ty}, ...} : arg) =
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
        case !ty of
          STRING => (T.STRING (s, l, r), l, r)
        | CHAR => (if size s = 1 then ()
                   else #error arg ("character constant not length 1", l, r);
                   (T.CHAR (s, l, r), l, r))
      end
*)
fun closeString (yypos, arg as {string = {buf, startPos, ty}, ...} : arg) =
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
        case !ty of
          STRING => (T.STRING (s, l, r), l, r)
                | CHAR => (if size s = 1 then (T.CHAR (s, l, r), l, r)
                           else (T.SELECTOR (s, l, r), l, r))
      end

fun addString (s, {string = {buf, startPos, ...}, ...}:arg) =
    buf := s :: !buf

fun eof ({string, comment, error, ...} : arg) =
    (case !(#startPos string) of
       SOME pos => error ("unclosed string", pos, Loc.nopos)
     | NONE => ();
     case !comment of
       pos::_ => error ("unclosed comment", pos, Loc.nopos)
     | nil => ();
     T.EOF (Loc.nopos, Loc.nopos))

fun check8bit (yytext, yypos, arg) =
    (if #allow8bitId arg orelse CharVector.all (fn x => ord x < 128) yytext
     then ()
     else #error arg ("8 bit characters in ID is not permitted",
                      left (yypos, arg),
                      right (yypos, size yytext, arg));
     (yytext, yypos, arg))

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
%structure MLLex
%arg (arg);

underscore="\_";
alpha=[A-Za-z\127-\255];
digit=[0-9];
xdigit=[0-9a-fA-F];
alnum=({alpha}|{digit}|{underscore});
tyvar=("'"({alnum}({alnum}|"'")*)?);
eqtyvar=("''"({alnum}|"'")*);
id=({alpha}({alnum}|"'")*);
ws=("\012"|[\t\ ]);
eol=("\013\010"|"\010"|"\013");
symid=([-!%&$#+/:<=>?@\\~`^|*]+);
int0=(0{digit}*);
int=([1-9]{digit}*);
prefixedlabel={int}"_"({id}|{symid});

num=[0-9]+;
frac="."{num};
exp=[eE](~?){num};
real=(~?)(({num}{frac}?{exp})|({num}{frac}{exp}?));

%%

<INITIAL>{ws} => (continue ());
<INITIAL>{eol} => (newline (yypos, yytext, arg); continue ());
<INITIAL>"__attribute__" => (T.ATTRIBUTE (keyword (yytext, yypos, arg)));
<INITIAL>"_builtin" => (T.BUILTIN (keyword (yytext, yypos, arg)));
<INITIAL>"_foreach" => (T.FOREACH (keyword (yytext, yypos, arg)));
<INITIAL>"_import" => (T.IMPORT (keyword (yytext, yypos, arg)));
<INITIAL>"_interface" => (T.INTERFACE (keyword (yytext, yypos, arg)));
<INITIAL>"_join" => (T.JOINOP (keyword (yytext, yypos, arg)));
<INITIAL>"_extend" => (T.EXTENDOP (keyword (yytext, yypos, arg)));
<INITIAL>"_update" => (T.UPDATEOP (keyword (yytext, yypos, arg)));
<INITIAL>"_dynamic" => (T.DYNAMIC (keyword (yytext, yypos, arg)));
<INITIAL>"_dynamiccase" => (T.DYNAMICCASE (keyword (yytext, yypos, arg)));
<INITIAL>"_dynamicnull" => (T.DYNAMICNULL (keyword (yytext, yypos, arg)));
<INITIAL>"_dynamicvoid" => (T.DYNAMICTOP (keyword (yytext, yypos, arg)));
<INITIAL>"_polyrec" => (T.POLYREC (keyword (yytext, yypos, arg)));
<INITIAL>"_require" => (T.REQUIRE (keyword (yytext, yypos, arg)));
<INITIAL>"_sizeof" => (T.SIZEOF (keyword (yytext, yypos, arg)));
<INITIAL>"_sql" => (T.SQL (keyword (yytext, yypos, arg)));
<INITIAL>"_sqleval" => (T.SQLEVAL (keyword (yytext, yypos, arg)));
<INITIAL>"_sqlexec" => (T.SQLEXEC (keyword (yytext, yypos, arg)));
<INITIAL>"_sqlserver" => (T.SQLSERVER (keyword (yytext, yypos, arg)));
<INITIAL>"_use" => (T.USE' (keyword (yytext, yypos, arg)));
<INITIAL>"_sizeof" => (T.SIZEOF (keyword (yytext, yypos, arg)));
<INITIAL>"_reifyTy" => (T.REIFYTY (keyword (yytext, yypos, arg)));
<INITIAL>"_"{id}+ => (let val (l, r) = keyword (yytext, yypos, arg)
                      in #error arg ("illegal _ keyword", l, r);
                         continue ()
                      end);
<INITIAL>"abstype" => (T.ABSTYPE (keyword (yytext, yypos, arg)));
<INITIAL>"all" => (T.ALL (keyword (yytext, yypos, arg)));
<INITIAL>"and" => (T.AND (keyword (yytext, yypos, arg)));
<INITIAL>"andalso" => (T.ANDALSO (keyword (yytext, yypos, arg)));
<INITIAL>"as" => (T.AS (keyword (yytext, yypos, arg)));
<INITIAL>"asc" => (T.ASC (keyword (yytext, yypos, arg)));
<INITIAL>"begin" => (T.BEGIN (keyword (yytext, yypos, arg)));
<INITIAL>"by" => (T.BY (keyword (yytext, yypos, arg)));
<INITIAL>"case" => (T.CASE (keyword (yytext, yypos, arg)));
<INITIAL>"commit" => (T.COMMIT (keyword (yytext, yypos, arg)));
<INITIAL>"cross" => (T.CROSS (keyword (yytext, yypos, arg)));
<INITIAL>"datatype" => (T.DATATYPE (keyword (yytext, yypos, arg)));
<INITIAL>"default" => (T.DEFAULT (keyword (yytext, yypos, arg)));
<INITIAL>"delete" => (T.DELETE (keyword (yytext, yypos, arg)));
<INITIAL>"desc" => (T.DESC (keyword (yytext, yypos, arg)));
<INITIAL>"distinct" => (T.DISTINCT (keyword (yytext, yypos, arg)));
<INITIAL>"do" => (T.DO (keyword (yytext, yypos, arg)));
<INITIAL>"else" => (T.ELSE (keyword (yytext, yypos, arg)));
<INITIAL>"end" => (T.END (keyword (yytext, yypos, arg)));
<INITIAL>"eqtype" => (T.EQTYPE (keyword (yytext, yypos, arg)));
<INITIAL>"exception" => (T.EXCEPTION (keyword (yytext, yypos, arg)));
<INITIAL>"exists" => (T.EXISTS (keyword (yytext, yypos, arg)));
<INITIAL>"false" => (T.FALSE (keyword (yytext, yypos, arg)));
<INITIAL>"fetch" => (T.FETCH (keyword (yytext, yypos, arg)));
<INITIAL>"first" => (T.FIRST (keyword (yytext, yypos, arg)));
<INITIAL>"fn" => (T.FN (keyword (yytext, yypos, arg)));
<INITIAL>"from" => (T.FROM (keyword (yytext, yypos, arg)));
<INITIAL>"fun" => (T.FUN (keyword (yytext, yypos, arg)));
<INITIAL>"functor" => (T.FUNCTOR (keyword (yytext, yypos, arg)));
<INITIAL>"group" => (T.GROUP (keyword (yytext, yypos, arg)));
<INITIAL>"handle" => (T.HANDLE (keyword (yytext, yypos, arg)));
<INITIAL>"having" => (T.HAVING (keyword (yytext, yypos, arg)));
<INITIAL>"if" => (T.IF (keyword (yytext, yypos, arg)));
<INITIAL>"in" => (T.IN (keyword (yytext, yypos, arg)));
<INITIAL>"include" => (T.INCLUDE (keyword (yytext, yypos, arg)));
<INITIAL>"infix" => (T.INFIX (keyword (yytext, yypos, arg)));
<INITIAL>"infixr" => (T.INFIXR (keyword (yytext, yypos, arg)));
<INITIAL>"inner" => (T.INNER (keyword (yytext, yypos, arg)));
<INITIAL>"insert" => (T.INSERT (keyword (yytext, yypos, arg)));
<INITIAL>"into" => (T.INTO (keyword (yytext, yypos, arg)));
<INITIAL>"is" => (T.IS (keyword (yytext, yypos, arg)));
<INITIAL>"join" => (T.JOIN (keyword (yytext, yypos, arg)));
<INITIAL>"let" => (T.LET (keyword (yytext, yypos, arg)));
<INITIAL>"limit" => (T.LIMIT (keyword (yytext, yypos, arg)));
<INITIAL>"local" => (T.LOCAL (keyword (yytext, yypos, arg)));
<INITIAL>"natural" => (T.NATURAL (keyword (yytext, yypos, arg)));
<INITIAL>"next" => (T.NEXT (keyword (yytext, yypos, arg)));
<INITIAL>"nonfix" => (T.NONFIX (keyword (yytext, yypos, arg)));
<INITIAL>"not" => (T.NOT (keyword (yytext, yypos, arg)));
<INITIAL>"null" => (T.NULL (keyword (yytext, yypos, arg)));
<INITIAL>"of" => (T.OF (keyword (yytext, yypos, arg)));
<INITIAL>"offset" => (T.OFFSET (keyword (yytext, yypos, arg)));
<INITIAL>"on" => (T.ON (keyword (yytext, yypos, arg)));
<INITIAL>"only" => (T.ONLY (keyword (yytext, yypos, arg)));
<INITIAL>"op" => (T.OP (keyword (yytext, yypos, arg)));
<INITIAL>"open" => (T.OPEN(keyword (yytext, yypos, arg)));
<INITIAL>"or" => (T.OR (keyword (yytext, yypos, arg)));
<INITIAL>"order" => (T.ORDER (keyword (yytext, yypos, arg)));
<INITIAL>"orelse" => (T.ORELSE (keyword (yytext, yypos, arg)));
<INITIAL>"raise" => (T.RAISE (keyword (yytext, yypos, arg)));
<INITIAL>"rec" => (T.REC (keyword (yytext, yypos, arg)));
<INITIAL>"rollback" => (T.ROLLBACK (keyword (yytext, yypos, arg)));
<INITIAL>"row" => (T.ROW (keyword (yytext, yypos, arg)));
<INITIAL>"rows" => (T.ROWS (keyword (yytext, yypos, arg)));
<INITIAL>"select" => (T.SELECT (keyword (yytext, yypos, arg)));
<INITIAL>"set" => (T.SET (keyword (yytext, yypos, arg)));
<INITIAL>"sharing" => (T.SHARING (keyword (yytext, yypos, arg)));
<INITIAL>"sig"=> (T.SIG (keyword (yytext, yypos, arg)));
<INITIAL>"signature" => (T.SIGNATURE (keyword (yytext, yypos, arg)));
<INITIAL>"struct" => (T.STRUCT (keyword (yytext, yypos, arg)));
<INITIAL>"structure" => (T.STRUCTURE (keyword (yytext, yypos, arg)));
<INITIAL>"then" => (T.THEN (keyword (yytext, yypos, arg)));
<INITIAL>"true" => (T.TRUE (keyword (yytext, yypos, arg)));
<INITIAL>"type" => (T.TYPE (keyword (yytext, yypos, arg)));
<INITIAL>"unknown" => (T.UNKNOWN (keyword (yytext, yypos, arg)));
<INITIAL>"update" => (T.UPDATE (keyword (yytext, yypos, arg)));
<INITIAL>"use" => (if #enableMeta arg
                   then T.USE (keyword (yytext, yypos, arg))
                   else T.ALPHABETICID (string (yytext, yypos, arg)));
<INITIAL>"val" => (T.VAL (keyword (yytext, yypos, arg)));
<INITIAL>"values" => (T.VALUES (keyword (yytext, yypos, arg)));
<INITIAL>"where" => (T.WHERE (keyword (yytext, yypos, arg)));
<INITIAL>"while" => (T.WHILE (keyword (yytext, yypos, arg)));
<INITIAL>"with" => (T.WITH (keyword (yytext, yypos, arg)));
<INITIAL>"withtype" => (T.WITHTYPE (keyword (yytext, yypos, arg)));
<INITIAL>":>" => (T.OPAQUE (keyword (yytext, yypos, arg)));
<INITIAL>"*" => (T.ASTERISK(keyword (yytext, yypos, arg)));
<INITIAL>"#" => (T.HASH(keyword (yytext, yypos, arg)));
<INITIAL>"(" => (T.LPAREN(keyword (yytext, yypos, arg)));
<INITIAL>")" => (T.RPAREN(keyword (yytext, yypos, arg)));
<INITIAL>"," => (T.COMMA(keyword (yytext, yypos, arg)));
<INITIAL>"->" => (T.ARROW (keyword (yytext, yypos, arg)));
<INITIAL>"." => (T.PERIOD (keyword (yytext, yypos, arg)));
<INITIAL>"..." => (T.PERIODS (keyword (yytext, yypos, arg)));
<INITIAL>":" => (T.COLON(keyword (yytext, yypos, arg)));
<INITIAL>";" => (T.SEMICOLON(keyword (yytext, yypos, arg)));
<INITIAL>"=" => (T.EQ(keyword (yytext, yypos, arg)));
<INITIAL>"=>" => (T.DARROW (keyword (yytext, yypos, arg)));
<INITIAL>"[" => (T.LBRACKET(keyword (yytext, yypos, arg)));
<INITIAL>"]" => (T.RBRACKET(keyword (yytext, yypos, arg)));
<INITIAL>"_" => (T.UNDERBAR(keyword (yytext, yypos, arg)));
<INITIAL>"{" => (T.LBRACE(keyword (yytext, yypos, arg)));
<INITIAL>"|" => (T.BAR(keyword (yytext, yypos, arg)));
<INITIAL>"}" => (T.RBRACE(keyword (yytext, yypos, arg)));
<INITIAL>"''_"({alnum}|"'")* => (T.FREE_EQTYVAR (string (yytext, yypos, arg)));
<INITIAL>"'_"({alnum}|"'")* => (T.FREE_TYVAR (string (yytext, yypos, arg)));
<INITIAL>{eqtyvar} => (T.EQTYVAR (string (yytext, yypos, arg)));
<INITIAL>{tyvar} => (T.TYVAR (string (yytext, yypos, arg)));
<INITIAL>{id} => (T.ALPHABETICID (string (yytext, yypos, arg)));
<INITIAL>{symid} => (T.SYMBOLICID (string (yytext, yypos, arg)));
<INITIAL>{prefixedlabel} => (T.PREFIXEDLABEL (string (yytext, yypos, arg)));
<INITIAL>"#"({id}) => 
         (let val (s, l, r) = string (yytext, yypos, arg)
          in T.SELECTOR (String.extract(s, 1, NONE), l, r)
          end
          );
<INITIAL>"#"({int}) => 
         (let val (s, l, r) = string (yytext, yypos, arg)
          in T.SELECTOR (String.extract(s, 1, NONE), l, r)
          end
          );
<INITIAL>"#"({prefixedlabel}) => 
         (let val (s, l, r) = string (yytext, yypos, arg)
          in T.SELECTOR (String.extract(s, 1, NONE), l, r)
          end
          );
<INITIAL>"0w"{num} =>
         (let val (s, l, r) = string (yytext, yypos, arg)
          in T.WORD ({radix = StringCvt.DEC,
                      digits = String.extract (s, 2, NONE)},
                     l, r)
          end);
<INITIAL>"~"?"0x"{xdigit}+ =>
         (let val (s, l, r) = string (yytext, yypos, arg)
          in T.INT ({radix = StringCvt.HEX, digits = s}, l, r)
          end);
<INITIAL>"0wx"{xdigit}+ =>
         (let val (s, l, r) = string (yytext, yypos, arg)
          in T.WORD ({radix = StringCvt.HEX,
                      digits = String.extract (s, 3, NONE)},
                     l, r)
          end);
<INITIAL>({int0}|~{num}) =>
         (let val (s, l, r) = string (yytext, yypos, arg)
          in T.INT ({radix = StringCvt.DEC, digits = s}, l, r)
          end);
<INITIAL>{int} => (T.INTLAB (string (yytext, yypos, arg)));
<INITIAL>{real} => (T.REAL (string (yytext, yypos, arg)));
<INITIAL>#\" => (startString (yypos, CHAR, arg); YYBEGIN STR; continue ());
<INITIAL>\" => (startString (yypos, STRING, arg); YYBEGIN STR; continue ());
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
                            (String.substring (yytext, 2, 4)))
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
