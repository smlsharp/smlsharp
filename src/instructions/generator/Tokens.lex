structure Tokens = Tokens;

(*****************************************************************************)
type pos = {fileName : string, line : int, col : int}
type svalue = Tokens.svalue;
type ('a,'b) token = ('a,'b) Tokens.token;
type lexresult = (svalue, pos) token;
type arg = {
    fileName : string,
    printError : (string * pos * pos) -> unit
};

(*****************************************************************************)
(* Because this parser is invoked only once, it is safe to keep state by
 * global variables. *)
val lineCount = ref 1;
val comLevel = ref 0;

fun currentPos (column, length, arg:arg) =
    {
      fileName = #fileName arg,
      line = !lineCount,
      col = column + length
    };
fun left (column, arg) = currentPos(column,0, arg);
fun right (column, string, arg) = currentPos(column, String.size string, arg);

val eof =
    fn arg => (lineCount := 1; Tokens.EOF (left(0, arg), right(0, "", arg)));

(*****************************************************************************)
%%
%reject
%s A;
%header (functor InstructionLexFun (structure Tokens: Instruction_TOKENS));
%arg (args as {fileName, printError}
      : {
          fileName : string,
          printError :
          (string *
           {fileName : string, line : int, col : int} *
           {fileName : string, line : int, col : int}) -> unit
        });

ws = ("\012"|[\ \t]);
eol = ("\013\010"|"\010"|"\013");

%%
<INITIAL>{ws}+ => (continue());
<INITIAL>{eol} => (lineCount := (!lineCount) + 1; continue ());
<INITIAL>"=" => (Tokens.EQ(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>":" => (Tokens.COLON(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>";" =>
    (Tokens.SEMICOLON(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>"," => (Tokens.COMMA(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>"{" => (Tokens.LBRACE(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>"}" => (Tokens.RBRACE(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>"\|" => (Tokens.VBAR(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>structure =>
    (Tokens.STRUCTURE(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>struct =>
    (Tokens.STRUCT(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>end =>
    (Tokens.END(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>datatype =>
    (Tokens.DATATYPE(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>of => (Tokens.OF(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>UInt8 =>
    (Tokens.UINT8(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>SInt8 =>
    (Tokens.SINT8(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>UInt16 =>
    (Tokens.UINT16(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>SInt16 =>
    (Tokens.SINT16(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>UInt24 =>
    (Tokens.UINT24(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>SInt24 =>
    (Tokens.SINT24(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>UInt32 =>
    (Tokens.UINT32(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>SInt32 =>
    (Tokens.SINT32(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>Real64 =>
    (Tokens.REAL64(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>list => (Tokens.LIST(left(yypos, args), right(yypos, yytext, args)));
<INITIAL>[a-zA-Z0-9_]+ =>
    (Tokens.STRING(yytext, left(yypos, args), right(yypos, yytext, args)));
<INITIAL>"(*" => (YYBEGIN A; comLevel := 1; continue());
<INITIAL>"*)" => 
    (
      (#printError args)
          (
            "unmatched close comment",
            left(yypos, args),
            right(yypos, yytext, args)
          );
      REJECT()
    );
<INITIAL>. =>
    (
      (#printError args)
      (
        "invalid token(" ^ yytext ^ ")",
        left(yypos, args),
        right(yypos, yytext, args)
      );
      REJECT()
    );
<A>"(*" => (comLevel := !comLevel + 1; continue());
<A>{eol} => (lineCount := (!lineCount) + 1; continue ());
<A>"*)" => (
             comLevel := !comLevel - 1;
             if !comLevel = 0 then YYBEGIN INITIAL else ();
             continue()
           );
<A>. => (continue());
