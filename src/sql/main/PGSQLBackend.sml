(**
 * PostgreSQL support for SML#
 * @author SATO Hiroyuki
 * @author UENO Katsuhiro
 * @copyright (c) 2010, Tohoku University.
 *)

structure SMLSharp_SQL_PGSQLBackend :> SMLSharp_SQL_SQLBACKEND =
struct

  structure PGSQL = SMLSharp_SQL_PGSQL

  type conn = PGSQL.conn
  type res = PGSQL.result
  type sqltype = string

  exception Exec of string
  exception Connect of string
  exception Format

  fun eof (result,rowIndex) =
      rowIndex >= PGSQL.PQntuples () result

  fun execQuery (conn, queryString) =
      let
        val r = PGSQL.PQexec () (conn, queryString)
        val s = if r = _NULL
                then PGSQL.PGRES_FATAL_ERROR
                else PGSQL.PQresultStatus () r
      in
        if s = PGSQL.PGRES_COMMAND_OK orelse s = PGSQL.PGRES_TUPLES_OK
        then r
        else raise Exec (if r = _NULL then "NULL"
                         else (PGSQL.PQclear () r;
                               PGSQL.getErrorMessage conn))
      end

  fun closeConn conn = (PGSQL.PQfinish () conn; ())

  fun closeRel r = (PGSQL.PQclear () r; ())

  fun numOfRows r = PGSQL.PQntuples () r

  fun connect connInfo =
      let
        val conn = PGSQL.PQconnectdb () connInfo
      in
        if conn = _NULL orelse PGSQL.PQstatus () conn <> PGSQL.CONNECTION_OK
        then raise Connect (if conn = _NULL then "NULL"
                            else PGSQL.getErrorMessage conn)
        else conn
      end

  fun getValue convFn (result:unit ptr, rowIndex:int, colIndex:int) =
      if PGSQL.PQgetisnull () (result, rowIndex, colIndex)
      then NONE
      else
        let
          val p = PGSQL.PQgetvalue () (result, rowIndex, colIndex)
          val len = PGSQL.PQgetlength () (result, rowIndex, colIndex)
          val s = Byte.bytesToString (Pointer.importBytes (p, len))
        in
          case convFn s of
            SOME x => SOME x
          | NONE => raise Format
        end

  fun readInt x = Int.fromString x
  fun readWord x = StringCvt.scanString (Word.scan StringCvt.DEC) x
  fun readReal x = Real.fromString x
  fun readString (x:string) = SOME x
  fun readChar x = SOME (String.sub (x, 0)) handle Subscript => NONE

  (* The boolean output conversion function of PostgreSQL-9.0.3, boolout,
   * returns "t" or "f".
   * The boolean input conversion function of PostgreSQL-9.0.3, boolin,
   * accepts prefixes of "true"/"false", "TRUE"/"FALSE", "yes"/"no",
   * "YES"/"NO" and complete "ON"/"OFF", "1"/"0".
   * We respected the former, and made readBool accept only "t" and "f".
   * See postgresql-version/src/backend/utils/adt/bool.c.
   *)

  fun readBool x = case x of "t" => SOME true | "f" => SOME false
                           | _ => raise Format

  fun getInt x = getValue readInt x
  fun getWord x = getValue readWord x
  fun getReal x = getValue readReal x
  fun getString x = getValue readString x
  fun getChar x = getValue readChar x
  fun getBool x = getValue readBool x

  local

    fun evalQuery (query, fetchFn, conn) =
        let
          val r = execQuery (conn, query)
          val tuples =
              List.tabulate (numOfRows r,
                          fn i => fetchFn i r)
              handle e => (closeRel r; raise e)
        in
            closeRel r; tuples
        end

    fun nonnull (SOME x) = x
      | nonnull NONE = raise Format

    fun getTableSchema conn {relname, oid} =
        let
          val query = "SELECT pg_attribute.attname, \
                      \pg_attribute.attnotnull,pg_type.typname \
                      \FROM pg_class, pg_attribute, pg_type \
                      \WHERE pg_class.oid = " ^ oid ^ " \
                      \AND pg_class.oid = pg_attribute.attrelid \
                      \AND pg_attribute.attnum > 0 \
                      \AND pg_attribute.atttypid = pg_type.oid \
                      \ORDER BY pg_attribute.attname"
          fun fetchFn r conn =
              {colname = nonnull (getString (conn, r, 0)),
               isnull = not (nonnull (getBool (conn, r, 1)))
               handle Option => raise Format,
               typename = nonnull (getString (conn, r, 2))}
        in
          (relname, evalQuery (query, fetchFn, conn))
        end
  in

  fun getDatabaseSchema conn =
      let
        val query = "SELECT pg_class.relname, pg_class.oid \
                    \FROM pg_namespace, pg_class \
                    \WHERE pg_namespace.oid = pg_class.relnamespace \
                    \AND pg_namespace.nspname = 'public' \
                    \AND pg_class.relkind = 'r' \
                    \ORDER BY pg_class.relname"
        fun fetchFn r conn =
            {relname = nonnull (getString (conn, r, 0)),
             oid = nonnull (getString (conn, r, 1))}
        val relOIDList = evalQuery (query, fetchFn, conn)
      in
        map (getTableSchema conn) relOIDList
      end

  end (* local *)

  fun translateType dbTypeName =
      case dbTypeName of
        "int4" => SOME "int"
      | "float4" => SOME "float"
      | "float8" => SOME "real"
      | "text" => SOME "string"
      | "varchar" => SOME "string"
      | "bool" => SOME "bool"
      | _ => NONE

end
