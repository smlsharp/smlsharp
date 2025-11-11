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
        | T.INVALID s => Tokens.INVALID (s, pos1, pos2)
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
        | T.U_ATTRIBUTE => Tokens.U_ATTRIBUTE (pos1, pos2)
        | T.U_BUILTIN => Tokens.U_BUILTIN (pos1, pos2)
        | T.U_FOREACH => Tokens.U_FOREACH (pos1, pos2)
        | T.U_IMPORT => Tokens.U_IMPORT (pos1, pos2)
        | T.U_INTERFACE => Tokens.U_INTERFACE (pos1, pos2)
        | T.U_JOIN => Tokens.U_JOIN (pos1, pos2)
        | T.U_EXTEND => Tokens.U_EXTEND (pos1, pos2)
        | T.U_UPDATE => Tokens.U_UPDATE (pos1, pos2)
        | T.U_DYNAMIC => Tokens.U_DYNAMIC (pos1, pos2)
        | T.U_DYNAMICCASE => Tokens.U_DYNAMICCASE (pos1, pos2)
        | T.U_DYNAMICNULL => Tokens.U_DYNAMICNULL (pos1, pos2)
        | T.U_DYNAMICVIEW => Tokens.U_DYNAMICVIEW (pos1, pos2)
        | T.U_DYNAMICVOID => Tokens.U_DYNAMICVOID (pos1, pos2)
        | T.U_POLYREC => Tokens.U_POLYREC (pos1, pos2)
        | T.U_REIFYTY => Tokens.U_REIFYTY (pos1, pos2)
        | T.U_REQUIRE => Tokens.U_REQUIRE (pos1, pos2)
        | T.U_SIZEOF => Tokens.U_SIZEOF (pos1, pos2)
        | T.U_SQL => Tokens.U_SQL (pos1, pos2)
        | T.U_SQLEVAL => Tokens.U_SQLEVAL (pos1, pos2)
        | T.U_SQLEXEC => Tokens.U_SQLEXEC (pos1, pos2)
        | T.U_SQLSERVER => Tokens.U_SQLSERVER (pos1, pos2)
        | T.U_USE => Tokens.U_USE (pos1, pos2)
        | T.ALNUMID "use" =>
          if enableMeta
          then Tokens.USE (pos1, pos2)
          else Tokens.ALNUMID ("use", pos1, pos2)
        | T.ALNUMID "all" => Tokens.ALL (pos1, pos2)
        | T.ALNUMID "asc" => Tokens.ASC (pos1, pos2)
        | T.ALNUMID "begin" => Tokens.BEGIN (pos1, pos2)
        | T.ALNUMID "by" => Tokens.BY (pos1, pos2)
        | T.ALNUMID "commit" => Tokens.COMMIT (pos1, pos2)
        | T.ALNUMID "cross" => Tokens.CROSS (pos1, pos2)
        | T.ALNUMID "default" => Tokens.DEFAULT (pos1, pos2)
        | T.ALNUMID "delete" => Tokens.DELETE (pos1, pos2)
        | T.ALNUMID "desc" => Tokens.DESC (pos1, pos2)
        | T.ALNUMID "distinct" => Tokens.DISTINCT (pos1, pos2)
        | T.ALNUMID "exists" => Tokens.EXISTS (pos1, pos2)
        | T.ALNUMID "false" => Tokens.FALSE (pos1, pos2)
        | T.ALNUMID "fetch" => Tokens.FETCH (pos1, pos2)
        | T.ALNUMID "first" => Tokens.FIRST (pos1, pos2)
        | T.ALNUMID "from" => Tokens.FROM (pos1, pos2)
        | T.ALNUMID "group" => Tokens.GROUP (pos1, pos2)
        | T.ALNUMID "having" => Tokens.HAVING (pos1, pos2)
        | T.ALNUMID "inner" => Tokens.INNER (pos1, pos2)
        | T.ALNUMID "insert" => Tokens.INSERT (pos1, pos2)
        | T.ALNUMID "into" => Tokens.INTO (pos1, pos2)
        | T.ALNUMID "is" => Tokens.IS (pos1, pos2)
        | T.ALNUMID "join" => Tokens.JOIN (pos1, pos2)
        | T.ALNUMID "limit" => Tokens.LIMIT (pos1, pos2)
        | T.ALNUMID "natural" => Tokens.NATURAL (pos1, pos2)
        | T.ALNUMID "next" => Tokens.NEXT (pos1, pos2)
        | T.ALNUMID "not" => Tokens.NOT (pos1, pos2)
        | T.ALNUMID "null" => Tokens.NULL (pos1, pos2)
        | T.ALNUMID "offset" => Tokens.OFFSET (pos1, pos2)
        | T.ALNUMID "on" => Tokens.ON (pos1, pos2)
        | T.ALNUMID "only" => Tokens.ONLY (pos1, pos2)
        | T.ALNUMID "or" => Tokens.OR (pos1, pos2)
        | T.ALNUMID "order" => Tokens.ORDER (pos1, pos2)
        | T.ALNUMID "rollback" => Tokens.ROLLBACK (pos1, pos2)
        | T.ALNUMID "row" => Tokens.ROW (pos1, pos2)
        | T.ALNUMID "rows" => Tokens.ROWS (pos1, pos2)
        | T.ALNUMID "select" => Tokens.SELECT (pos1, pos2)
        | T.ALNUMID "set" => Tokens.SET (pos1, pos2)
        | T.ALNUMID "true" => Tokens.TRUE (pos1, pos2)
        | T.ALNUMID "unknown" => Tokens.UNKNOWN (pos1, pos2)
        | T.ALNUMID "update" => Tokens.UPDATE (pos1, pos2)
        | T.ALNUMID "values" => Tokens.VALUES (pos1, pos2)
        | T.ALNUMID s => Tokens.ALNUMID (s, pos1, pos2)
        | T.EQTYVAR s => Tokens.EQTYVAR (s, pos1, pos2)
        | T.FREE_TYVAR s => Tokens.FREE_TYVAR (s, pos1, pos2)
        | T.FREE_EQTYVAR s => Tokens.FREE_EQTYVAR (s, pos1, pos2)
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
        initialLineno : int
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

  fun setup ({source, read, initialLineno}:source) =
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
               allow8bitId = !Control.allow8bitId}
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
