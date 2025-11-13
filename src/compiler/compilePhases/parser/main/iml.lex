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

structure T = Token

type lexresult = Token.token * (Loc.source * Loc.at * Loc.at)

(* if you use ml-lex of SML/NJ, you need to specify this to 2. *)
val INITIAL_POS_OF_LEXER = 0

datatype string_type = STRING | CHAR
type arg =
    {
      source : Loc.source,
      line : {count : int, begin : int} ref,
      error : string * (Loc.source * Loc.at * Loc.at) -> unit,
      comment : Loc.at list ref,
      string : {buf : string list ref,
                startPos : Loc.at option ref,
                ty : string_type ref},
      allowUtf8 : bool
    }

fun toPos source at1 : Loc.pos = {source = source, pos = at1}

fun initArg {source, errorFn, initialLineno, allowUtf8} =
    {
      source = source,
      line = ref {count = initialLineno, begin = INITIAL_POS_OF_LEXER},
      error = fn (msg, (s, p1, p2)) => errorFn (msg, toPos s p1, toPos s p2),
      comment = ref nil,
      string = {buf = ref nil, startPos = ref NONE, ty = ref STRING},
      allowUtf8 = allowUtf8
    } : arg

fun isINITIAL (arg : arg) =
    case arg of
      {comment = ref nil, string = {startPos = ref NONE, ...}, ...} => true
    | _ => false

fun newline pos yytext ({line as ref {count, begin}, ...} : arg) =
    line := {count = count + 1, begin = pos + size yytext}

fun pos yypos ({line = ref {count, begin}, ...} : arg) =
    Loc.AT {line = count,
            col = yypos - begin + 1,
            pos = yypos - INITIAL_POS_OF_LEXER,
            token = 0}

fun loc yytext yypos (arg as {source, ...}) =
    (source, pos yypos arg, pos (yypos + size yytext - 1) arg)

fun startComment yypos (arg as {comment,...}) =
    comment := pos yypos arg :: !comment

fun closeComment ({comment,...} : arg) =
    case !comment of
      nil => raise Bug.Bug "closeComment"
    | h :: t => (comment := t; case t of nil => SOME h | _ :: _ => NONE)

fun startString yypos strTy (arg as {string = {buf, startPos, ty}, ...}) =
    (buf := nil; startPos := SOME (pos yypos arg); ty := strTy)

