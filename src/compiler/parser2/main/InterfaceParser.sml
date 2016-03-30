(**
 * parser for interface file.
 * @copyright (c) 2011 - 2015, Tohoku University.
 * @author UENO Katsuhiro
 * @author Atsushi Ohori
 *)
structure InterfaceParser =
struct
  structure Parser = InterfaceLrVals.Parser
  type token = Parser.token
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
            InterfaceLex.UserDeclarations.initArg
              {sourceName = sourceName,
               lexErrorFn = errorFn,
               initialLineno = 1,
               allow8bitId = !Control.allow8bitId}
        val lexer = InterfaceLex.makeLexer read lexarg
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
