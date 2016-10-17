(*
 * lexical structures of IML.
 *   the part of constant specifications is based on 
 *   that of the SML New Jersye implementation
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 * @version $Id: iml.lex,v 1.42.6.6 2010/01/22 09:19:06 hiro-en Exp $
 *)

structure T = MLLrVals.Tokens

type token = T.token
type pos = Loc.pos
type lexresult = T.token

(* if you use ml-lex of SML/NJ, you need to specify this to 2. *)
val INITIAL_POS_OF_LEXER = 0

exception Error

datatype stringType = STRING | CHAR | NOSTR
type arg =
{
  inFormatComment : bool ref,
  fileName : string,
  isPrelude : bool,
  enableMeta : bool,
  lexError : (string * pos * pos) -> unit,
  stringBuf : string list ref,
  stringStart : pos ref,
  stringType : stringType ref,
  commentStart : pos list ref,
  lineMap : {lineCount : int, beginPos : int} list ref,
  lineCount : int ref,
  charCount : int ref,
  initialCharCount : int,
  allow8bitId : bool
}


fun initArg {sourceName, isPrelude, enableMeta, lexErrorFn, initialLineno, allow8bitId} : arg =
    let
      val startPos = Loc.makePos {fileName = sourceName, line = 0, col = 0}
    in
      {
       inFormatComment = ref false,
       fileName = sourceName,
       isPrelude = isPrelude,
       enableMeta = enableMeta,
       lexError = lexErrorFn,
       stringBuf = ref nil,
       stringStart = ref startPos,
       stringType = ref NOSTR,
       commentStart = ref nil,
       lineMap = ref [{lineCount = initialLineno,
                       beginPos = INITIAL_POS_OF_LEXER}],
       lineCount = ref initialLineno,
       charCount = ref INITIAL_POS_OF_LEXER,
       initialCharCount = 0,
       allow8bitId = allow8bitId
      } : arg
    end

fun isINITIAL ({commentStart = ref nil, stringType = ref NOSTR, ...}:arg) = true
  | isINITIAL _ = false

