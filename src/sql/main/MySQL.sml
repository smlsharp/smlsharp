(**
 * importing MySQL C API
 * @author SATO Hiroyuki
 * @author UENO Katsuhiro
 * @copyright (c) 2010, Tohoku University.
 *)

structure SMLSharp_SQL_MySQL :> sig

  type MYSQL = unit ptr
  type MYSQL_RES = unit ptr
  type MYSQL_ROW = unit ptr ptr
  type my_ulonglong = int

  val mysql_init : unit -> MYSQL -> MYSQL
  val mysql_real_connect
      : unit -> (MYSQL * string * string * string * string *
                 int * unit ptr * int) -> MYSQL
  val mysql_errno : unit -> MYSQL -> int
  val mysql_error : unit -> MYSQL -> char ptr
  val mysql_query : unit -> (MYSQL * string) -> int
  val mysql_store_result : unit -> MYSQL -> MYSQL_RES
  val mysql_fetch_row : unit -> MYSQL_RES -> MYSQL_ROW
  val mysql_free_result : unit -> MYSQL -> unit
  val mysql_data_seek : unit -> (MYSQL_RES * my_ulonglong) -> unit
  val mysql_close : unit -> MYSQL -> unit
  val mysql_num_rows : unit -> MYSQL_RES -> my_ulonglong

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

  (* TODO: platform independent *)
  val lib =
      lazy (fn _ =>
               DynamicLink.dlopen
                 (case OS.Process.getEnv "SMLSHARP_LIBMYSQLCLIENT" of
                    NONE => "libmysqlclient.16." ^ SMLSharp_Config.DLLEXT ()
                  | SOME x => x))

  type MYSQL = unit ptr
  type MYSQL_RES = unit ptr
  type MYSQL_ROW = unit ptr ptr
  type my_ulonglong = int   (* 64bit int *)
  type MYSQL_ROW_OFFSET = int

  fun find s = DynamicLink.dlsym(lib (), s)
  val mysql_init =
      lazy (fn _ => find "mysql_init"
                    : _import (MYSQL) -> MYSQL)
  val mysql_real_connect =
      lazy (fn _ => find "mysql_real_connect"
                    : _import (MYSQL, string, string, string,
                               string, int, unit ptr, int) -> MYSQL)
  val mysql_errno =
      lazy (fn _ => find "mysql_errno"
                    :_import (MYSQL) -> int)
  val mysql_error =
      lazy (fn _ => find "mysql_error"
                    : _import (MYSQL) -> char ptr)
  val mysql_query =
      lazy (fn _ => find "mysql_query"
                    :_import (MYSQL, string) -> int)
  val mysql_store_result =
      lazy (fn _ => find "mysql_store_result"
                    :_import (MYSQL) -> MYSQL_RES)
  val mysql_use_result =
      lazy (fn _ => find "mysql_use_result"
                    :_import (MYSQL) -> MYSQL_RES)
  val mysql_fetch_row =
      lazy (fn _ => find "mysql_fetch_row"
                    : _import (MYSQL_RES) -> MYSQL_ROW)
  val mysql_free_result =
      lazy (fn _ => find "mysql_free_result"
                    :_import (MYSQL_RES) -> ())
  val mysql_close =
      lazy (fn _ => find "mysql_close"
                    :_import (MYSQL) -> ())

  (* mysql_data_seek takes a 64 bit integer as an argument.
   * Since current SML# does not support 64 bit integer,
   * we assume x86 calling convention and use sequential two
   * 32 bit integers to pass a 64 bit integer. High word of
   * the 64 bit integer is always set to 0. *)
  val mysql_data_seek =
      lazy (fn _ =>
               let
                 val mysql_data_seek =
                     find "mysql_data_seek"
                     : _import (MYSQL_RES,int (*lo*) ,int (*hi*) ) -> ()
               in
              fn (x, y) => mysql_data_seek (x, y, 0)
               end)

  (* mysql_num_rows returns a 64 bit interger but SML# does not
   * support it. We assume x86 calling convention to receive a
   * lower 32 bit of the 64 bit integer. *)
  val mysql_num_rows =
      lazy (fn _ => find "mysql_num_rows"
                    :_import (MYSQL_RES) -> my_ulonglong)

end
