(**
 * common interface for database backends.
 * @author SATO Hiroyuki
 * @copyright (c) 2010, Tohoku University.
 *)

signature SMLSharp_SQL_SQLBACKEND =
sig

  (* Compilar requres that both conn and res are unit ptr. *)
  type conn = unit ptr
  type res = unit ptr
  type sqltype

  exception Exec of string
  exception Connect of string
  exception Format

  val eof : res * int -> bool
  val execQuery : conn * string -> res
  val closeConn : conn -> unit
  val closeRel : res -> unit
  val numOfRows : res -> int
  val getDatabaseSchema : conn -> (string *
                                   {colname: string,
                                    typename: sqltype,
                                    isnull: bool} list) list
  val connect : string -> conn
  val getInt : res * int * int -> int option
  val getWord : res * int * int -> word option
  val getReal : res * int * int -> real option
  val getString : res * int * int -> string option
  val getChar : res * int * int -> char option
  val getBool : res * int * int -> bool option
  val translateType : sqltype -> string option

end
