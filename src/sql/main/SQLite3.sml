(**
 * SQLite support for SML#
 * @author UENO Katsuhiro
 * @author Rodolphe Bertolini
 * @copyright (c) 2017, Tohoku University.
 *)

structure SMLSharp_SQL_SQLite3 =
struct

  (* lazy : (unit -> 'a -> 'b) -> 'a -> 'b *)
  fun lazy f =
      let
        val r = ref NONE
      in
        fn x =>
           case !r of
             SOME g => g x
           | NONE =>
             let val g = f ()
             in r := SOME g; g x
             end
      end

  (* ToDo: make it platform independent *)

  val dlsym =
      lazy (fn _ =>
               let
                 val lib =
                     DynamicLink.dlopen
                       (case OS.Process.getEnv "SMLSHARP_LIBSQLITE3" of
                          SOME x => x
                        | NONE =>
                          case !SMLSharp_SQL_Config.DLLEXT of
                            "so" => "libsqlite3.so.0"
                          | dll => "libsqlite3.0." ^ dll)
               in
                 fn sym => DynamicLink.dlsym (lib, sym)
               end)

  val SQLITE_OK = 0
  val SQLITE_ROW = 100
  val SQLITE_DONE = 101

  type open_mode = word
  val SQLITE_OPEN_READONLY = 0wx00000001
  val SQLITE_OPEN_READWRITE = 0wx00000002
  val SQLITE_OPEN_READWRITE_CREATE = 0wx00000006

  type threading_mode = word
  val SQLITE_OPEN_NOMUTEX = 0wx00008000
  val SQLITE_OPEN_FULLMUTEX = 0wx00010000

  type cache_mode = word
  val SQLITE_OPEN_SHAREDCACHE = 0wx00020000
  val SQLITE_OPEN_PRIVATECACHE = 0wx00040000

  type uri_mode = word
  val SQLITE_OPEN_URI = 0wx00000040

  type flags = {mode : open_mode,
                threading : threading_mode,
                cache : cache_mode,
                uri : uri_mode}
  val flags = {mode = SQLITE_OPEN_READWRITE_CREATE,
               threading = 0w0,
               cache = 0w0,
               uri = 0w0}

  type column_type = int
  val SQLITE_INTEGER = 1
  val SQLITE_FLOAT = 2
  val SQLITE3_TEXT = 3
  val SQLITE_BLOB = 4
  val SQLITE_NULL = 5

  type sqlite3 = unit ptr
  type sqlite3_stmt = unit ptr

  val new_sqlite3 =
      fn () => ref (SMLSharp_Builtin.Pointer.null () : sqlite3)
  val new_sqlite3_stmt =
      fn () => ref (SMLSharp_Builtin.Pointer.null () : sqlite3_stmt)

  val sqlite3_errstr =
      lazy (fn _ => dlsym "sqlite3_errstr" : _import int -> char ptr)

  val sqlite3_errstr =
      fn n => SMLSharp_Runtime.str_new (sqlite3_errstr n)

  val sqlite3_open_v2 =
      lazy (fn _ => dlsym "sqlite3_open_v2"
                    : _import (string, sqlite3 ref, word, unit ptr) -> int)

  val sqlite3_open_v2 =
      fn (filename, ret, {mode, threading, cache, uri}) =>
         sqlite3_open_v2
           (filename, ret, foldl Word.orb 0w0 [mode, threading, cache, uri],
            SMLSharp_Builtin.Pointer.null ()) 

  val sqlite3_close_v2 =
      lazy (fn _ => dlsym"sqlite3_close_v2"
                    : _import sqlite3 -> int);

  val sqlite3_prepare_v2 =
      lazy (fn _ => dlsym"sqlite3_prepare_v2"
                    : _import (sqlite3, string, int, sqlite3_stmt ref, unit ptr)
                              -> int)

  val sqlite3_prepare_v2 =
      fn (sqlite3, query, ret) =>
         sqlite3_prepare_v2 (sqlite3, query, String.size query, ret,
                             SMLSharp_Builtin.Pointer.null ())

  val sqlite3_step =
      lazy (fn _ => dlsym "sqlite3_step"
                    : _import sqlite3_stmt -> int)

  val sqlite3_column_type =
      lazy (fn _ => dlsym "sqlite3_column_type"
                    : _import (sqlite3_stmt, int) -> column_type)

  val sqlite3_column_bytes =
      lazy (fn _ => dlsym "sqlite3_column_bytes"
                    : _import (sqlite3_stmt, int) -> int)

  (* may return null for zero-length blob *)
  val sqlite3_column_blob =
      lazy (fn _ => dlsym "sqlite3_column_blob"
                    : _import (sqlite3_stmt, int) -> word8 ptr)

  val sqlite3_column_double =
      lazy (fn _ => dlsym "sqlite3_column_double"
                    : _import (sqlite3_stmt, int) -> real)

  val sqlite3_column_int =
      lazy (fn _ => dlsym "sqlite3_column_int"
                    : _import (sqlite3_stmt, int) -> int)

  val sqlite3_column_int64 =
      lazy (fn _ => dlsym "sqlite3_column_int64"
                    : _import (sqlite3_stmt, int) -> int64)

  val sqlite3_column_text =
      lazy (fn _ => dlsym "sqlite3_column_text"
                    : _import (sqlite3_stmt, int) -> char ptr)

  val sqlite3_finalize =
      lazy (fn _ => dlsym "sqlite3_finalize"
                    : _import sqlite3_stmt -> int);

end