fun newLine (pos, eolString, arg : arg) =
    (
      #lineCount arg := !(#lineCount arg) + 1;
      #lineMap arg :=
      {lineCount = !(#lineCount arg), beginPos = pos + size eolString}
      :: !(#lineMap arg)
    )

fun currentPos (pos, offset, arg : arg) =
    let
      (*  pos is the number of chars which has been read by this lexer.
       * Because a new lexer is created at each time when any error is found,
       * it means that this pos is not always started from the beginning of
       * the current source.
       *  On the other hand, the lineMap records absolute positions of
       * newlines. These positions start from the beginning of the current
       * source.
       *  The initialCharCount holds the absolute position of location in the
       * source where the current lexer begins to scan.
       *  The next line converts the pos into an absolute one.
       *)
      val absolutePos = pos + (#initialCharCount arg)
    in
      (*  Then, we search for a lineMap entry for the line which contains the
       * location that is pointed by the absolutePos.
       *  Entries in the lineMap are sorted in descending order of line count.
       *  An entry for the line which has been read last is at the top of the
       * lineMap.
       *  Therefore, we scan the lineMap from the top to the last.
       *)
      case
        List.find
          (fn{beginPos, ...} => beginPos <= absolutePos)
          (!(#lineMap arg))
       of
        SOME{lineCount, beginPos} =>
        Loc.makePos 
          {
            fileName = #fileName arg,
            line = lineCount,
            col = absolutePos - beginPos + offset + 0 (* first column is 0. *)
          }
      | NONE =>
        let 
          val message = 
              "lineCount of " ^ Int.toString absolutePos ^ " is not found."
        in
          #lexError arg (message, Loc.nopos, Loc.nopos); Loc.nopos
      (*
          raise Bug.Bug message
       *)
        end
            
    end
fun left (pos, arg) = currentPos(pos, 0, arg)
fun right (pos, size, arg) = currentPos(pos, size - 1, arg)
fun addString (buffer, string) = buffer := string :: (!buffer)
fun strToLoc (text, pos, arg) = 
    let
      val leftPos = left(pos, arg)
      val rightPos = right(pos, String.size text, arg)
    in
      (leftPos, rightPos)
    end
fun addChar (buffer, string) = buffer := String.str string :: (!buffer)
fun makeString (buffer) = concat (rev (!buffer)) before buffer := nil

fun eof ({commentStart, stringStart, stringType, lexError,
          ...}:arg) =
    (case !commentStart of
       nil => ()
     | pos::_ => lexError ("unclosed comment", pos, Loc.nopos);
     case !stringType of
       NOSTR => ()
     | STRING => lexError ("unclosed string", !stringStart, Loc.nopos)
     | CHAR => lexError ("unclosed character constant",
			 !stringStart, Loc.nopos);
     T.EOF (Loc.nopos, Loc.nopos))

fun isSuffix char string =
    0 < size string andalso String.sub (string, size string - 1) = char

fun pushComment (commentStart, yypos, arg) =
    commentStart := left(yypos, arg) :: !commentStart
fun popComment (commentStart) =
    case !commentStart of
      _::t => commentStart := t
    | nil => raise Bug.Bug "unmatched closing comment"
fun commentLevel (commentStart) =
    List.length (!commentStart)
local
  fun cvt radix (s, i) =
	#1(valOf(Int.scan radix Substring.getc (Substring.triml i (Substring.full s))))
in
val atoi = cvt StringCvt.DEC
val xtoi = cvt StringCvt.HEX
end (* local *)

fun check8bitId (arg:arg) (yytext, yypos) =
    if #allow8bitId arg orelse CharVector.all (fn x => ord x < 128) yytext
    then ()
    else #lexError arg ("8 bit characters in ID is not permitted",
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
%s A S F FC FCC;
%header (
structure MLLex
);
%arg (arg as 
      {
        inFormatComment,
        fileName,
        isPrelude,
        enableMeta,
        lexError,
        stringBuf,
        stringStart,
        stringType,
        commentStart,
        lineMap,
        lineCount,
        charCount,
        initialCharCount,
        ...
      });

quote="'";
underscore="\_";
alpha=[A-Za-z\127-\255];
digit=[0-9];
idchars={alpha}|{digit}|{quote}|{underscore};
id=({alpha}|{quote}){idchars}*;
ws=("\012"|[\t\ ])*;
eol=("\013\010"|"\010"|"\013");
sym=[!%&$+/:<=>?@~`|#*]|\-|\^;
symbol={sym}|\\;
num=[0-9]+;
positive=[1-9][0-9]*;
frac="."{num};
exp=[eE](~?){num};
real=(~?)(({num}{frac}?{exp})|({num}{frac}{exp}?));
hexnum=[0-9a-fA-F]+;
prefixedlabel={positive}"_"({alpha}{idchars}*|{symbol}+);
%%
<INITIAL>{ws} => (continue());
<INITIAL>{eol} => (newLine(yypos, yytext, arg); continue ());
<INITIAL>"abstype" => (T.ABSTYPE (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"andalso" => (T.ANDALSO (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"and" => (T.AND (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"as" => (T.AS (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"__attribute__" => (T.ATTRIBUTE (left(yypos,arg),right(yypos,13,arg)));
<INITIAL>"_builtin" => (T.BUILTIN (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"case" => (T.CASE (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"datatype" => (T.DATATYPE (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"do" => (T.DO (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"else" => (T.ELSE (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"end" => (T.END (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"eqtype" => (T.EQTYPE (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"exception" => (T.EXCEPTION (left(yypos,arg),right(yypos,9,arg)));
<INITIAL>"_ffiapply" => (T.FFIAPPLY (left(yypos,arg),right(yypos,9,arg)));
<INITIAL>"fn" => (T.FN (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"fun" => (T.FUN (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"functor" => (T.FUNCTOR (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"handle" => (T.HANDLE (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"if" => (T.IF (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"_import" => (T.IMPORT (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"in" => (T.IN (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"include" => (T.INCLUDE (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"infix" => (T.INFIX (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"infixr" => (T.INFIXR (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"_interface" => (T.INTERFACE (left(yypos,arg),right(yypos,10,arg)));
<INITIAL>"_join" => (T.JOINOP (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"_json" => (T.JSON (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"_jsoncase" => (T.JSONCASE (left(yypos,arg),right(yypos,9,arg)));
<INITIAL>"nonfix" => (T.NONFIX (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"let" => (T.LET (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"local" => (T.LOCAL (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"of" => (T.OF (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"op" => (T.OP (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"open" => (T.OPEN(left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"orelse" => (T.ORELSE (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"_NULL" => (T.NULL (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"raise" => (T.RAISE (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"rec" => (T.REC (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"_polyrec" => (T.POLYREC (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"_require" => (T.REQUIRE (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"sharing" => (T.SHARING (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"sig"=> (T.SIG (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"signature" => (T.SIGNATURE (left(yypos,arg),right(yypos,9,arg)));
<INITIAL>"_sizeof" => (T.SIZEOF (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"struct" => (T.STRUCT (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"structure" => (T.STRUCTURE (left(yypos,arg),right(yypos,9,arg)));
<INITIAL>"then" => (T.THEN (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"type" => (T.TYPE (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"use" => (if enableMeta
                   then T.USE (left(yypos,arg),right(yypos,3,arg))
                   else T.ALPHABETICID (yytext,left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"_use" => (T.USE' (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"val" => (T.VAL (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"where" => (T.WHERE (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"while" => (T.WHILE (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"with" => (T.WITH (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"withtype" => (T.WITHTYPE (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"_sqlserver" => (T.SQLSERVER (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"_sqleval" => (T.SQLEVAL (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"_sqlexec" => (T.SQLEXEC (left(yypos,arg),right(yypos,8,arg)));

<INITIAL>"_sql" => (T.SQL (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"asc" => (T.ASC (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"desc" => (T.DESC (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"select" => (T.SELECT (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"all" => (T.ALL (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"distinct" => (T.DISTINCT (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"from" => (T.FROM (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"order" => (T.ORDER (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"by" => (T.BY (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"insert" => (T.INSERT (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"into" => (T.INTO (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"values" => (T.VALUES (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"delete" => (T.DELETE (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"update" => (T.UPDATE (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"set" => (T.SET (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"default" => (T.DEFAULT (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"begin" => (T.BEGIN (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"commit" => (T.COMMIT (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"rollback" => (T.ROLLBACK (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"inner" => (T.INNER (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"cross" => (T.CROSS (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"natural" => (T.NATURAL (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"join" => (T.JOIN (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"on" => (T.ON (left(yypos,arg),right(yypos,2,arg)));

<INITIAL>":>" => (T.OPAQUE (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"*" => (T.ASTERISK(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"#" => (T.HASH(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"(" => (T.LPAREN(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>")" => (T.RPAREN(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"," => (T.COMMA(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"->" => (T.ARROW (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"." => (T.PERIOD (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"..." => (T.PERIODS (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>":" => (T.COLON(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>";" => (T.SEMICOLON(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"=" => (T.EQ(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"=>" => (T.DARROW (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"[" => (T.LBRACKET(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"]" => (T.RBRACKET(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"_" => (T.UNDERBAR(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"{" => (T.LBRACE(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"|" => (T.BAR(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"}" => (T.RBRACE(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>{id} =>
    (let
(*
       val _ = check8bitId arg (yytext, yypos)
*)
       val loc = strToLoc(yytext, yypos, arg)
       val textSize = String.size yytext
     in
       if String.isPrefix "''" yytext
       then
         T.EQTYVAR(String.substring(yytext, 2, textSize - 2), #1 loc, #2 loc)
       else if #isPrelude arg andalso
               String.isPrefix "'_" yytext andalso
               isSuffix #"'" yytext
       then T.ALPHABETICID(String.substring(yytext, 1, textSize - 2), #1 loc, #2 loc)
       else if String.isPrefix "'" yytext
       then T.TYVAR(String.substring(yytext, 1, textSize - 1), #1 loc, #2 loc)
       else T.ALPHABETICID(yytext, #1 loc, #2 loc)
     end);
<INITIAL>{symbol}+ =>
        (T.SYMBOLICID
          (yytext, left(yypos, arg), right(yypos, String.size yytext, arg)));
<INITIAL>{real} =>
        (T.REAL
          (yytext, left(yypos, arg), right(yypos, String.size yytext, arg)));
<INITIAL>{num} =>
        (let val (l,r) = strToLoc(yytext, yypos, arg)
         in if String.isPrefix "0" yytext
            then T.INT ({radix=StringCvt.DEC, digits=yytext},l,r)
            else T.INTLAB (yytext,l,r)
         end);
<INITIAL>{prefixedlabel} =>
        (let val (l,r) = strToLoc(yytext, yypos, arg)
         in T.PREFIXEDLABEL (yytext,l,r)
         end);
<INITIAL>~{num} =>
        (let val (l,r) = strToLoc(yytext, yypos, arg)
         in T.INT ({radix=StringCvt.DEC, digits=yytext},l,r)
         end);
<INITIAL>"0w"{num} => 
        (let val (l,r) = strToLoc(yytext, yypos, arg)
         in T.WORD ({radix=StringCvt.DEC, digits=yytext}, l, r)
         end);
<INITIAL>(~?)"0x"{hexnum} => 
        (let val (l,r) = strToLoc(yytext, yypos, arg)
         in T.INT ({radix=StringCvt.HEX, digits=yytext}, l, r)
         end);
<INITIAL>"0wx"{hexnum} =>
        (let val (l,r) = strToLoc(yytext, yypos, arg)
         in T.WORD ({radix=StringCvt.HEX, digits=yytext}, l, r)
         end);
<INITIAL>\" => (
                 stringBuf := nil; 
                 stringStart := left(yypos, arg);
                 stringType := STRING;
                 YYBEGIN S;
                 continue()
               );
<INITIAL>\#\" => (
                    stringBuf := nil; 
                    stringStart := left(yypos, arg);
                    stringType := CHAR;
                    YYBEGIN S;
                    continue()
                  );
<INITIAL>"(*" => (YYBEGIN A;
                  pushComment(commentStart, yypos, arg);
                  continue()
 (* Unlike "(*", unmatched "*)" should not cause parse error. It should
  * be regarded as two tokens "*" and ")". *)
                 );
<INITIAL>"(*%"	=> (YYBEGIN FC; 
                    inFormatComment := true; 
                    stringStart := left(yypos, arg); 
                    pushComment(commentStart, yypos, arg);
                    T.FORMATCOMMENTSTART(left(yypos, arg), right(yypos, size yytext, arg)));

<INITIAL>\h => (
                 lexError
                 (
                   "non-Ascii character",
                   left(yypos, arg),
                   right(yypos, 1, arg)
                 );
                 continue()
               );
<INITIAL>. => (
                lexError
                ("illegal token", left(yypos, arg), right(yypos, 1, arg));
                continue()
              );
<FC>"(*" => (YYBEGIN FCC; 
             pushComment(commentStart, yypos, arg);
             continue());

<A,FCC>"(*"  => (
                 pushComment(commentStart, yypos, arg);
                 continue());

<A,FC,FCC>{eol} => (newLine(yypos, yytext, arg); continue ());

<A>"*)" => (
            popComment(commentStart);
            if commentLevel(commentStart) = 0 then
              (inFormatComment := false; YYBEGIN INITIAL)
            else ();
            continue()
           );
<FCC>"*)" => (
              popComment(commentStart);
              if commentLevel(commentStart) = 1 then YYBEGIN FC else (); 
              continue()
             );
<FC>"*)" => (
             popComment(commentStart);
             if commentLevel(commentStart) = 0
             then
               (inFormatComment := false;
                YYBEGIN INITIAL;
                T.FORMATCOMMENTEND(left(yypos, arg), right(yypos, size yytext, arg)))
             else raise Bug.Bug "unmatched opening comment"
             );
<A,FCC>. => (continue());

<FC>^{ws}*"*)" =>
    (popComment(commentStart);
     if commentLevel(commentStart) = 0
     then
       (inFormatComment := false;
        YYBEGIN INITIAL;
        T.FORMATCOMMENTEND(left(yypos, arg), right(yypos, size yytext, arg)))
     else continue());
<FC>^{ws}*"*" => (continue());
<FC>\"          => (stringBuf := [""]; stringStart := left(yypos, arg);
                    stringType := STRING; YYBEGIN S; continue());
<FC>"@ditto"  => (T.DITTOTAG(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"@prefix"   => (T.PREFIXTAG(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"@formatter"   => (T.FORMATTERTAG(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"@params"   => (T.FORMATPARAMSTAG(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"@format"   => (T.FORMATTAG(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"@destination" => (T.DESTINATIONTAG(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"@header" => (T.HEADERTAG(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"\\n" => (T.NEWLINE(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>("~")?{num}"["    => (T.STARTOFINDENT(atoi(yytext, 0), left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"+"         => (T.FORMATINDICATOR({space = true, newline = NONE}, left(yypos, arg), right(yypos, String.size yytext, arg)));
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
      T.FORMATINDICATOR
      (indicatorArg, left(yypos, arg), right(yypos, String.size yytext, arg))
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
         T.ASSOCINDICATOR
         ({
            cut = cut,
            strength = strength,
            direction = direction
          },
          left(yypos, arg), right(yypos, String.size yytext, arg))
       end);
<FC>{id}        => 
    (
(*
      check8bitId arg (yytext, yypos);
*)
      T.ALPHABETICID(yytext,left(yypos, arg), right(yypos, String.size yytext, arg))
    );
<FC>"'"({id}|{num})"'"  =>
        (check8bitId arg (yytext, yypos);
         T.ALPHABETICID(String.substring(yytext,1,(size yytext)-2),
                   left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"*"         => (T.ASTERISK(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>":"         => (T.COLON(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>","	        => (T.COMMA(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"..."	=> (T.PERIODS(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"."		=> (T.PERIOD(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"{"	        => (T.LBRACE(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"}"	        => (T.RBRACE(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"]"	        => (T.RBRACKET(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"("	        => (T.LPAREN(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>")"	        => (T.RPAREN(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>"_"         => (T.UNDERBAR(left(yypos, arg), right(yypos, String.size yytext, arg)));
<FC>{ws}	=> (continue());
<FC>{eol}	=> (newLine(yypos, yytext, arg); continue());
<FC>.           =>
   (lexError("ml lexer: bad character in format comment:"^yytext, left(yypos, arg), right(yypos, 1, arg));
    continue());

<S>\"	        =>
    (let
       val s = makeString stringBuf
       val s = if size s <> 1 andalso  !stringType = CHAR
               then
                 (lexError("character constant not length 1", !stringStart, left(yypos, arg));
                  substring(s^"x",0,1))
               else s
       val t = (s,!stringStart, right(yypos, 1, arg))
     in
       if !inFormatComment then YYBEGIN FC else YYBEGIN INITIAL;
       case !stringType before stringType := NOSTR of
         STRING => T.STRING t
       | CHAR => T.CHAR t
       | NOSTR => raise Bug.Bug "close string"
     end);

<S>{eol} => (
              lexError
              ("unclosed string", left(yypos, arg), right(yypos, 1, arg));
              stringType := NOSTR;
              newLine(yypos, yytext, arg); 
              YYBEGIN INITIAL;
              T.STRING
              (makeString stringBuf, !stringStart, right(yypos, 1, arg))
            );
<S>\\{eol} => (newLine(yypos, yytext, arg); YYBEGIN F; continue());
<S>\\{ws} => (YYBEGIN F; continue());
<S>\\a => (addString(stringBuf, "\007"); continue());
<S>\\b => (addString(stringBuf, "\008"); continue());
<S>\\f => (addString(stringBuf, "\012"); continue());
<S>\\n => (addString(stringBuf, "\010"); continue());
<S>\\r => (addString(stringBuf, "\013"); continue());
<S>\\t => (addString(stringBuf, "\009"); continue());
<S>\\v => (addString(stringBuf, "\011"); continue());
<S>\\\\ => (addString(stringBuf, "\\"); continue());
<S>\\\" => (addString(stringBuf, "\""); continue());
<S>\\\^[@-_] => (
                  addChar
                  (
                    stringBuf,
                    Char.chr(Char.ord(String.sub(yytext, 2)) - (Char.ord #"@"))
                  );
                  continue()
                );
<S>\\\^. => (
              lexError
              (
                "illegal control escape; must be one of \
                \@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_",
                left(yypos, arg),
                right(yypos, size yytext, arg)
              );
              continue()
            );
<S>\\[0-9]{3} => (let
                    val x = Char.ord(String.sub(yytext, 1)) * 100
                            + Char.ord(String.sub(yytext, 2)) * 10
                            + Char.ord(String.sub(yytext, 3))
                            - ((Char.ord #"0") * 111)
                  in
                    if x > 255
                    then
                      (
                        lexError
                        (
                          "illegal ascii escape",
                          left(yypos, arg),
                          right(yypos, size yytext, arg)
                        )
                      )
                    else addChar(stringBuf, Char.chr x);
                    continue()
                  end);
<S>\\u[0-9a-fA-F]{4} =>
                 (let
                    fun parseHexInt string =
                        StringCvt.scanString (Int.scan StringCvt.HEX) string
                    val x =
                        valOf(parseHexInt (String.extract (yytext, 2, NONE)))
                  in
                    if Char.maxOrd < x
                    then
                      (
                        lexError
                        (
                          "illegal ascii escape",
                          left(yypos, arg),
                          right(yypos, size yytext, arg)
                        )
                      )
                    else addChar(stringBuf, Char.chr x);
                    continue()
                  end);
<S>\\  => (
            lexError
            ("illegal string escape", left(yypos, arg), right(yypos, 1, arg));
            continue()
          );
<S>[\000-\031] => (
                    lexError
                    (
                      "illegal non-printing character in string",
                      left(yypos, arg),
                      right(yypos, 1, arg)
                    );
                    continue()
                  );
<S>({idchars}|{sym}|\[|\]|\(|\)|{quote}|[,.;^{}])+|.  =>
                (addString(stringBuf, yytext); continue());
<F>{eol} => (newLine(yypos, yytext, arg); continue());
<F>{ws} => (continue());
<F>\\  => (YYBEGIN S; continue());
<F>.  => (
           lexError
           ("unclosed string", left(yypos, arg), right(yypos, 1, arg));
           stringType := NOSTR;
           YYBEGIN INITIAL;
           T.STRING
           (makeString stringBuf, !stringStart, right(yypos, 1, arg))
         );
. => (T.SPECIAL(yytext, left(yypos, arg), right(yypos, 1, arg)));