fun closeString yypos (arg as {string = {buf, startPos, ty}, ...} : arg) =
    case !startPos of
      NONE => raise Bug.Bug "closeString"
    | SOME left =>
      let
        val loc = (#source arg, left, pos yypos arg)
        val s = String.concat (rev (!buf))
      in
        buf := nil;
        startPos := NONE;
        case !ty of
          STRING => (T.STRING s, loc)
        | CHAR => if size s = 1
                  then (T.CHAR s, loc)
                  else (T.HASH_STRING s, loc)
      end

fun addString s ({string = {buf, startPos, ...}, ...}:arg) =
    buf := s :: !buf

fun eof ({source, string, comment, error, ...} : arg) =
    (case !(#startPos string) of
       SOME pos => error ("unclosed string", (source, pos, Loc.EOF))
     | NONE => ();
     case !comment of
       pos :: _ => error ("unclosed comment", (source, pos, Loc.EOF))
     | nil => ();
     (T.EOF, (source, Loc.EOF, Loc.EOF)))

fun checkUtf8 yytext yypos (arg as {allowUtf8, error, ...} : arg) =
    if allowUtf8 then () else
    case CharVector.findi (fn (_, c) => ord c >= 127) yytext of
      NONE => ()
    | SOME (i, c) =>
      error ("illegal character code " ^ Int.toString (ord c),
             loc "_" (yypos + i) arg)

fun setIndex (Loc.AT pos) index = Loc.AT (pos # {token = index})
  | setIndex Loc.EOF _ = Loc.EOF

fun setupLexer tokens lexer =
    let
      val count = ref 0
    in
      fn () =>
         let
           val (token, (source, pos1, pos2)) = lexer ()
           val index = !count before count := !count + 1
           val at1 = setIndex pos1 index
           val at2 = setIndex pos2 index
           val pos1 = toPos source at1
           val pos2 = toPos source at2
         in
           tokens := !tokens ::> (token, (at1, at2));
           (token, (pos1, pos2))
         end
    end

%%

%full
%s COMM STR SKIP;
%structure ImlLex
%arg (arg);

utf8_t=[\128-\191];
utf8_2=[\194-\223]{utf8_t};
utf8_3=(\224[\160-\191]|\237[\128-\159]|[\225-\236\238\239]{utf8_t}){utf8_t};
utf8_4=(\240[\144-\191]|\244[\128-\143]|[\241-\243]{utf8_t}){utf8_t}{utf8_t};
utf8={utf8_2}|{utf8_3}|{utf8_4};

alpha=[A-Za-z]|{utf8};
digit=[0-9];
xdigit=[0-9a-fA-F];
alnum={alpha}|{digit}|"_";
alnumq={alnum}|"'";
ws="\012"|[\t\ ];
eol="\013\010"|"\010"|"\013";
tyvar="'"({alnum}{alnumq}*)?;
eqtyvar="''"{alnumq}*;
alnumid={alpha}{alnumq}*;
symbolid=[-!%&$#+/:<=>?@\\~`^|*]+;
intlab=[1-9]{digit}*;
int="0"{digit}*|~{digit}+;
frac="."{digit}+;
exp=[eE]"~"?{digit}+;
real="~"?{digit}+({frac}{exp}|{frac}|{exp});

%%

<INITIAL>{ws} => (continue ());
<INITIAL>{eol} => (newline yypos yytext arg; continue ());

<INITIAL>"abstype" => ((T.ABSTYPE, loc yytext yypos arg));
<INITIAL>"and" => ((T.AND, loc yytext yypos arg));
<INITIAL>"andalso" => ((T.ANDALSO, loc yytext yypos arg));
<INITIAL>"as" => ((T.AS, loc yytext yypos arg));
<INITIAL>"case" => ((T.CASE, loc yytext yypos arg));
<INITIAL>"datatype" => ((T.DATATYPE, loc yytext yypos arg));
<INITIAL>"do" => ((T.DO, loc yytext yypos arg));
<INITIAL>"else" => ((T.ELSE, loc yytext yypos arg));
<INITIAL>"end" => ((T.END, loc yytext yypos arg));
<INITIAL>"exception" => ((T.EXCEPTION, loc yytext yypos arg));
<INITIAL>"fn" => ((T.FN, loc yytext yypos arg));
<INITIAL>"fun" => ((T.FUN, loc yytext yypos arg));
<INITIAL>"handle" => ((T.HANDLE, loc yytext yypos arg));
<INITIAL>"if" => ((T.IF, loc yytext yypos arg));
<INITIAL>"in" => ((T.IN, loc yytext yypos arg));
<INITIAL>"infix" => ((T.INFIX, loc yytext yypos arg));
<INITIAL>"infixr" => ((T.INFIXR, loc yytext yypos arg));
<INITIAL>"let" => ((T.LET, loc yytext yypos arg));
<INITIAL>"local" => ((T.LOCAL, loc yytext yypos arg));
<INITIAL>"nonfix" => ((T.NONFIX, loc yytext yypos arg));
<INITIAL>"of" => ((T.OF, loc yytext yypos arg));
<INITIAL>"op" => ((T.OP, loc yytext yypos arg));
<INITIAL>"open" => ((T.OPEN, loc yytext yypos arg));
<INITIAL>"orelse" => ((T.ORELSE, loc yytext yypos arg));
<INITIAL>"raise" => ((T.RAISE, loc yytext yypos arg));
<INITIAL>"rec" => ((T.REC, loc yytext yypos arg));
<INITIAL>"then" => ((T.THEN, loc yytext yypos arg));
<INITIAL>"type" => ((T.TYPE, loc yytext yypos arg));
<INITIAL>"val" => ((T.VAL, loc yytext yypos arg));
<INITIAL>"with" => ((T.WITH, loc yytext yypos arg));
<INITIAL>"withtype" => ((T.WITHTYPE, loc yytext yypos arg));
<INITIAL>"while" => ((T.WHILE, loc yytext yypos arg));
<INITIAL>"(" => ((T.LPAREN, loc yytext yypos arg));
<INITIAL>")" => ((T.RPAREN, loc yytext yypos arg));
<INITIAL>"[" => ((T.LBRACKET, loc yytext yypos arg));
<INITIAL>"]" => ((T.RBRACKET, loc yytext yypos arg));
<INITIAL>"{" => ((T.LBRACE, loc yytext yypos arg));
<INITIAL>"}" => ((T.RBRACE, loc yytext yypos arg));
<INITIAL>"," => ((T.COMMA, loc yytext yypos arg));
<INITIAL>":" => ((T.COLON, loc yytext yypos arg));
<INITIAL>";" => ((T.SEMICOLON, loc yytext yypos arg));
<INITIAL>"..." => ((T.PERIODS, loc yytext yypos arg));
<INITIAL>"_" => ((T.UNDERBAR, loc yytext yypos arg));
<INITIAL>"|" => ((T.BAR, loc yytext yypos arg));
<INITIAL>"=" => ((T.EQ, loc yytext yypos arg));
<INITIAL>"=>" => ((T.DARROW, loc yytext yypos arg));
<INITIAL>"->" => ((T.ARROW, loc yytext yypos arg));
<INITIAL>"#" => ((T.HASH, loc yytext yypos arg));

<INITIAL>"eqtype" => ((T.EQTYPE, loc yytext yypos arg));
<INITIAL>"functor" => ((T.FUNCTOR, loc yytext yypos arg));
<INITIAL>"include" => ((T.INCLUDE, loc yytext yypos arg));
<INITIAL>"sharing" => ((T.SHARING, loc yytext yypos arg));
<INITIAL>"sig"=> ((T.SIG, loc yytext yypos arg));
<INITIAL>"signature" => ((T.SIGNATURE, loc yytext yypos arg));
<INITIAL>"struct" => ((T.STRUCT, loc yytext yypos arg));
<INITIAL>"structure" => ((T.STRUCTURE, loc yytext yypos arg));
<INITIAL>"where" => ((T.WHERE, loc yytext yypos arg));
<INITIAL>":>" => ((T.OPAQUE, loc yytext yypos arg));

<INITIAL>"*" => ((T.ASTERISK, loc yytext yypos arg));
<INITIAL>"." => ((T.PERIOD, loc yytext yypos arg));

<INITIAL>"__attribute__" => ((T.U_ATTRIBUTE, loc yytext yypos arg));
<INITIAL>"_builtin" => ((T.U_BUILTIN, loc yytext yypos arg));
<INITIAL>"_foreach" => ((T.U_FOREACH, loc yytext yypos arg));
<INITIAL>"_import" => ((T.U_IMPORT, loc yytext yypos arg));
<INITIAL>"_interface" => ((T.U_INTERFACE, loc yytext yypos arg));
<INITIAL>"_join" => ((T.U_JOIN, loc yytext yypos arg));
<INITIAL>"_extend" => ((T.U_EXTEND, loc yytext yypos arg));
<INITIAL>"_update" => ((T.U_UPDATE, loc yytext yypos arg));
<INITIAL>"_dynamic" => ((T.U_DYNAMIC, loc yytext yypos arg));
<INITIAL>"_dynamiccase" => ((T.U_DYNAMICCASE, loc yytext yypos arg));
<INITIAL>"_dynamicnull" => ((T.U_DYNAMICNULL, loc yytext yypos arg));
<INITIAL>"_dynamicview" => ((T.U_DYNAMICVIEW, loc yytext yypos arg));
<INITIAL>"_dynamicvoid" => ((T.U_DYNAMICVOID, loc yytext yypos arg));
<INITIAL>"_polyrec" => ((T.U_POLYREC, loc yytext yypos arg));
<INITIAL>"_reifyTy" => ((T.U_REIFYTY, loc yytext yypos arg));
<INITIAL>"_require" => ((T.U_REQUIRE, loc yytext yypos arg));
<INITIAL>"_sizeof" => ((T.U_SIZEOF, loc yytext yypos arg));
<INITIAL>"_sql" => ((T.U_SQL, loc yytext yypos arg));
<INITIAL>"_sqleval" => ((T.U_SQLEVAL, loc yytext yypos arg));
<INITIAL>"_sqlexec" => ((T.U_SQLEXEC, loc yytext yypos arg));
<INITIAL>"_sqlserver" => ((T.U_SQLSERVER, loc yytext yypos arg));
<INITIAL>"_use" => ((T.U_USE, loc yytext yypos arg));

<INITIAL>"_"{eqtyvar} => ((T.FREE_EQTYVAR yytext, loc yytext yypos arg));
<INITIAL>"_"{tyvar} => ((T.FREE_TYVAR yytext, loc yytext yypos arg));
<INITIAL>{eqtyvar} => ((T.EQTYVAR yytext, loc yytext yypos arg));
<INITIAL>{tyvar} => ((T.TYVAR yytext, loc yytext yypos arg));
<INITIAL>{alnumid} => (checkUtf8 yytext yypos arg;
		       (T.ALNUMID yytext, loc yytext yypos arg));
<INITIAL>{symbolid} => ((T.SYMBOLID yytext, loc yytext yypos arg));

<INITIAL>"0w"{digit}+ => ((T.WORD yytext, loc yytext yypos arg));
<INITIAL>"~"?"0x"{xdigit}+ => ((T.INTX yytext, loc yytext yypos arg));
<INITIAL>"0wx"{xdigit}+ => ((T.WORDX yytext, loc yytext yypos arg));
<INITIAL>{int} => ((T.INT yytext, loc yytext yypos arg));
<INITIAL>{intlab} => ((T.INTLAB yytext, loc yytext yypos arg));
<INITIAL>{real} => ((T.REAL yytext, loc yytext yypos arg));
<INITIAL>#\" => (startString yypos CHAR arg; YYBEGIN STR; continue ());
<INITIAL>\" => (startString yypos STRING arg; YYBEGIN STR; continue ());

<INITIAL>"(*" => (startComment yypos arg; YYBEGIN COMM; continue ()
  (* Unlike "(*", unmatched "*)" should not cause parse error. It should
   * be regarded as two tokens "*" and ")". *)
);
<INITIAL>. => (#error arg ("illegal character code "
                           ^ Int.toString (ord (String.sub (yytext, 0))),
                           loc yytext yypos arg);
               continue ());

<COMM>{eol} => (newline yypos yytext arg; continue ());
<COMM>"(*"  => (startComment yypos arg; continue ());
<COMM>"*)"  => (case closeComment arg of
                  NONE => continue ()
                | SOME left =>
                  (YYBEGIN INITIAL;
                   (T.COMMENT, (#source arg, left, pos (yypos + 2) arg))));
<COMM>.     => (continue ());

<STR>{eol} => (let val (tok, loc) = closeString yypos arg
               in #error arg ("unclosed string", loc);
                  newline yypos yytext arg;
                  YYBEGIN INITIAL;
                  (tok, loc)
               end);
<STR>\" => (YYBEGIN INITIAL; closeString yypos arg);
<STR>\\{eol} => (newline yypos yytext arg; YYBEGIN SKIP; continue ());
<STR>\\{ws} => (YYBEGIN SKIP; continue ());
<STR>\\a => (addString "\007" arg; continue ());
<STR>\\b => (addString "\008" arg; continue ());
<STR>\\f => (addString "\012" arg; continue ());
<STR>\\n => (addString "\010" arg; continue ());
<STR>\\r => (addString "\013" arg; continue ());
<STR>\\t => (addString "\009" arg; continue ());
<STR>\\v => (addString "\011" arg; continue ());
<STR>\\\\ => (addString "\\" arg; continue ());
<STR>\\\" => (addString "\"" arg; continue ());
<STR>\\\^[@-_] => (addString
                     (str (chr (ord (String.sub (yytext, 2)) - 64)))
                     arg;
                   continue ());
<STR>\\\^. => (#error arg
                 ("illegal control escape; must be one of \
                  \@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_",
                  loc yytext yypos arg);
               continue ());
<STR>\\[0-9]{3} =>
        (let
           val c = StringCvt.scanString
                     (Int.scan StringCvt.DEC)
                     (String.substring (yytext, 1, 3))
         in
           addString (str (chr (valOf c))) arg
           handle _ => #error arg ("illegal decimal escape sequence",
                                   loc yytext yypos arg);
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
           if x <= 0wx7f
           then (addString (str (byte (x,  0w0, 0wx7f, 0wx00))) arg)
           else if x <= 0wx7ff
           then (addString (str (byte (x,  0w6, 0wx1f, 0wxc0))) arg;
                 addString (str (byte (x,  0w0, 0wx3f, 0wx80))) arg)
           else (addString (str (byte (x, 0w12, 0wx0f, 0wxe0))) arg;
                 addString (str (byte (x,  0w6, 0wx3f, 0wx80))) arg;
                 addString (str (byte (x,  0w0, 0wx3f, 0wx80))) arg);
           continue ()
        end);
<STR>\\ => (#error arg ("illegal escape sequence", loc yytext yypos arg);
            continue ());
<STR>([^\000-\031\\\"\127-\255]|{utf8})+ =>
        (checkUtf8 yytext yypos arg;
         addString yytext arg; continue ());
<STR>. => (#error arg ("illegal character code "
                       ^ Int.toString (ord (String.sub (yytext, 0))),
                       loc yytext yypos arg);
           continue ());

<SKIP>{eol} => (newline yypos yytext arg; continue());
<SKIP>{ws} => (continue());
<SKIP>\\ => (YYBEGIN STR; continue ());
<SKIP>. => (#error arg ("unclosed string", loc yytext yypos arg);
            YYBEGIN STR;
            continue ());
