(**
 * @author YAMATODANI Kiyoshi
 * @copyright (C) 2021 SML# Development Team.
 *)
structure Ast =
struct

  datatype command = EXIT
                   | PRINT of SMLFormat.FormatExpression.expression list
                   | SET of string * string
                   | USE of string

end