(**
 * ML parser.
 *
 * @author Atsushi ohori 
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *)
structure SMLSharpParser =
struct
  structure Parser = ML.Parser
  type token = Parser.token

  (* for debug *)
  fun showToken (ML.ParserData.Token.TOKEN (t, _)) =
      ML.ParserData.EC.showTerminal t

  val EOF = ML.Tokens.EOF (Loc.nopos, Loc.nopos) : token
  val SEMICOLON = ML.Tokens.SEMICOLON (Loc.nopos, Loc.nopos) : token

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
        first : bool ref,
        errors : (Loc.loc * string) list ref,
        errorFn : string * Loc.pos * Loc.pos -> unit,
        source : Loc.source
      }

  exception Error of (Loc.loc * string) list

  fun setup ({source, read, initialLineno}:source) =
      let
        val errors = ref nil
        val errorFn = fn (s, p1, p2) => errors := ((p1, p2), s) :: !errors
        val first = ref false
        val interactive =
            case source of Loc.INTERACTIVE => true | Loc.FILE _ => false
        val lexarg =
            MLLex.UserDeclarations.initArg
              {source = source,
               enableMeta = interactive,
               lexErrorFn = errorFn,
               initialLineno = initialLineno,
               allow8bitId = !Control.allow8bitId}
        fun input n =
            read (!first andalso MLLex.UserDeclarations.isINITIAL lexarg, n)
        fun inputInteractive n =
            case !errors of nil => input n | errors => raise Error (rev errors)
        val inputFn = if interactive then inputInteractive else input
        val lexer = MLLex.makeLexer inputFn lexarg
        val stream = Parser.makeStream {lexer=lexer}
      in
        {
          lookahead = if interactive then 0 else 15,
          atOnce = not interactive,
          streamRef = ref stream,
          first = first,
          errors = errors,
          errorFn = errorFn,
          source = source
        } : input
      end

  fun sourceOfInput ({source, ...}:input) = source
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
                | (_, Absyn.INTERFACE (filename, (pos1, pos2))) =>
                  (errorFn ("_interface must be at the beginning of a file",
                            pos1, pos2);
                   Absyn.NOINTERFACE)
          in
            (Absyn.UNIT {interface = interface,
                         tops = #tops unit1 @ tops,
                         loc = (#1 (#loc unit1), #2 loc)},
             lex)
          end

  fun parse ({lookahead, atOnce, streamRef, first, errors, errorFn, source}:input) =
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
              if Parser.sameToken (tok, EOF) then (Absyn.EOF, stream)
              else if Parser.sameToken (tok, SEMICOLON) then parseStep stream2
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
      in
        case !errors of nil => () | errors => raise Error (rev errors);
        result
      end

  fun isEOF ({lookahead, atOnce, streamRef, first, errors, errorFn, source}:input) =
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
      in
        case !errors of nil => () | errors => raise Error (rev errors);
        Parser.sameToken (tok, EOF)
      end

end
