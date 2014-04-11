(**
 * ML parser.
 *
 * @author Atsushi ohori 
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *)
structure Parser =
struct
  structure T = MLLex.UserDeclarations.T
  structure Parser = MLLrVals.Parser
  type token = Parser.token

  fun convert t =
      case t of
        T.ASSOCINDICATOR x => MLLrVals.Tokens.ASSOCINDICATOR x
      | T.FORMATINDICATOR x => MLLrVals.Tokens.FORMATINDICATOR x
      | T.STARTOFINDENT x => MLLrVals.Tokens.STARTOFINDENT x
      | T.NEWLINE x => MLLrVals.Tokens.NEWLINE x
      | T.LOCALFORMATTAG x => MLLrVals.Tokens.LOCALFORMATTAG x
      | T.FORMATTAG x => MLLrVals.Tokens.FORMATTAG x
      | T.FORMATPARAMSTAG x => MLLrVals.Tokens.FORMATPARAMSTAG x
      | T.FORMATTERTAG x => MLLrVals.Tokens.FORMATTERTAG x
      | T.FORMATCOMMENTEND x => MLLrVals.Tokens.FORMATCOMMENTEND x
      | T.FORMATCOMMENTSTART x => MLLrVals.Tokens.FORMATCOMMENTSTART x
      | T.HEADERTAG x => MLLrVals.Tokens.HEADERTAG x
      | T.DESTINATIONTAG x => MLLrVals.Tokens.DESTINATIONTAG x
      | T.PREFIXTAG x => MLLrVals.Tokens.PREFIXTAG x
      | T.DITTOTAG x => MLLrVals.Tokens.DITTOTAG x
      | T.ROLLBACK x => MLLrVals.Tokens.ROLLBACK x
      | T.COMMIT x => MLLrVals.Tokens.COMMIT x
      | T.BEGIN x => MLLrVals.Tokens.BEGIN x
      | T.DEFAULT x => MLLrVals.Tokens.DEFAULT x
      | T.SET x => MLLrVals.Tokens.SET x
      | T.UPDATE x => MLLrVals.Tokens.UPDATE x
      | T.BY x => MLLrVals.Tokens.BY x
      | T.ORDER x => MLLrVals.Tokens.ORDER x
      | T.DELETE x => MLLrVals.Tokens.DELETE x
      | T.VALUES x => MLLrVals.Tokens.VALUES x
      | T.INTO x => MLLrVals.Tokens.INTO x
      | T.INSERT x => MLLrVals.Tokens.INSERT x
      | T.FROM x => MLLrVals.Tokens.FROM x
      | T.SELECT x => MLLrVals.Tokens.SELECT x
      | T.DESC x => MLLrVals.Tokens.DESC x
      | T.ASC x => MLLrVals.Tokens.ASC x
      | T.SQL x => MLLrVals.Tokens.SQL x
      | T.SQLEXEC x => MLLrVals.Tokens.SQLEXEC x
      | T.SQLEVAL x => MLLrVals.Tokens.SQLEVAL x
      | T.SQLSERVER x => MLLrVals.Tokens.SQLSERVER x
      | T.WORD x => MLLrVals.Tokens.WORD x
      | T.WITHTYPE x => MLLrVals.Tokens.WITHTYPE x
      | T.WITH x => MLLrVals.Tokens.WITH x
      | T.WHERE x => MLLrVals.Tokens.WHERE x
      | T.WHILE x => MLLrVals.Tokens.WHILE x
      | T.VAL x => MLLrVals.Tokens.VAL x
      | T.USE' x => MLLrVals.Tokens.USE' x
      | T.USE x => MLLrVals.Tokens.USE x
      | T.UNDERBAR x => MLLrVals.Tokens.UNDERBAR x
      | T.TYVAR x => MLLrVals.Tokens.TYVAR x
      | T.TYPE x => MLLrVals.Tokens.TYPE x
      | T.THEN x => MLLrVals.Tokens.THEN x
      | T.STRUCTURE x => MLLrVals.Tokens.STRUCTURE x
      | T.STRUCT x => MLLrVals.Tokens.STRUCT x
      | T.STRING x => MLLrVals.Tokens.STRING x
      | T.SPECIAL x => MLLrVals.Tokens.SPECIAL x
      | T.SIZEOF x => MLLrVals.Tokens.SIZEOF x
      | T.SIGNATURE x => MLLrVals.Tokens.SIGNATURE x
      | T.SIG x => MLLrVals.Tokens.SIG x
      | T.SHARING x => MLLrVals.Tokens.SHARING x
      | T.SEMICOLON x => MLLrVals.Tokens.SEMICOLON x
      | T.RPAREN x => MLLrVals.Tokens.RPAREN x
      | T.REAL x => MLLrVals.Tokens.REAL x
      | T.RBRACKET x => MLLrVals.Tokens.RBRACKET x
      | T.RBRACE x => MLLrVals.Tokens.RBRACE x
      | T.REQUIRE x => MLLrVals.Tokens.REQUIRE x
      | T.REC x => MLLrVals.Tokens.REC x
      | T.POLYREC x => MLLrVals.Tokens.POLYREC x
      | T.RAISE x => MLLrVals.Tokens.RAISE x
      | T.PERIODS x => MLLrVals.Tokens.PERIODS x
      | T.PERIOD x => MLLrVals.Tokens.PERIOD x
      | T.NULL x => MLLrVals.Tokens.NULL x
      | T.ORELSE x => MLLrVals.Tokens.ORELSE x
      | T.OPEN x => MLLrVals.Tokens.OPEN x
      | T.OPAQUE x => MLLrVals.Tokens.OPAQUE x
      | T.OP x => MLLrVals.Tokens.OP x
      | T.OF x => MLLrVals.Tokens.OF x
      | T.NONFIX x => MLLrVals.Tokens.NONFIX x
      | T.LPAREN x => MLLrVals.Tokens.LPAREN x
      | T.LOCAL x => MLLrVals.Tokens.LOCAL x
      | T.LET x => MLLrVals.Tokens.LET x
      | T.LBRACKET x => MLLrVals.Tokens.LBRACKET x
      | T.LBRACE x => MLLrVals.Tokens.LBRACE x
      | T.INTERFACE x => MLLrVals.Tokens.INTERFACE x
      | T.JOIN x => MLLrVals.Tokens.JOIN x
      | T.INTLAB x => MLLrVals.Tokens.INTLAB x
      | T.INT x => MLLrVals.Tokens.INT x
      | T.INFIXR x => MLLrVals.Tokens.INFIXR x
      | T.INFIX x => MLLrVals.Tokens.INFIX x
      | T.INCLUDE x => MLLrVals.Tokens.INCLUDE x
      | T.IMPORT x => MLLrVals.Tokens.IMPORT x
      | T.IN x => MLLrVals.Tokens.IN x
      | T.IF x => MLLrVals.Tokens.IF x
      | T.ID x => MLLrVals.Tokens.ID x
      | T.HASH x => MLLrVals.Tokens.HASH x
      | T.HANDLE x => MLLrVals.Tokens.HANDLE x
      | T.FUNCTOR x => MLLrVals.Tokens.FUNCTOR x
      | T.FUN x => MLLrVals.Tokens.FUN x
      | T.FN x => MLLrVals.Tokens.FN x
      | T.FFIAPPLY x => MLLrVals.Tokens.FFIAPPLY x
      | T.EXCEPTION x => MLLrVals.Tokens.EXCEPTION x
      | T.EQTYVAR x => MLLrVals.Tokens.EQTYVAR x
      | T.EQTYPE x => MLLrVals.Tokens.EQTYPE x
      | T.EQ x => MLLrVals.Tokens.EQ x
      | T.END x => MLLrVals.Tokens.END x
      | T.ELSE x => MLLrVals.Tokens.ELSE x
      | T.DO x => MLLrVals.Tokens.DO x
      | T.DATATYPE x => MLLrVals.Tokens.DATATYPE x
      | T.DARROW x => MLLrVals.Tokens.DARROW x
      | T.COMMA x => MLLrVals.Tokens.COMMA x
      | T.COLON x => MLLrVals.Tokens.COLON x
      | T.CHAR x => MLLrVals.Tokens.CHAR x
      | T.CASE x => MLLrVals.Tokens.CASE x
      | T.BUILTIN x => MLLrVals.Tokens.BUILTIN x
      | T.BAR x => MLLrVals.Tokens.BAR x
      | T.ATTRIBUTE x => MLLrVals.Tokens.ATTRIBUTE x
      | T.AT x => MLLrVals.Tokens.AT x
      | T.ASTERISK x => MLLrVals.Tokens.ASTERISK x
      | T.AS x => MLLrVals.Tokens.AS x
      | T.ARROW x => MLLrVals.Tokens.ARROW x
      | T.ANDALSO x => MLLrVals.Tokens.ANDALSO x
      | T.AND x => MLLrVals.Tokens.AND x
      | T.ABSTYPE x => MLLrVals.Tokens.ABSTYPE x
      | T.EOF x => MLLrVals.Tokens.EOF x

  val EOF = MLLrVals.Tokens.EOF (Loc.nopos, Loc.nopos) : token
  val SEMICOLON = MLLrVals.Tokens.SEMICOLON (Loc.nopos, Loc.nopos) : token

  datatype mode = Prelude | Interactive | Batch | File

  type source =
      {
        mode : mode,
        read : bool * int -> string,
        sourceName : string,
        initialLineno : int
      }

  type input =
      {
        mode : mode,
        lookahead : int,
        atOnce : bool,
        streamRef : Parser.stream ref,
        first : bool ref,
        errors : UserError.errorQueue,
        errorFn : string * Loc.pos * Loc.pos -> unit
      }

  fun parseError errors (msg, pos1, pos2) =
      UserError.enqueueError errors ((pos1,pos2), ParserError.ParseError msg)

  fun setup ({mode, read, sourceName, initialLineno}:source) =
      let
        val errors = UserError.createQueue ()
        val errorFn = parseError errors
        val first = ref false
        val lexarg =
            MLLex.UserDeclarations.initArg
              {sourceName = sourceName,
               isPrelude = (mode = Prelude),
               enableMeta = (mode <> File),
               lexErrorFn = errorFn,
               initialLineno = initialLineno,
               allow8bitId = !Control.allow8bitId}
        fun input n =
            read (!first andalso MLLex.UserDeclarations.isINITIAL lexarg, n)
        fun inputInteractive n =
            if UserError.isEmptyErrorQueue errors
            then input n
            else raise UserError.UserErrors (UserError.getErrors errors)

        val inputFn = if mode = Interactive then inputInteractive else input
        val lexer = convert o MLLex.makeLexer inputFn lexarg
        val stream = Parser.makeStream {lexer=lexer}
      in
        {
          mode = mode,
          lookahead = if mode = Interactive then 0 else 15,
          atOnce = (mode = File),
          streamRef = ref stream,
          first = first,
          errors = errors,
          errorFn = errorFn
        } : input
      end

  fun parseWhole errorFn parseStep lex =
      case parseStep lex of
        (Absyn.EOF, lex) => (Absyn.EOF, lex)
      | (u1 as Absyn.UNIT unit1, lex) =>
        case parseWhole errorFn parseStep lex of
          (Absyn.EOF, lex) => (u1, lex)
        | (Absyn.UNIT {interface, tops, loc}, lex) =>
          let
            val interface =
                case (unit1, interface) of
                  ({interface,...}, Absyn.NOINTERFACE) => interface
                | ({tops=nil,interface=Absyn.NOINTERFACE,...}, i) => i
                | (_, Absyn.INTERFACE symbol ) =>
                  let
                    val (pos1, pos2) = Symbol.symbolToLoc symbol
                  in
                    (errorFn ("_interface must be at the beginning of a file",
                              pos1, pos2);
                     Absyn.NOINTERFACE)
                  end
          in
            (Absyn.UNIT {interface = interface,
                         tops = #tops unit1 @ tops,
                         loc = (#1 (#loc unit1), #2 loc)},
             lex)
          end

  fun parse ({mode, lookahead, atOnce, streamRef, first, errors, errorFn}:input) =
      let
        (* prevent reading this source after parse error occurred. *)
        val _ = if UserError.isEmptyErrorQueue errors
                then () else raise Bug.Bug "parse: aborted stream"

        fun parseStep stream =
            let
              val _ = first := true
              val (tok, stream2) = Parser.getStream stream
              val _ = first := false
            in
              if Parser.sameToken (tok, EOF) then (Absyn.EOF, stream)
              else if Parser.sameToken (tok, SEMICOLON) then parseStep stream2
              else Parser.parse {lookahead=lookahead, stream=stream, error=errorFn, arg=()}
            end

        val stream = !streamRef
        val (result, newStream) =
            (if atOnce
             then parseWhole errorFn parseStep stream
             else parseStep stream)
            handle Parser.ParseError =>
                   raise UserError.UserErrors (UserError.getErrors errors)
        val _ = streamRef := newStream
      in
        if UserError.isEmptyErrorQueue errors
        then () else raise UserError.UserErrors (UserError.getErrors errors);
        result
      end

  fun isEOF ({mode, lookahead, atOnce, streamRef, first, errors, errorFn}:input) =
      let
        (* prevent reading this source after parse error occurred. *)
        val _ = if UserError.isEmptyErrorQueue errors
                then () else raise Bug.Bug "parse: aborted stream"

        val _ = first := true
        val (tok, _) = Parser.getStream (!streamRef)
        val _ = first := false
      in
        Parser.sameToken (tok, EOF)
      end
end
