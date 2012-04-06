(**
 * PostgreSQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @copyright (c) 2009, 2010, Tohoku University.
 *)

structure SMLSharp_SQL_PGSQL :> sig

  type conn = unit ptr
  type result = unit ptr
  eqtype status
  eqtype resultStatus

  val CONNECTION_OK : status
  val CONNECTION_BAD : status
  val PGRES_EMPTY_QUERY : resultStatus
  val PGRES_COMMAND_OK : resultStatus
  val PGRES_TUPLES_OK : resultStatus
  val PGRES_COPY_OUT : resultStatus
  val PGRES_COPY_IN : resultStatus
  val PGRES_BAD_RESPONSE : resultStatus
  val PGRES_NONFATAL_ERROR : resultStatus
  val PGRES_FATAL_ERROR : resultStatus

  val PQconnectdb : unit -> string -> conn
  val PQstatus : unit -> conn -> status
  val PQfinish : unit -> conn -> unit
  val PQexec : unit -> (conn * string) -> result
  val PQgetvalue : unit -> (result * int * int) -> Word8.word ptr
  val PQgetlength : unit -> (result * int * int) -> int
  val PQgetisnull : unit -> (result * int * int) -> bool
  val PQntuples : unit -> result -> int
  val PQnfields : unit -> result -> int
  val PQresultStatus : unit -> result -> resultStatus
  val PQerrorMessage : unit -> conn -> char ptr
  val PQresultErrorMessage : unit -> result -> char ptr
  val PQdb : unit -> conn -> char ptr
  val PQuser : unit -> conn -> char ptr
  val PQclear : unit -> result -> unit

  val getErrorMessage : conn -> string
  val getResErrorMessage : result -> string
  val getDBname : conn -> string
  val getDBuser : conn -> string

end =
struct

  fun lazy f =
      let
        val r = ref NONE
      in
        fn () =>
           case !r of
             SOME x => x
           | NONE =>
             let val x = f ()
             in r := SOME x; x
             end
      end

  (* ToDo: platform independent *)
  val lib =
      lazy (fn _ =>
               DynamicLink.dlopen
                 (case OS.Process.getEnv "SMLSHARP_LIBPQ" of
                    NONE => "libpq.5." ^ SMLSharp_Config.DLLEXT ()
                  | SOME x => x))

  type conn = unit ptr
  type result = unit ptr
  type status = int
  type resultStatus = int

  val CONNECTION_OK = 0
  val CONNECTION_BAD = 1
  val PGRES_EMPTY_QUERY = 0
  val PGRES_COMMAND_OK = 1
  val PGRES_TUPLES_OK = 2
  val PGRES_COPY_OUT = 3
  val PGRES_COPY_IN = 4
  val PGRES_BAD_RESPONSE = 5
  val PGRES_NONFATAL_ERROR = 6
  val PGRES_FATAL_ERROR = 7

  val PQconnectdb =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQconnectdb")
                    : _import string -> unit ptr)
  val PQstatus =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQstatus")
                    : _import unit ptr -> int)
  val PQfinish =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQfinish")
                    : _import unit ptr -> unit)
  val PQexec =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQexec")
                    : _import (unit ptr, string) -> unit ptr)
  val PQgetvalue =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQgetvalue")
                    : _import (unit ptr, int, int) -> Word8.word ptr)
  val PQgetlength =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQgetlength")
                    : _import (unit ptr, int, int) -> int)
  val PQgetisnull =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQgetisnull")
                    : _import (unit ptr, int, int) -> bool)
  val PQntuples =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQntuples")
                    : _import unit ptr -> int)
  val PQnfields =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQnfields")
                    : _import unit ptr -> int)
  val PQresultStatus =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQresultStatus")
                    : _import unit ptr -> int)
  val PQerrorMessage =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQerrorMessage")
                    : _import unit ptr -> char ptr)
  val PQresultErrorMessage =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQresultErrorMessage")
                    : _import unit ptr -> char ptr)
  val PQdb =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQdb")
                    : _import unit ptr -> char ptr)
  val PQuser =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQuser")
                    : _import unit ptr -> char ptr)
  val PQclear =
      lazy (fn _ => DynamicLink.dlsym (lib (), "PQclear")
                    : _import unit ptr -> unit)

  fun getErrorMessage conn =
      SMLSharpRuntime.str_new (PQerrorMessage () conn)

  fun getResErrorMessage res =
      SMLSharpRuntime.str_new (PQresultErrorMessage () res)

  fun getDBname conn =
      SMLSharpRuntime.str_new (PQdb () conn)

  fun getDBuser conn =
      SMLSharpRuntime.str_new (PQuser () conn)

end
