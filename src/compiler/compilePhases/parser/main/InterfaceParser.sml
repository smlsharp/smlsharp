(**
 * parser for interface file.
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure InterfaceParser =
struct
  structure T = Token
  structure Parser = InterfaceGrm.Parser
  structure Tokens = InterfaceGrm.Tokens

  fun toParserToken lexer () =
      case lexer () of
        (token, (pos1, pos2)) =>
        case token of
          T.EOF => Tokens.EOF (pos1, pos2)
        | T.COMMENT => toParserToken lexer ()
        | T.ABSTYPE => Tokens.ABSTYPE (pos1, pos2)
        | T.AND => Tokens.AND (pos1, pos2)
        | T.ANDALSO => Tokens.ANDALSO (pos1, pos2)
        | T.AS => Tokens.AS (pos1, pos2)
        | T.CASE => Tokens.CASE (pos1, pos2)
        | T.DATATYPE => Tokens.DATATYPE (pos1, pos2)
        | T.DO => Tokens.DO (pos1, pos2)
        | T.ELSE => Tokens.ELSE (pos1, pos2)
        | T.END => Tokens.END (pos1, pos2)
        | T.EXCEPTION => Tokens.EXCEPTION (pos1, pos2)
        | T.FN => Tokens.FN (pos1, pos2)
        | T.FUN => Tokens.FUN (pos1, pos2)
        | T.HANDLE => Tokens.HANDLE (pos1, pos2)
        | T.IF => Tokens.IF (pos1, pos2)
        | T.IN => Tokens.IN (pos1, pos2)
        | T.INFIX => Tokens.INFIX (pos1, pos2)
        | T.INFIXR => Tokens.INFIXR (pos1, pos2)
        | T.LET => Tokens.LET (pos1, pos2)
        | T.LOCAL => Tokens.LOCAL (pos1, pos2)
        | T.NONFIX => Tokens.NONFIX (pos1, pos2)
        | T.OF => Tokens.OF (pos1, pos2)
        | T.OP => Tokens.OP (pos1, pos2)
        | T.OPEN => Tokens.OPEN (pos1, pos2)
        | T.ORELSE => Tokens.ORELSE (pos1, pos2)
        | T.RAISE => Tokens.RAISE (pos1, pos2)
        | T.REC => Tokens.REC (pos1, pos2)
        | T.THEN => Tokens.THEN (pos1, pos2)
        | T.TYPE => Tokens.TYPE (pos1, pos2)
        | T.VAL => Tokens.VAL (pos1, pos2)
        | T.WITH => Tokens.WITH (pos1, pos2)
        | T.WITHTYPE => Tokens.WITHTYPE (pos1, pos2)
        | T.WHILE => Tokens.WHILE (pos1, pos2)
        | T.LPAREN => Tokens.LPAREN (pos1, pos2)
        | T.RPAREN => Tokens.RPAREN (pos1, pos2)
        | T.LBRACKET => Tokens.LBRACKET (pos1, pos2)
        | T.RBRACKET => Tokens.RBRACKET (pos1, pos2)
        | T.LBRACE => Tokens.LBRACE (pos1, pos2)
        | T.RBRACE => Tokens.RBRACE (pos1, pos2)
        | T.COMMA => Tokens.COMMA (pos1, pos2)
        | T.COLON => Tokens.COLON (pos1, pos2)
        | T.SEMICOLON => Tokens.SEMICOLON (pos1, pos2)
        | T.PERIODS => Tokens.PERIODS (pos1, pos2)
        | T.UNDERBAR => Tokens.UNDERBAR (pos1, pos2)
        | T.UNDERBAR_ => Tokens.UNDERBAR_ (pos1, pos2)
        | T.BAR => Tokens.BAR (pos1, pos2)
        | T.EQ => Tokens.EQ (pos1, pos2)
        | T.DARROW => Tokens.DARROW (pos1, pos2)
        | T.ARROW => Tokens.ARROW (pos1, pos2)
        | T.HASH => Tokens.HASH (pos1, pos2)
        | T.EQTYPE => Tokens.EQTYPE (pos1, pos2)
        | T.FUNCTOR => Tokens.FUNCTOR (pos1, pos2)
        | T.INCLUDE => Tokens.INCLUDE (pos1, pos2)
        | T.SHARING => Tokens.SHARING (pos1, pos2)
        | T.SIG => Tokens.SIG (pos1, pos2)
        | T.SIGNATURE => Tokens.SIGNATURE (pos1, pos2)
        | T.STRUCT => Tokens.STRUCT (pos1, pos2)
        | T.STRUCTURE => Tokens.STRUCTURE (pos1, pos2)
        | T.WHERE => Tokens.WHERE (pos1, pos2)
        | T.OPAQUE => Tokens.OPAQUE (pos1, pos2)
        | T.ASTERISK => Tokens.ASTERISK (pos1, pos2)
        | T.PERIOD => Tokens.PERIOD (pos1, pos2)
        | T.ALNUMID (s as "builtin") => Tokens.BUILTIN (s, pos1, pos2)
        | T.ALNUMID (s as "require") => Tokens.REQUIRE (s, pos1, pos2)
        | T.ALNUMID (s as "use") => Tokens.USE (s, pos1, pos2)
        | T.ALNUMID s => Tokens.ALNUMID (s, pos1, pos2)
        | T.EQTYVAR s => Tokens.EQTYVAR (s, pos1, pos2)
        | T.TYVAR s => Tokens.TYVAR (s, pos1, pos2)
        | T.SYMBOLID s => Tokens.SYMBOLID (s, pos1, pos2)
        | T.CHAR s => Tokens.CHAR (s, pos1, pos2)
        | T.HASH_STRING s => Tokens.HASH_STRING (s, pos1, pos2)
        | T.INT s => Tokens.INT (s, pos1, pos2)
        | T.INTX s => Tokens.INTX (s, pos1, pos2)
        | T.INTLAB s => Tokens.INTLAB (s, pos1, pos2)
        | T.REAL s => Tokens.REAL (s, pos1, pos2)
        | T.STRING s => Tokens.STRING (s, pos1, pos2)
        | T.WORD s => Tokens.WORD (s, pos1, pos2)
        | T.WORDX s => Tokens.WORDX (s, pos1, pos2)

  type source = {read : int -> string, source : Loc.source, allowUtf8 : bool}
  type input =
      {
        streamRef : Parser.stream ref,
        tokensRef : (Token.token * (Loc.at * Loc.at)) snoc ref,
        errors : UserError.errorQueue,
        errorFn : string * Loc.pos * Loc.pos -> unit
      }

  fun parseError errors (msg, lpos, rpos) =
      UserError.enqueueError
        errors
        (Loc.LOC (lpos, rpos), ParserError.ParseError msg)

  fun setup ({read, source, allowUtf8}:source) =
      let
        val errors = UserError.createQueue ()
        val errorFn = parseError errors
        val lexarg =
            ImlLex.UserDeclarations.initArg
              {source = source,
               errorFn = errorFn,
               initialLineno = 1,
               allowUtf8 = allowUtf8}
        val lexer = ImlLex.makeLexer read lexarg
        val tokensRef = ref NIL
        val lexer = ImlLex.UserDeclarations.setupLexer tokensRef lexer
        val stream = Parser.makeStream {lexer = toParserToken lexer}
      in
        {streamRef = ref stream,
         tokensRef = tokensRef,
         errors = errors,
         errorFn = parseError errors} : input
      end

  fun parse ({streamRef, tokensRef, errors, errorFn} : input) =
      let
        (* prevent reading this source after parse error occurred. *)
        val _ = if UserError.isEmptyErrorQueue errors
                then () else raise Bug.Bug "parse: aborted stream"

        val (result, newStream) =
            Parser.parse {lookahead=15, stream = !streamRef, error=errorFn, arg=()}
            handle Parser.ParseError =>
                   raise UserError.UserErrors (UserError.getErrors errors)

        val _ = streamRef := newStream
        val tokens = !tokensRef before tokensRef := NIL
      in
        if UserError.isEmptyErrorQueue errors
        then ()
        else raise UserError.UserErrors (UserError.getErrors errors);
        (tokens, result)
      end
end
