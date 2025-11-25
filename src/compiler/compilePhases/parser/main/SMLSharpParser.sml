(**
 * ML parser.
 *
 * @author Atsushi ohori 
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *)
structure SMLSharpParser =
struct
  structure T = Token
  structure Parser = ImlGrm.Parser
  structure Tokens = ImlGrm.Tokens

  fun toParserToken enableMeta lexer () =
      case lexer () of
        (token, (pos1, pos2)) =>
        case token of
          T.EOF => Tokens.EOF (pos1, pos2)
        | T.COMMENT => toParserToken enableMeta lexer ()
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
        | T.ALNUMID (s as "attribute__") => Tokens.ATTRIBUTE__ (s, pos1, pos2)
        | T.ALNUMID (s as "dynamic") => Tokens.DYNAMIC (s, pos1, pos2)
        | T.ALNUMID (s as "dynamiccase") => Tokens.DYNAMICCASE (s, pos1, pos2)
        | T.ALNUMID (s as "dynamicnull") => Tokens.DYNAMICNULL (s, pos1, pos2)
        | T.ALNUMID (s as "dynamicview") => Tokens.DYNAMICVIEW (s, pos1, pos2)
        | T.ALNUMID (s as "dynamicvoid") => Tokens.DYNAMICVOID (s, pos1, pos2)
        | T.ALNUMID (s as "extend") => Tokens.EXTEND (s, pos1, pos2)
        | T.ALNUMID (s as "foreach") => Tokens.FOREACH (s, pos1, pos2)
        | T.ALNUMID (s as "import") => Tokens.IMPORT (s, pos1, pos2)
        | T.ALNUMID (s as "interface") => Tokens.INTERFACE (s, pos1, pos2)
        | T.ALNUMID (s as "reifyTy") => Tokens.REIFYTY (s, pos1, pos2)
        | T.ALNUMID (s as "sizeof") => Tokens.SIZEOF (s, pos1, pos2)
        | T.ALNUMID (s as "sql") => Tokens.SQL (s, pos1, pos2)
        | T.ALNUMID (s as "sqlserver") => Tokens.SQLSERVER (s, pos1, pos2)
        | T.ALNUMID (s as "use") =>
          if enableMeta
          then Tokens.USE_META (s, pos1, pos2)
          else Tokens.USE (s, pos1, pos2)
        | T.ALNUMID (s as "all") => Tokens.ALL (s, pos1, pos2)
        | T.ALNUMID (s as "asc") => Tokens.ASC (s, pos1, pos2)
        | T.ALNUMID (s as "begin") => Tokens.BEGIN (s, pos1, pos2)
        | T.ALNUMID (s as "by") => Tokens.BY (s, pos1, pos2)
        | T.ALNUMID (s as "commit") => Tokens.COMMIT (s, pos1, pos2)
        | T.ALNUMID (s as "cross") => Tokens.CROSS (s, pos1, pos2)
        | T.ALNUMID (s as "default") => Tokens.DEFAULT (s, pos1, pos2)
        | T.ALNUMID (s as "delete") => Tokens.DELETE (s, pos1, pos2)
        | T.ALNUMID (s as "desc") => Tokens.DESC (s, pos1, pos2)
        | T.ALNUMID (s as "distinct") => Tokens.DISTINCT (s, pos1, pos2)
        | T.ALNUMID (s as "exists") => Tokens.EXISTS (s, pos1, pos2)
        | T.ALNUMID (s as "false") => Tokens.FALSE (s, pos1, pos2)
        | T.ALNUMID (s as "fetch") => Tokens.FETCH (s, pos1, pos2)
        | T.ALNUMID (s as "first") => Tokens.FIRST (s, pos1, pos2)
        | T.ALNUMID (s as "from") => Tokens.FROM (s, pos1, pos2)
        | T.ALNUMID (s as "group") => Tokens.GROUP (s, pos1, pos2)
        | T.ALNUMID (s as "having") => Tokens.HAVING (s, pos1, pos2)
        | T.ALNUMID (s as "inner") => Tokens.INNER (s, pos1, pos2)
        | T.ALNUMID (s as "insert") => Tokens.INSERT (s, pos1, pos2)
        | T.ALNUMID (s as "into") => Tokens.INTO (s, pos1, pos2)
        | T.ALNUMID (s as "is") => Tokens.IS (s, pos1, pos2)
        | T.ALNUMID (s as "join") => Tokens.JOIN (s, pos1, pos2)
        | T.ALNUMID (s as "limit") => Tokens.LIMIT (s, pos1, pos2)
        | T.ALNUMID (s as "natural") => Tokens.NATURAL (s, pos1, pos2)
        | T.ALNUMID (s as "next") => Tokens.NEXT (s, pos1, pos2)
        | T.ALNUMID (s as "not") => Tokens.NOT (s, pos1, pos2)
        | T.ALNUMID (s as "null") => Tokens.NULL (s, pos1, pos2)
        | T.ALNUMID (s as "offset") => Tokens.OFFSET (s, pos1, pos2)
        | T.ALNUMID (s as "on") => Tokens.ON (s, pos1, pos2)
        | T.ALNUMID (s as "only") => Tokens.ONLY (s, pos1, pos2)
        | T.ALNUMID (s as "or") => Tokens.OR (s, pos1, pos2)
        | T.ALNUMID (s as "order") => Tokens.ORDER (s, pos1, pos2)
        | T.ALNUMID (s as "rollback") => Tokens.ROLLBACK (s, pos1, pos2)
        | T.ALNUMID (s as "row") => Tokens.ROW (s, pos1, pos2)
        | T.ALNUMID (s as "rows") => Tokens.ROWS (s, pos1, pos2)
        | T.ALNUMID (s as "select") => Tokens.SELECT (s, pos1, pos2)
        | T.ALNUMID (s as "set") => Tokens.SET (s, pos1, pos2)
        | T.ALNUMID (s as "true") => Tokens.TRUE (s, pos1, pos2)
        | T.ALNUMID (s as "unknown") => Tokens.UNKNOWN (s, pos1, pos2)
        | T.ALNUMID (s as "update") => Tokens.UPDATE (s, pos1, pos2)
        | T.ALNUMID (s as "values") => Tokens.VALUES (s, pos1, pos2)
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

  (* for debug *)
  fun showToken (ImlGrm.ParserData.Token.TOKEN (t, _)) =
      ImlGrm.ParserData.EC.showTerminal t

  val dummyPos = {source = Loc.INTERACTIVE, pos = Loc.EOF}
  val EOF = Tokens.EOF (dummyPos, dummyPos)
  val SEMICOLON = Tokens.SEMICOLON (dummyPos, dummyPos)

  fun getLoc (ImlGrm.ParserData.Token.TOKEN (_, (_, l, r))) = (l, r)

  fun semicolonUnit loc =
      Absyn.UNIT (NONE, [Absyn.TOPSEMICOLON loc], loc)

  type source =
      {
        source : Loc.source,
        read : bool * int -> string,
        initialLineno : int,
        allowUtf8 : bool
      }

  type input =
      {
        lookahead : int,
        atOnce : bool,
        streamRef : Parser.stream ref,
        tokensRef : (Token.token * (Loc.at * Loc.at)) snoc ref,
        first : bool ref,
        errors : (Absyn.loc * string) list ref,
        errorFn : string * Loc.pos * Loc.pos -> unit,
        source : Loc.source
      }

  exception Error of (Absyn.loc * string) list

  fun setup ({source, read, initialLineno, allowUtf8}:source) =
      let
        val errors = ref nil
        val errorFn = fn (s, p1, p2) => errors := ((p1, p2), s) :: !errors
        val first = ref false
        val interactive =
            case source of Loc.INTERACTIVE => true | Loc.FILE _ => false
        val lexarg =
            ImlLex.UserDeclarations.initArg
              {source = source,
               errorFn = errorFn,
               initialLineno = initialLineno,
               allowUtf8 = allowUtf8}
        fun input n =
            read (!first andalso ImlLex.UserDeclarations.isINITIAL lexarg, n)
        fun inputInteractive n =
            case !errors of nil => input n | errors => raise Error (rev errors)
        val inputFn = if interactive then inputInteractive else input
        val lexer = ImlLex.makeLexer inputFn lexarg
        val tokensRef = ref NIL
        val lexer = ImlLex.UserDeclarations.setupLexer tokensRef lexer
        val lexer = toParserToken interactive lexer
        val stream = Parser.makeStream {lexer = lexer}
      in
        {
          lookahead = if interactive then 0 else 15,
          atOnce = not interactive,
          streamRef = ref stream,
          tokensRef = tokensRef,
          first = first,
          errors = errors,
          errorFn = errorFn,
          source = source
        } : input
      end

  fun sourceOfInput ({source, ...}:input) = source
  fun parseWhole errorFn parseStep lex =
      case parseStep lex of
        (u as Absyn.EOF _, lex) => (u, lex)
      | (u1 as Absyn.UNIT (unit1 as (interface1, tops1, loc1)), lex) =>
        case parseWhole errorFn parseStep lex of
          (Absyn.EOF _, lex) => (u1, lex)
        | (Absyn.UNIT (interface, tops, loc), lex) =>
          let
            val interface =
                case (interface1, tops1, interface) of
                  (_, _, NONE) => interface1
                | (NONE, nil, _) => interface
                | (_, _, SOME (filename, (pos1, pos2))) =>
                  (errorFn ("_interface must be at the beginning of a file",
                            pos1, pos2);
                   NONE)
          in
            (Absyn.UNIT (interface, tops1 @ tops, (#1 loc1, #2 loc)), lex)
          end

  fun parse ({lookahead, atOnce, streamRef, tokensRef, first, source, errors,
              errorFn, ...} : input) =
      let
        (* prevent reading this source after parse error occurred. *)
        val _ = case !errors of
                  nil => () | _::_ => raise Bug.Bug "parse: aborted stream"

        fun parseStep stream =
            let
              val _ = first := true
              val (tok, stream2) = Parser.getStream stream
              val _ = first := false
            in
              if Parser.sameToken (tok, EOF)
              then (Absyn.EOF {source = source, pos = Loc.EOF}, stream)
              else if Parser.sameToken (tok, SEMICOLON)
              then (semicolonUnit (getLoc tok), stream2)
              else Parser.parse {lookahead = lookahead,
                                 stream = stream,
                                 error = errorFn,
                                 arg = ()}
            end

        val stream = !streamRef
        val (result, newStream) =
            (if atOnce
             then parseWhole errorFn parseStep stream
             else parseStep stream)
            handle Parser.ParseError => raise Error (rev (!errors))
        val _ = streamRef := newStream
        val tokens = !tokensRef before tokensRef := NIL
      in
        case !errors of nil => () | errors => raise Error (rev errors);
        (tokens, result)
      end

  fun isEOF ({lookahead, atOnce, streamRef, tokensRef, first,
              errors, ...} : input) =
      let
        (* prevent reading this source after parse error occurred. *)
        val _ = case !errors of
                  nil => () | _::_ => raise Bug.Bug "parse: aborted stream"

        fun skipSemicolons stream =
            let
              val _ = first := true
              val (tok, stream2) = Parser.getStream stream
              val _ = first := false
            in
              if Parser.sameToken (tok, SEMICOLON)
              then skipSemicolons stream2
              else (tok, stream)
            end

        val (tok, stream) = skipSemicolons (!streamRef)
        val _ = streamRef := stream
        val _ = tokensRef := NIL
      in
        case !errors of nil => () | errors => raise Error (rev errors);
        Parser.sameToken (tok, EOF)
      end

end
