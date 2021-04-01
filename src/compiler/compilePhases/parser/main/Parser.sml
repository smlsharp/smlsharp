(**
 * ML parser
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)

structure Parser =
struct
  open SMLSharpParser

  type source = SMLSharpParser.source
  type input = SMLSharpParser.input
  exception ParseError = ParserError.ParseError

  fun raiseUserErrors errors =
      raise UserError.UserErrors
            (map (fn (loc, msg) => (loc, UserError.Error, ParseError msg))
                 errors)

  val setup = SMLSharpParser.setup

  fun parse input =
      SMLSharpParser.parse input
      handle SMLSharpParser.Error errors => raiseUserErrors errors

  fun isEOF input =
      SMLSharpParser.isEOF input
      handle SMLSharpParser.Error errors => raiseUserErrors errors

end
