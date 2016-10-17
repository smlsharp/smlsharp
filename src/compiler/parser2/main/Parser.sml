(**
 * ML parser.
 *
 * @author Atsushi ohori 
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *)
structure Parser =
struct
  structure Parser = MLLrVals.Parser
  type token = Parser.token

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
        val lexer = MLLex.makeLexer inputFn lexarg
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
