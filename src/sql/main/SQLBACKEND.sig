(**
 * common interface for database backends.
 * @author SATO Hiroyuki
 * @author UENO Katsuhiro
 * @copyright (c) 2010, Tohoku University.
 *)

signature SMLSharp_SQL_SQLBACKEND =
sig

  type conn
  type res
  type value

  val execQuery : conn * string -> res
  val closeConn : conn -> unit
  val closeRes : res -> unit
  val getDatabaseSchema : conn -> SMLSharp_SQL_BackendTy.schema
  val connect : string -> conn
  val fetch : res -> bool  (* return false if it reaches the end *)
  val getValue : res * int -> value option
  val intValue : value -> int option
  val intInfValue : value -> intInf option
  val wordValue : value -> word option
  val realValue : value -> real option
  val real32Value : value -> real32 option
  val stringValue : value -> string option
  val charValue : value -> char option
  val boolValue : value -> bool option
  val timestampValue : value -> SMLSharp_SQL_TimeStamp.timestamp option
  val decimalValue : value -> SMLSharp_SQL_Decimal.decimal option
  val floatValue : value -> SMLSharp_SQL_Float.float option

end
