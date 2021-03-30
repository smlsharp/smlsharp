(**
 * SQLite support for SML#
 * @author UENO Katsuhiro
 * @author Rodolphe Bertolini
 * @copyright (C) 2021 SML# Development Team.
 *)
structure SMLSharp_SQL_SQLite3Backend : SMLSharp_SQL_SQLBACKEND =
struct

  structure SQLite = SMLSharp_SQL_SQLite3
  structure Numeric = SMLSharp_SQL_Numeric

  type conn = SQLite.sqlite3
  type res = SQLite.sqlite3_stmt
  type value = res * int
  type server_desc = SQLite.flags * string

  exception Exec = SMLSharp_SQL_Errors.Exec
  exception Connect = SMLSharp_SQL_Errors.Connect
  exception Format = SMLSharp_SQL_Errors.Format

  fun connect (flags, filename) =
      let
        val r = SQLite.new_sqlite3 ()
        val e = SQLite.sqlite3_open_v2 (filename, r, flags)
      in
        if e = SQLite.SQLITE_OK
        then !r
        else raise Connect (SQLite.sqlite3_errstr e)
      end

  fun closeConn conn =
      let
        val e = SQLite.sqlite3_close_v2 conn
      in
        if e = SQLite.SQLITE_OK
        then ()
        else raise Exec (SQLite.sqlite3_errstr e)
      end

  fun execQuery (conn, queryString) =
      let
        val r = SQLite.new_sqlite3_stmt ()
        val e = SQLite.sqlite3_prepare_v2 (conn, queryString, r)
      in
        if e = SQLite.SQLITE_OK
        then !r
        else raise Exec (SQLite.sqlite3_errstr e)
      end

  fun closeRes res =
      let
        val e = SQLite.sqlite3_finalize res
      in
        if e = SQLite.SQLITE_OK
        then ()
        else raise Exec (SQLite.sqlite3_errstr e)
      end

  fun fetch res =
      let
        val e = SQLite.sqlite3_step res
      in
        if e = SQLite.SQLITE_ROW
        then true
        else if e = SQLite.SQLITE_DONE
        then false
        else raise Exec (SQLite.sqlite3_errstr e)
      end

  fun getValue (res, n) =
      if SQLite.sqlite3_column_type (res, n) = SQLite.SQLITE_NULL
      then NONE
      else SOME (res, n)

  fun readText (res, n) =
      let
        val p = SQLite.sqlite3_column_text (res, n)
        val n = SQLite.sqlite3_column_bytes (res, n)
      in
        Pointer.importString' (p, n)
      end

  fun intValue (res, n) =
      SOME (SQLite.sqlite3_column_int (res, n))

  fun intInfValue (res, n) =
      SOME (Int64.toLarge (SQLite.sqlite3_column_int64 (res, n)))

  fun realValue (res, n) =
      SOME (SQLite.sqlite3_column_double (res, n))

  fun stringValue (res, n) =
      SOME (readText (res, n))

  fun numericValue (res, n) =
      SOME (Numeric.fromLargeInt
              (Int64.toLarge
                 (SQLite.sqlite3_column_int64 (res, n))))

  fun wordValue _ = NONE
  fun real32Value _ = NONE
  fun charValue _ = NONE
  fun boolValue _ = NONE
  fun timestampValue _ = NONE
  fun floatValue _ = NONE

  fun getTableNames conn =
      let
        val query = "SELECT name FROM SQLITE_MASTER \
                    \WHERE type IN ('table', 'view') \
                    \UNION ALL \
                    \SELECT name FROM SQLITE_TEMP_MASTER \
                    \WHERE type IN ('table', 'view') \
                    \ORDER BY name DESC"
        val s = execQuery (conn, query)
        fun loop l =
            if fetch s
            then loop (readText (s, 0) :: l)
            else l
        val tableNames = loop nil
        val _ = closeRes s
      in
        tableNames
      end

  fun schemaColumn {name, ty, notnull, pk} =
      let
        val s = CharVector.map Char.toLower ty
      in
        (name,
         {ty =
            if String.isSubstring "int" s then SMLSharp_SQL_BackendTy.INT
            else if String.isSubstring "char" s orelse
                    String.isSubstring "clob" s orelse
                    String.isSubstring "text" s
            then SMLSharp_SQL_BackendTy.STRING
            else if String.isSubstring "blob" s orelse s = ""
            then SMLSharp_SQL_BackendTy.UNSUPPORTED ty
            else if String.isSubstring "real" s orelse
                    String.isSubstring "floa" s orelse
                    String.isSubstring "doub" s
            then SMLSharp_SQL_BackendTy.REAL
            else SMLSharp_SQL_BackendTy.NUMERIC,
          nullable = notnull = 0 andalso pk = 0})
      end

  fun getTableInfo conn name =
      let
        val query = "PRAGMA main.table_info (" ^ name ^ ")"
        val s = execQuery (conn, query)
        fun loop l =
            if fetch s
            then loop (schemaColumn
                         {name = readText (s, 1),
                          ty = readText (s, 2),
                          notnull = SQLite.sqlite3_column_int (s, 3),
                          pk = SQLite.sqlite3_column_int (s, 5)}
                       :: l)
            else l
        val columnsRev = loop nil
        val _ = closeRes s
      in
        rev columnsRev
      end

  fun getDatabaseSchema conn =
        map (fn x => (x, getTableInfo conn x)) (getTableNames conn)

  fun columnTypeName ty =
      case ty of
        SMLSharp_SQL_BackendTy.INT => "INT"
      | SMLSharp_SQL_BackendTy.INTINF => "INT"
      | SMLSharp_SQL_BackendTy.WORD => "INT"
      | SMLSharp_SQL_BackendTy.CHAR => "TEXT"
      | SMLSharp_SQL_BackendTy.STRING => "TEXT"
      | SMLSharp_SQL_BackendTy.REAL => "DOUBLE"
      | SMLSharp_SQL_BackendTy.REAL32 => "FLOAT"
      | SMLSharp_SQL_BackendTy.BOOL => "BOOLEAN"
      | SMLSharp_SQL_BackendTy.TIMESTAMP => "DATETIME"
      | SMLSharp_SQL_BackendTy.NUMERIC => "NUMERIC"
      | SMLSharp_SQL_BackendTy.UNSUPPORTED s => s

end
