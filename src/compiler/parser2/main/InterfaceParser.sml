(**
 * parser for interface file.
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure InterfaceParser =
struct
  structure T = MLLex.UserDeclarations.T
  structure Parser = InterfaceLrVals.Parser
  type token = Parser.token

  fun convert t =
      case t of
        T.ASSOCINDICATOR x => InterfaceLrVals.Tokens.ASSOCINDICATOR x
      | T.FORMATINDICATOR x => InterfaceLrVals.Tokens.FORMATINDICATOR x
      | T.STARTOFINDENT x => InterfaceLrVals.Tokens.STARTOFINDENT x
      | T.NEWLINE x => InterfaceLrVals.Tokens.NEWLINE x
      | T.LOCALFORMATTAG x => InterfaceLrVals.Tokens.LOCALFORMATTAG x
      | T.FORMATTAG x => InterfaceLrVals.Tokens.FORMATTAG x
      | T.FORMATPARAMSTAG x => InterfaceLrVals.Tokens.FORMATPARAMSTAG x
      | T.FORMATTERTAG x => InterfaceLrVals.Tokens.FORMATTERTAG x
      | T.FORMATCOMMENTEND x => InterfaceLrVals.Tokens.FORMATCOMMENTEND x
      | T.FORMATCOMMENTSTART x => InterfaceLrVals.Tokens.FORMATCOMMENTSTART x
      | T.HEADERTAG x => InterfaceLrVals.Tokens.HEADERTAG x
      | T.DESTINATIONTAG x => InterfaceLrVals.Tokens.DESTINATIONTAG x
      | T.PREFIXTAG x => InterfaceLrVals.Tokens.PREFIXTAG x
      | T.DITTOTAG x => InterfaceLrVals.Tokens.DITTOTAG x
      | T.ROLLBACK x => InterfaceLrVals.Tokens.ROLLBACK x
      | T.COMMIT x => InterfaceLrVals.Tokens.COMMIT x
      | T.BEGIN x => InterfaceLrVals.Tokens.BEGIN x
      | T.DEFAULT x => InterfaceLrVals.Tokens.DEFAULT x
      | T.SET x => InterfaceLrVals.Tokens.SET x
      | T.UPDATE x => InterfaceLrVals.Tokens.UPDATE x
      | T.BY x => InterfaceLrVals.Tokens.BY x
      | T.ORDER x => InterfaceLrVals.Tokens.ORDER x
      | T.DELETE x => InterfaceLrVals.Tokens.DELETE x
      | T.VALUES x => InterfaceLrVals.Tokens.VALUES x
      | T.INTO x => InterfaceLrVals.Tokens.INTO x
      | T.INSERT x => InterfaceLrVals.Tokens.INSERT x
      | T.FROM x => InterfaceLrVals.Tokens.FROM x
      | T.SELECT x => InterfaceLrVals.Tokens.SELECT x
      | T.DESC x => InterfaceLrVals.Tokens.DESC x
      | T.ASC x => InterfaceLrVals.Tokens.ASC x
      | T.SQL x => InterfaceLrVals.Tokens.SQL x
      | T.SQLEXEC x => InterfaceLrVals.Tokens.SQLEXEC x
      | T.SQLEVAL x => InterfaceLrVals.Tokens.SQLEVAL x
      | T.SQLSERVER x => InterfaceLrVals.Tokens.SQLSERVER x
      | T.WORD x => InterfaceLrVals.Tokens.WORD x
      | T.WITHTYPE x => InterfaceLrVals.Tokens.WITHTYPE x
      | T.WITH x => InterfaceLrVals.Tokens.WITH x
      | T.WHERE x => InterfaceLrVals.Tokens.WHERE x
      | T.WHILE x => InterfaceLrVals.Tokens.WHILE x
      | T.VAL x => InterfaceLrVals.Tokens.VAL x
      | T.USE' x => InterfaceLrVals.Tokens.USE' x
      | T.USE x => InterfaceLrVals.Tokens.USE x
      | T.UNDERBAR x => InterfaceLrVals.Tokens.UNDERBAR x
      | T.TYVAR x => InterfaceLrVals.Tokens.TYVAR x
      | T.TYPE x => InterfaceLrVals.Tokens.TYPE x
      | T.THEN x => InterfaceLrVals.Tokens.THEN x
      | T.STRUCTURE x => InterfaceLrVals.Tokens.STRUCTURE x
      | T.STRUCT x => InterfaceLrVals.Tokens.STRUCT x
      | T.STRING x => InterfaceLrVals.Tokens.STRING x
      | T.SPECIAL x => InterfaceLrVals.Tokens.SPECIAL x
      | T.SIZEOF x => InterfaceLrVals.Tokens.SIZEOF x
      | T.SIGNATURE x => InterfaceLrVals.Tokens.SIGNATURE x
      | T.SIG x => InterfaceLrVals.Tokens.SIG x
      | T.SHARING x => InterfaceLrVals.Tokens.SHARING x
      | T.SEMICOLON x => InterfaceLrVals.Tokens.SEMICOLON x
      | T.RPAREN x => InterfaceLrVals.Tokens.RPAREN x
      | T.REAL x => InterfaceLrVals.Tokens.REAL x
      | T.RBRACKET x => InterfaceLrVals.Tokens.RBRACKET x
      | T.RBRACE x => InterfaceLrVals.Tokens.RBRACE x
      | T.REQUIRE x => InterfaceLrVals.Tokens.REQUIRE x
      | T.REC x => InterfaceLrVals.Tokens.REC x
      | T.POLYREC x => InterfaceLrVals.Tokens.POLYREC x
      | T.RAISE x => InterfaceLrVals.Tokens.RAISE x
      | T.PERIODS x => InterfaceLrVals.Tokens.PERIODS x
      | T.PERIOD x => InterfaceLrVals.Tokens.PERIOD x
      | T.NULL x => InterfaceLrVals.Tokens.NULL x
      | T.ORELSE x => InterfaceLrVals.Tokens.ORELSE x
      | T.OPEN x => InterfaceLrVals.Tokens.OPEN x
      | T.OPAQUE x => InterfaceLrVals.Tokens.OPAQUE x
      | T.OP x => InterfaceLrVals.Tokens.OP x
      | T.OF x => InterfaceLrVals.Tokens.OF x
      | T.NONFIX x => InterfaceLrVals.Tokens.NONFIX x
      | T.LPAREN x => InterfaceLrVals.Tokens.LPAREN x
      | T.LOCAL x => InterfaceLrVals.Tokens.LOCAL x
      | T.LET x => InterfaceLrVals.Tokens.LET x
      | T.LBRACKET x => InterfaceLrVals.Tokens.LBRACKET x
      | T.LBRACE x => InterfaceLrVals.Tokens.LBRACE x
      | T.INTERFACE x => InterfaceLrVals.Tokens.INTERFACE x
      | T.JOIN x => InterfaceLrVals.Tokens.JOIN x
      | T.INTLAB x => InterfaceLrVals.Tokens.INTLAB x
      | T.INT x => InterfaceLrVals.Tokens.INT x
      | T.INFIXR x => InterfaceLrVals.Tokens.INFIXR x
      | T.INFIX x => InterfaceLrVals.Tokens.INFIX x
      | T.INCLUDE x => InterfaceLrVals.Tokens.INCLUDE x
      | T.IMPORT x => InterfaceLrVals.Tokens.IMPORT x
      | T.IN x => InterfaceLrVals.Tokens.IN x
      | T.IF x => InterfaceLrVals.Tokens.IF x
      | T.ID x => InterfaceLrVals.Tokens.ID x
      | T.HASH x => InterfaceLrVals.Tokens.HASH x
      | T.HANDLE x => InterfaceLrVals.Tokens.HANDLE x
      | T.FUNCTOR x => InterfaceLrVals.Tokens.FUNCTOR x
      | T.FUN x => InterfaceLrVals.Tokens.FUN x
      | T.FN x => InterfaceLrVals.Tokens.FN x
      | T.FFIAPPLY x => InterfaceLrVals.Tokens.FFIAPPLY x
      | T.EXCEPTION x => InterfaceLrVals.Tokens.EXCEPTION x
      | T.EQTYVAR x => InterfaceLrVals.Tokens.EQTYVAR x
      | T.EQTYPE x => InterfaceLrVals.Tokens.EQTYPE x
      | T.EQ x => InterfaceLrVals.Tokens.EQ x
      | T.END x => InterfaceLrVals.Tokens.END x
      | T.ELSE x => InterfaceLrVals.Tokens.ELSE x
      | T.DO x => InterfaceLrVals.Tokens.DO x
      | T.DATATYPE x => InterfaceLrVals.Tokens.DATATYPE x
      | T.DARROW x => InterfaceLrVals.Tokens.DARROW x
      | T.COMMA x => InterfaceLrVals.Tokens.COMMA x
      | T.COLON x => InterfaceLrVals.Tokens.COLON x
      | T.CHAR x => InterfaceLrVals.Tokens.CHAR x
      | T.CASE x => InterfaceLrVals.Tokens.CASE x
      | T.BUILTIN x => InterfaceLrVals.Tokens.BUILTIN x
      | T.BAR x => InterfaceLrVals.Tokens.BAR x
      | T.ATTRIBUTE x => InterfaceLrVals.Tokens.ATTRIBUTE x
      | T.AT x => InterfaceLrVals.Tokens.AT x
      | T.ASTERISK x => InterfaceLrVals.Tokens.ASTERISK x
      | T.AS x => InterfaceLrVals.Tokens.AS x
      | T.ARROW x => InterfaceLrVals.Tokens.ARROW x
      | T.ANDALSO x => InterfaceLrVals.Tokens.ANDALSO x
      | T.AND x => InterfaceLrVals.Tokens.AND x
      | T.ABSTYPE x => InterfaceLrVals.Tokens.ABSTYPE x
      | T.EOF x => InterfaceLrVals.Tokens.EOF x

  type source = {read : int -> string, sourceName : string}

  type input =
      {
        streamRef : Parser.stream ref,
        errors : UserError.errorQueue,
        errorFn : string * Loc.pos * Loc.pos -> unit
      }

  fun parseError errors (msg, lpos, rpos) =
      UserError.enqueueError errors ((lpos, rpos), ParserError.ParseError msg)

  fun setup ({read, sourceName}:source) =
      let
        val errors = UserError.createQueue ()
        val errorFn = parseError errors
        val lexarg =
            MLLex.UserDeclarations.initArg
              {sourceName = sourceName,
               isPrelude = false,
               enableMeta = false,
               lexErrorFn = errorFn,
               initialLineno = 1,
               allow8bitId = !Control.allow8bitId}
        val lexer = convert o MLLex.makeLexer read lexarg
        val stream = Parser.makeStream {lexer=lexer}
      in
        {streamRef = ref stream, errors = errors, errorFn = errorFn} : input
      end

  fun parse ({streamRef, errors, errorFn}:input) =
      let
        (* prevent reading this source after parse error occurred. *)
        val _ = if UserError.isEmptyErrorQueue errors
                then () else raise Bug.Bug "parse: aborted stream"

        val (result, newStream) =
            Parser.parse {lookahead=15, stream = !streamRef, error=errorFn, arg=()}
            handle Parser.ParseError =>
                   raise UserError.UserErrors (UserError.getErrors errors)

        val _ = streamRef := newStream
      in
        if UserError.isEmptyErrorQueue errors
        then ()
        else raise UserError.UserErrors (UserError.getErrors errors);
        result
      end
end
