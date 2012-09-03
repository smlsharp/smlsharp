structure Ast =
struct

  datatype command = EXIT
                   | PRINT of SMLFormat.FormatExpression.expression list
                   | SET of string * string
                   | USE of string

end