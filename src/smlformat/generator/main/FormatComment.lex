(* -*- sml-lex -*- *)

structure T = FormatCommentLrVals.Tokens
type token = T.token
type pos = T.pos
type lexresult = T.token

(* if you use ml-lex of SML/NJ, you need to specify this to 2. *)
val INITIAL_POS_OF_LEXER = 0

type arg =
    {
      error : string * pos * pos -> unit,
      comment : pos list ref,
      string : {buf : string list ref, startPos : pos option ref},
      offset : int
    }

fun initArg {error, offset} =
    {
      error = error,
      comment = ref nil,
      string = {buf = ref nil, startPos = ref NONE},
      offset = offset
    } : arg

fun startComment (yypos, arg as {comment,...}) =
    comment := yypos :: !comment

fun closeComment ({comment,...}:arg) =
    case !comment of
      nil => raise Fail "BUG: closeComment"
    | h::t => (comment := t; case t of nil => true | _::_ => false)

fun pos (yypos, yytext, {offset, ...} : arg) =
    (offset + yypos, offset + yypos + size yytext - 1)

fun startString (yypos, arg as {string = {buf, startPos}, ...} : arg) =
    (buf := nil; startPos := SOME yypos)

fun closeString (yypos, arg as {string = {buf, startPos}, ...} : arg) =
    case !startPos of
      NONE => raise Fail "BUG: closeString"
    | SOME l =>
      (T.STRING (String.concat (rev (!buf)), l, yypos), l, yypos)
      before (buf := nil; startPos := NONE)

fun addString (s, {string = {buf, ...}, ...}:arg) =
    buf := s :: !buf

