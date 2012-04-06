(**
 * parser for interface file.
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure InterfaceParser :> sig

  type source =
      {
        (** read upto "int" bytes. *)
        read : int -> string,
        (** name of this source *)
        sourceName : string
      }
  type input

  val setup : source -> input
  val parse : input -> AbsynInterface.itop

end =
struct
  structure Lex = MLLexFun(structure Tokens = InterfaceLrVals.Tokens)
  structure ParserData = InterfaceLrVals.ParserData  

  val makeLexer = 
   fn s => fn arg =>
	      LrParser.Stream.streamify (Lex.makeLexer s arg)
  val LrParse = fn (lookahead,lexer,error,arg) =>
	(fn (a,b) => (InterfaceLrVals.ParserData.Actions.extract a,b))
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
  type source =
      {read : int -> string, sourceName : string}

  type input =
      {
        lex : token LrParser.Stream.stream ref,
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
            Lex.UserDeclarations.initArg
              {sourceName = sourceName,
               isPrelude = false,
               enableMeta = false,
               lexErrorFn = errorFn,
               initialLineno = 1}
        val lex = makeLexer read lexarg
      in
        {lex = ref lex, errors = errors, errorFn = errorFn} : input
      end

  fun parse ({lex, errors, errorFn}:input) =
      let
        (* prevent reading this source after parse error occurred. *)
        val _ = if UserError.isEmptyErrorQueue errors
                then () else raise Control.Bug "parse: aborted stream"

        val (result, newLex) =
            LrParse (15, !lex, errorFn, ())
            handle LrParser.ParseError =>
                   raise UserError.UserErrors (UserError.getErrors errors)

        val _ = lex := newLex
      in
        if UserError.isEmptyErrorQueue errors
        then ()
        else raise UserError.UserErrors (UserError.getErrors errors);
        result
      end
end
