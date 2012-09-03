structure Ast =
struct

  datatype command = EXIT
                   | PRINT of SMLPP.FormatExpression.expression list
                   | SET of string * string
                   | USE of string

end