fun eof ({string, comment, error, ...} : arg) =
    (case !(#startPos string) of
       SOME pos => error ("unclosed string", pos, ~1)
     | NONE => ();
     case !comment of
       pos::_ => error ("unclosed comment", pos, ~1)
     | nil => ();
     T.EOF (~1, ~1))

%%

%full
%s COMM FC FCOMM STR;
%structure FormatCommentLex
%arg (arg);

underscore="\_";
alpha=[A-Za-z\128-\255];
digit=[0-9];
xdigit=[0-9a-fA-F];
alnum=({alpha}|{digit}|{underscore});
id=({alpha}({alnum}|"'")*);
ws=("\012"|[\t\ ]);
eol=("\013\010"|"\010"|"\013");
symid=([-!%&$#+/:<=>?@\\~`^|*]+);
int=([1-9]{digit}*);
num={digit}+;
prefixedlabel={int}"_"({id}|{symid});

%%

<INITIAL>{ws} => (continue());
<INITIAL>{eol} => (continue ());
<INITIAL>"(*%" => (YYBEGIN FC; T.FORMATCOMMENTSTART (pos (yypos, yytext, arg)));
<INITIAL>"(*" => (startComment (yypos, arg); YYBEGIN COMM; continue ());
<INITIAL>. => (case pos (yypos, yytext, arg) of
                 (l, r) => T.SPECIAL (String.sub (yytext, 0), l, r));

<COMM>{eol} => (continue ());
<COMM>"(*" => (startComment (yypos, arg); continue ());
<COMM>"*)" => (if closeComment arg then YYBEGIN INITIAL else (); continue ());
<COMM>. => (continue ());

<FCOMM>{eol} => (continue ());
<FCOMM>"(*" => (startComment (yypos, arg); continue ());
<FCOMM>"*)" => (if closeComment arg then YYBEGIN FC else (); continue ());
<FCOMM>. => (continue ());

<FC>{eol} => (continue());
<FC>{ws} => (continue());
<FC>^{ws}*"*" => (continue());
<FC>"(*" => (startComment (yypos, arg); YYBEGIN FCOMM; continue ());
<FC>"*)" => (YYBEGIN INITIAL; T.FORMATCOMMENTEND (pos (yypos, yytext, arg)));
<FC>^{ws}*"*)" =>
        (YYBEGIN INITIAL; T.FORMATCOMMENTEND (pos (yypos, yytext, arg)));
<FC>\" => (startString (yypos, arg); YYBEGIN STR; continue ());
<FC>"@ditto" => (T.DITTOTAG (pos (yypos, yytext, arg)));
<FC>"@prefix" => (T.PREFIXTAG (pos (yypos, yytext, arg)));
<FC>"@formatter" => (T.FORMATTERTAG (pos (yypos, yytext, arg)));
<FC>"@params" => (T.FORMATPARAMSTAG (pos (yypos, yytext, arg)));
<FC>"@extern" => (T.FORMATEXTERNTAG (pos (yypos, yytext, arg)));
<FC>"@destination" => (T.DESTINATIONTAG (pos (yypos, yytext, arg)));
<FC>"@header" => (T.HEADERTAG (pos (yypos, yytext, arg)));
<FC>"@format" => (T.FORMATTAG (pos (yypos, yytext, arg)));
<FC>"@format:"{id} => (T.LOCALFORMATTAG (String.extract (yytext, 8, NONE),
                                         yypos, yypos + size yytext - 1));
<FC>"\\n" => (T.NEWLINE (pos (yypos, yytext, arg)));
<FC>"*" => (T.ASTERISK (pos (yypos, yytext, arg)));
<FC>":" => (T.COLON (pos (yypos, yytext, arg)));
<FC>"," => (T.COMMA (pos (yypos, yytext, arg)));
<FC>"..." => (T.DOTDOTDOT (pos (yypos, yytext, arg)));
<FC>"." => (T.DOT (pos (yypos, yytext, arg)));
<FC>"{" => (T.LBRACE (pos (yypos, yytext, arg)));
<FC>"}" => (T.RBRACE (pos (yypos, yytext, arg)));
<FC>"]" => (T.RBRACKET (pos (yypos, yytext, arg)));
<FC>"(" => (T.LPAREN (pos (yypos, yytext, arg)));
<FC>")" => (T.RPAREN (pos (yypos, yytext, arg)));
<FC>"_" => (T.WILD (pos (yypos, yytext, arg)));
<FC>("~")?{int}"[" =>
        (case pos (yypos, yytext, arg) of
           (l, r) => T.STARTOFINDENT (valOf (Int.fromString yytext), l, r));
<FC>"+" => (case pos (yypos, yytext, arg) of
              (l, r) => T.FORMATINDICATOR
                          ({space = true, newline = NONE}, l, r));
<FC>"+"?("d"|{int}) =>
        (let
           val space = String.sub (yytext, 0) = #"+"
           val priorityText =
               if space then String.extract (yytext, 1, NONE) else yytext
           val priority =
               if priorityText = "d"
               then FormatTemplate.Deferred
               else FormatTemplate.Preferred
                      (valOf (Int.fromString (priorityText)))
           val indicatorArg =
               {space = space, newline = SOME{priority = priority}}
           val (l, r) = pos (yypos, yytext, arg)
         in
           T.FORMATINDICATOR (indicatorArg, l, r)
         end);
<FC>"!"?[LRN]("~")?{num} =>
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
                | _ => raise Fail "BUG: illegal direction"
           val strengthText = String.extract (yytext, numStartPos, NONE)
           val strength = valOf (Int.fromString strengthText)
           val (l, r) = pos (yypos, yytext, arg)
         in
           T.ASSOCINDICATOR
             ({cut = cut, strength = strength, direction = direction}, l, r)
         end);
<FC>{id} =>
        (case pos (yypos, yytext, arg) of (l, r) => T.ID (yytext, l, r));
<FC>{prefixedlabel} =>
        (case pos (yypos, yytext, arg) of
           (l, r) => T.PREFIXEDLABEL (yytext, l, r));
<FC>. =>
        (case pos (yypos, yytext, arg) of
           (l, r) => T.SPECIAL (String.sub (yytext, 0), l, r));

<STR>{eol} => (let val (t, l, r) = closeString (yypos, arg)
               in #error arg ("unclosed string", l, r);
                  YYBEGIN FC;
                  t
               end);
<STR>\" => (YYBEGIN FC; #1 (closeString (yypos, arg)));
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
                  yypos,
                  yypos + size yytext - 1);
               continue ());
<STR>\\[0-9]{3} =>
        (let
           val c = StringCvt.scanString
                     (Int.scan StringCvt.DEC)
                     (String.substring (yytext, 1, 3))
         in
           addString (str (chr (valOf c)), arg)
           handle _ => #error arg ("illegal ascii escape",
                                   yypos,
                                   yypos + size yytext - 1);
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
                        #offset arg + yypos, #offset arg + yypos);
            continue ());
<STR>[^\000-\031\\\"\r\n]+ => (addString (yytext, arg); continue ());
<STR>. => (#error arg
             ("illegal non-printing character in string",
              #offset arg + yypos, #offset arg + yypos);
           continue());
