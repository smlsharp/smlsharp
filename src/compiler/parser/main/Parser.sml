(**
 * ML parser.
 *
 * @author Atsushi ohori 
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 *)
structure Parser :> sig

  datatype mode =
      Prelude        (* for prelude source code *)
    | Interactive    (* for interactive mode *)
    | Batch          (* for batch evaluation mode *)
    | File           (* for separate compilation *)

  type source =
      {
        (** parser mode.
         * If mode is File, the parser reads the entire input at once
         * and returns single Absyn.UNIT. *)
        mode : mode,
        (** read upto "int" bytes. "bool" indicates whether this call is
         * involved to obtain the first character of a program or not. *)
        read : bool * int -> string,
        (** name of this source *)
        sourceName : string,
        (** initial line count of this source *)
        initialLineno : int
      }
  type input

  val setup : source -> input
  val parse : input -> Absyn.unitparseresult
  val isEOF : input -> bool

end =
struct
  structure MLLex = MLLexFun(structure Tokens = MLLrVals.Tokens)
  structure ParserData = MLLrVals.ParserData
  val makeLexer = 
   fn s => fn arg =>
	      LrParser.Stream.streamify (MLLex.makeLexer s arg)
  val LrParse = fn (lookahead,lexer,error,arg) =>
	(fn (a,b) => (MLLrVals.ParserData.Actions.extract a,b))
     (LrParser.parse {table = ParserData.table,
	        lexer=lexer,
		lookahead=lookahead,
		saction = ParserData.Actions.actions,
		arg=arg,
		void= ParserData.Actions.void,
	        ec = {is_keyword = ParserData.EC.is_keyword,
		      noShift = ParserData.EC.noShift,
		      preferred_change = ParserData.EC.preferred_change,
		      errtermvalue = ParserData.EC.errtermvalue,
		      error=error,
		      showTerminal = ParserData.EC.showTerminal,
		      terms = ParserData.EC.terms}}
      )


  type token = (ParserData.svalue, ParserData.pos) LrParser.Token.token
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
        lex : token LrParser.Stream.stream ref,
        first : bool ref,
        errors : UserError.errorQueue,
        errorFn : string * Loc.pos * Loc.pos -> unit
      }

  fun parseError errors (msg, lpos, rpos) =
      UserError.enqueueError errors ((lpos, rpos), ParserError.ParseError msg)

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
               initialLineno = initialLineno}
        fun input n =
            read (!first andalso MLLex.UserDeclarations.isINITIAL lexarg, n)
        fun inputInteractive n =
            if UserError.isEmptyErrorQueue errors
            then input n
            else raise UserError.UserErrors (UserError.getErrors errors)

        val inputFn = if mode = Interactive then inputInteractive else input
        val lex = makeLexer inputFn lexarg
      in
        {
          mode = mode,
          lookahead = if mode = Interactive then 0 else 15,
          atOnce = (mode = File),
          lex = ref lex,
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
                | (_, Absyn.INTERFACE {loc=(l,r),...}) =>
                  (errorFn ("_interface must be at the beginning of a file",
                            l,r);
                   Absyn.NOINTERFACE)
          in
            (Absyn.UNIT {interface = interface,
                         tops = #tops unit1 @ tops,
                         loc = (#1 (#loc unit1), #2 loc)},
             lex)
          end

  fun parse ({mode, lookahead, atOnce, lex, first, errors, errorFn}:input) =
      let
        (* prevent reading this source after parse error occurred. *)
        val _ = if UserError.isEmptyErrorQueue errors
                then () else raise Control.Bug "parse: aborted stream"

        fun parseStep lex =
            let
              val _ = first := true
              val (tok, lex2) = LrParser.Stream.get lex
              val _ = first := false
            in
              if ParserData.Token.sameToken (tok, EOF) then (Absyn.EOF, lex)
              else if ParserData.Token.sameToken (tok, SEMICOLON) then parseStep lex2
              else LrParse (lookahead, lex, errorFn, ())
            end

        val lexer = !lex
        val (result, newLex) =
            (if atOnce
             then parseWhole errorFn parseStep lexer
             else parseStep lexer)
            handle LrParser.ParseError =>
                   raise UserError.UserErrors (UserError.getErrors errors)
        val _ = lex := newLex
      in
        if UserError.isEmptyErrorQueue errors
        then () else raise UserError.UserErrors (UserError.getErrors errors);
        result
      end

  fun isEOF ({mode, lookahead, atOnce, lex, first, errors, errorFn}:input) =
      let
        (* prevent reading this source after parse error occurred. *)
        val _ = if UserError.isEmptyErrorQueue errors
                then () else raise Control.Bug "parse: aborted stream"

        val _ = first := true
        val (tok, _) = LrParser.Stream.get (!lex)
        val _ = first := false
      in
        ParserData.Token.sameToken (tok, EOF)
      end
end
