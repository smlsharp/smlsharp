structure SMLSharp_SQL_BackendTy =
struct

  datatype ty =
      INT
    | INTINF
    | WORD
    | CHAR
    | STRING
    | REAL
    | REAL32
    | BOOL
    | TIMESTAMP
    | NUMERIC
    | UNSUPPORTED of string

  type schema_column = {ty: ty, nullable: bool}
  type schema_table = string * (string * schema_column) list
  type schema = schema_table list

end
