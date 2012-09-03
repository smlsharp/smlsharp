(*
 * lexical structures of IML.
 *   the part of constant specifications is based on 
 *   that of the SML New Jersye implementation
 * @copyright (c) 2006, Tohoku University.
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author YAMATODANI Kiyoshi
 * @version $Id: iml.lex,v 1.24 2006/03/03 02:40:16 bochao Exp $
 *)

structure Tokens = Tokens

type svalue = Tokens.svalue
type ('a,'b) token = ('a,'b) Tokens.token
type lexresult= (svalue,Loc.pos) token
type pos = Loc.pos
exception Error

type arg =
{
  fileName : string,
  errorPrinter : (string * pos * pos) -> unit,
  stringBuf : string list ref,
  stringStart : pos ref,
  stringType : bool ref,
  comLevel : int ref,
  anyErrors : bool ref,
  lineMap : {lineCount : int, beginPos : int} list ref,
  lineCount : int ref,
  charCount : int ref,
  initialCharCount : int
}

(*
val error = Error.printError
 *)

(* NOTE: the length of eol can be 2 on DOS/Windows. *)
fun newLine (pos, eolString, arg : arg) =
    (
(*
      #ln arg := (!(#ln arg)) + 1;
      #lineMap arg :=
      {lineCount = !(#ln arg), beginPos = pos + size eolString}
      :: (!(#lineMap arg))
*)
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
            col = absolutePos - beginPos + offset + 1 (* first column is 1. *)
          }
      | NONE =>
        raise
          Control.Bug
            ("lineCount of " ^ Int.toString absolutePos ^ " is not found.")
    end
fun left (pos, arg) = currentPos(pos, 0, arg)
fun right (pos, size, arg) = currentPos(pos, size - 1, arg)
fun addString (buffer, string) = buffer := string :: (!buffer)

fun addChar (buffer, string) = buffer := String.str string :: (!buffer)
fun makeString (buffer) = concat (rev (!buffer)) before buffer := nil

val eof =
    (*
    fn arg => Tokens.EOF (left(0, arg),right(0, 0, arg))
     *)
    fn arg => Tokens.EOF (Loc.nopos, Loc.nopos)
local
  fun cvti radix (s, i) =
      #1
      (valOf
       (Int32.scan radix Substring.getc (Substring.triml i (Substring.all s))))
  fun cvtw radix (s, i) =
      #1
      (valOf
       (Word32.scan radix Substring.getc (Substring.triml i (Substring.all s))))
in
val atoi = cvti StringCvt.DEC
val atow = cvtw StringCvt.DEC
val xtoi = cvti StringCvt.HEX
val xtow = cvtw StringCvt.HEX
end (* local *)
%%
%s A S F;
%header (functor CoreMLLexFun(structure Tokens: CoreML_TOKENS));
%arg (arg as 
      {
        fileName,
        errorPrinter,
        stringBuf,
        stringStart,
        stringType,
        comLevel,
        anyErrors,
        lineMap,
        lineCount,
        charCount,
        initialCharCount
      } :
      {
        fileName : string, 
        errorPrinter : (string * Loc.pos * Loc.pos) -> unit,
        stringBuf : string list ref,
        stringStart : Loc.pos ref,
        stringType : bool ref,
        comLevel : int ref,
        anyErrors : bool ref,
        lineMap : {lineCount : int, beginPos : int} list ref,
        lineCount : int ref,
        charCount : int ref,
        initialCharCount : int
      });

quote="'";
underscore="\_";
alpha=[A-Za-z];
digit=[0-9];
idchars={alpha}|{digit}|{quote}|{underscore};
id=({alpha}|{quote}){idchars}*;
ws=("\012"|[\t\ ])*;
eol=("\013\010"|"\010"|"\013");
sym=[!%&$+/:<=>?@~|#*]|\-|\^;
symbol={sym}|\\;
num=[0-9]+;
frac="."{num};
exp=[eE](~?){num};
real=(~?)(({num}{frac}?{exp})|({num}{frac}{exp}?));
hexnum=[0-9a-fA-F]+;
%%
<INITIAL>{ws} => (continue());
<INITIAL>{eol} => (newLine(yypos, yytext, arg); continue ());
<INITIAL>"abstype" => (Tokens.ABSTYPE (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"andalso" => (Tokens.ANDALSO (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"and" => (Tokens.AND (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"as" => (Tokens.AS (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"case" => (Tokens.CASE (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"_cast" => (Tokens.CAST (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"datatype" => (Tokens.DATATYPE (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>"do" => (Tokens.DO (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"else" => (Tokens.ELSE (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"end" => (Tokens.END (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"eqtype" => (Tokens.EQTYPE (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"exception" =>
          (Tokens.EXCEPTION (left(yypos,arg),right(yypos,9,arg)));
<INITIAL>"_external" =>
          (Tokens.EXTERNAL (left(yypos,arg),right(yypos,9,arg)));
<INITIAL>"fn" => (Tokens.FN (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"fun" => (Tokens.FUN (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"functor" => (Tokens.FUNCTOR (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"handle" => (Tokens.HANDLE (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"if" => (Tokens.IF (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"_import" => (Tokens.IMPORT (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"in" => (Tokens.IN (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"include" => (Tokens.INCLUDE (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"infix" => (Tokens.INFIX (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"infixr" => (Tokens.INFIXR (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"nonfix" => (Tokens.NONFIX (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"let" => (Tokens.LET (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"local" => (Tokens.LOCAL (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"of" => (Tokens.OF (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"op" => (Tokens.OP (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"open" => (Tokens.OPEN(left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"orelse" => (Tokens.ORELSE (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"raise" => (Tokens.RAISE (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"rec" => (Tokens.REC (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"sharing" => (Tokens.SHARING (left(yypos,arg),right(yypos,7,arg)));
<INITIAL>"sig"=> (Tokens.SIG (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"signature" =>
          (Tokens.SIGNATURE (left(yypos,arg),right(yypos,9,arg)));
<INITIAL>"struct" => (Tokens.STRUCT (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"structure" =>
         (Tokens.STRUCTURE (left(yypos,arg),right(yypos,9,arg)));
<INITIAL>"then" => (Tokens.THEN (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"type" => (Tokens.TYPE (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"use" => (Tokens.USE (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"useObj" => (Tokens.USEOBJ (left(yypos,arg),right(yypos,6,arg)));
<INITIAL>"val" => (Tokens.VAL (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>"where" => (Tokens.WHERE (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"while" => (Tokens.WHILE (left(yypos,arg),right(yypos,5,arg)));
<INITIAL>"with" => (Tokens.WITH (left(yypos,arg),right(yypos,4,arg)));
<INITIAL>"withtype" => (Tokens.WITHTYPE (left(yypos,arg),right(yypos,8,arg)));
<INITIAL>":>" => (Tokens.OPAQUE (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"*" => (Tokens.ASTERISK(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"#" => (Tokens.HASH(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"(" => (Tokens.LPAREN(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>")" => (Tokens.RPAREN(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"," => (Tokens.COMMA(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"->" => (Tokens.ARROW (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"." => (Tokens.PERIOD (left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"..." => (Tokens.PERIODS (left(yypos,arg),right(yypos,3,arg)));
<INITIAL>":" => (Tokens.COLON(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>";" => (Tokens.SEMICOLON(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"=" => (Tokens.EQ(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"=>" => (Tokens.DARROW (left(yypos,arg),right(yypos,2,arg)));
<INITIAL>"[" => (Tokens.LBRACKET(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"]" => (Tokens.RBRACKET(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"_" => (Tokens.UNDERBAR(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"{" => (Tokens.LBRACE(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"|" => (Tokens.BAR(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>"}" => (Tokens.RBRACE(left(yypos,arg),right(yypos,1,arg)));
<INITIAL>{id} => (if String.isPrefix "''" yytext
                  then
                    Tokens.EQTYVAR
                      (
                        String.substring(yytext, 2, String.size yytext - 2),
                        left(yypos, arg),
                        right(yypos, String.size yytext, arg)
                      )
                  else
                    if String.isPrefix "'" yytext
                    then
                      Tokens.TYVAR
                      (
                        String.substring(yytext, 1, String.size yytext - 1),
                        left(yypos, arg),
                        right(yypos, String.size yytext, arg)
                      )
                    else
                      Tokens.ID
                      (
                        yytext,
                        left(yypos, arg),
                        right(yypos, String.size yytext, arg)
                      ));
<INITIAL>{num} => (Tokens.INT
                   (
                     atoi(yytext, 0),
                     left(yypos, arg),
                     right(yypos, String.size yytext, arg)
                   ));
<INITIAL>~{num} => (Tokens.INT
                    (
                      atoi(yytext, 0),
                      left(yypos, arg),
                      right(yypos, String.size yytext, arg)
                    ));
<INITIAL>{symbol}+ => (Tokens.ID
                       (
                         yytext,
                         left(yypos, arg),
                         right(yypos, String.size yytext, arg)
                       ));
<INITIAL>{real} => (Tokens.REAL
                    (
                      yytext,
                      left(yypos, arg),
                      right(yypos, String.size yytext, arg)
                    ));
<INITIAL>"0w"{num} => (Tokens.WORD
                       (
                         atow(yytext, 2),
                         left(yypos, arg),
                         right(yypos, String.size yytext, arg)
                       ));
<INITIAL>"0x"{hexnum} => (Tokens.INT
                          (
                            xtoi(yytext, 2),
                            left(yypos, arg),
                            right(yypos, String.size yytext, arg)
                          ));
<INITIAL>"~0x"{hexnum} => (Tokens.INT
                           (
                             ~(xtoi(yytext, 3)),
                             left(yypos, arg),
                             right(yypos, String.size yytext, arg)
                           ));
<INITIAL>"0wx"{hexnum}  => (Tokens.WORD
                            (
                              xtow(yytext, 3),
                              left(yypos, arg),
                              right(yypos, String.size yytext, arg)
                            ));
<INITIAL>\" => (
                 stringBuf := nil; 
                 stringStart := left(yypos, arg);
                 stringType := true; 
                 YYBEGIN S;
                 continue()
               );
<INITIAL>\#\" => (
                    stringBuf := nil; 
                    stringStart := left(yypos, arg);
                    stringType := false; 
                    YYBEGIN S;
                    continue()
                  );
<INITIAL>"(*" => (YYBEGIN A; comLevel := 1; continue());
<INITIAL>"*)" => (
                   errorPrinter
                   (
                     "unmatched close comment",
                     left(yypos, arg),
                     right(yypos, 2, arg)
                   );
                   anyErrors := true;
                   continue()
                 );
<INITIAL>\h => (
                 errorPrinter
                 (
                   "non-Ascii character",
                   left(yypos, arg),
                   right(yypos, 1, arg)
                 );
                 anyErrors := true;
                 continue()
               );
<INITIAL>. => (
                errorPrinter
                ("illegal token", left(yypos, arg), right(yypos, 1, arg));
                anyErrors := true;
                continue()
              );
<A>"(*"  => (comLevel := !comLevel + 1; continue());
<A>{eol} => (newLine(yypos, yytext, arg); continue ());
<A>"*)" => (
             comLevel := !comLevel - 1;
             if !comLevel=0 then YYBEGIN INITIAL else ();
             continue()
           );
<A>. => (continue());
<S>\" => (
           let
             val s = makeString stringBuf
             val s = if size s <> 1 andalso not(!stringType)
                     then
                       (
                         errorPrinter
                         (
                           "character constant not length 1",
                           left(yypos, arg),
                           right(yypos, 1, arg) (* pos of double quote *)
                         );
                         anyErrors := true;
                         if 0 = size s then "?" else s
                       )
                     else s
             val t = (s, !stringStart, right(yypos, 1, arg))
           in
             YYBEGIN INITIAL;
             if !stringType
             then Tokens.STRING t else Tokens.CHAR t
           end
         );
<S>{eol} => (
              errorPrinter
              ("unclosed string", left(yypos, arg), right(yypos, 1, arg));
              anyErrors := true;
              newLine(yypos, yytext, arg); 
              YYBEGIN INITIAL;
              Tokens.STRING
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
              errorPrinter
              (
                "illegal control escape; must be one of \
                \@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_",
                left(yypos, arg),
                right(yypos, size yytext, arg)
              );
              anyErrors := true;
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
                        errorPrinter
                        (
                          "illegal ascii escape",
                          left(yypos, arg),
                          right(yypos, size yytext, arg)
                        );
                        anyErrors := true
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
                        errorPrinter
                        (
                          "illegal ascii escape",
                          left(yypos, arg),
                          right(yypos, size yytext, arg)
                        );
                        anyErrors := true
                      )
                    else addChar(stringBuf, Char.chr x);
                    continue()
                  end);
<S>\\  => (
            errorPrinter
            ("illegal string escape", left(yypos, arg), right(yypos, 1, arg));
            anyErrors := true;
            continue()
          );
<S>[\000-\031] => (
                    errorPrinter
                    (
                      "illegal non-printing character in string",
                      left(yypos, arg),
                      right(yypos, 1, arg)
                    );
                    anyErrors := true;
                    continue()
                  );
<S>({idchars}|{sym}|\[|\]|\(|\)|{quote}|[,.;^{}])+|.  =>
                (addString(stringBuf, yytext); continue());
<F>{eol} => (newLine(yypos, yytext, arg); continue());
<F>{ws} => (continue());
<F>\\  => (YYBEGIN S; continue());
<F>.  => (
           errorPrinter
           ("unclosed string", left(yypos, arg), right(yypos, 1, arg));
           anyErrors := true;
           YYBEGIN INITIAL;
           Tokens.STRING
           (makeString stringBuf, !stringStart, right(yypos, 1, arg))
         );
. => (Tokens.SPECIAL(yytext, left(yypos, arg), right(yypos, 1, arg)));
