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

  structure LrVals = InterfaceLrValsFun(structure Token = LrParser.Token)
  structure Lex = MLLexFun(structure Tokens = LrVals.Tokens)
  structure Parser = JoinWithArg(structure ParserData = LrVals.ParserData
                                 structure Lex = Lex
                                 structure LrParser = LrParser)
  type token = (Parser.svalue, Parser.pos) Parser.Token.token

  type source =
      {read : int -> string, sourceName : string}

  type input =
      {
        lex : token Parser.Stream.stream ref,
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
        val lex = Parser.makeLexer read lexarg
      in
        {lex = ref lex, errors = errors, errorFn = errorFn} : input
      end

  fun parse ({lex, errors, errorFn}:input) =
      let
        (* prevent reading this source after parse error occurred. *)
        val _ = if UserError.isEmptyErrorQueue errors
                then () else raise Control.Bug "parse: aborted stream"

        val (result, newLex) =
            Parser.parse (15, !lex, errorFn, ())
            handle Parser.ParseError =>
                   raise UserError.UserErrors (UserError.getErrors errors)
        val _ = lex := newLex
      in
        if UserError.isEmptyErrorQueue errors
        then ()
        else raise UserError.UserErrors (UserError.getErrors errors);
        result
      end

end
