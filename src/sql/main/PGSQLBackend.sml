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
  type res = {result: PGSQL.result, rowIndex: int, numRows: int}
  type sqltype = string
  type value = string

  exception Exec = SMLSharp_SQL_Errors.Exec
  exception Connect = SMLSharp_SQL_Errors.Connect
  exception Format = SMLSharp_SQL_Errors.Format

  fun execQuery (conn, queryString) =
      let
        val r = PGSQL.PQexec () (conn, queryString)
        val s = if r = _NULL
                then PGSQL.PGRES_FATAL_ERROR
                else PGSQL.PQresultStatus () r
      in
        if s = PGSQL.PGRES_COMMAND_OK orelse s = PGSQL.PGRES_TUPLES_OK
        then ()
        else raise Exec (if r = _NULL then "NULL"
                         else (PGSQL.PQclear () r;
                               PGSQL.getErrorMessage conn));
        {result = r, rowIndex = ~1, numRows = PGSQL.PQntuples () r}
      end

  fun fetch (r as {result, rowIndex, numRows}:res) =
      if rowIndex + 1 < numRows
      then SOME (r # {rowIndex = rowIndex + 1})
      else NONE

  fun closeConn conn = (PGSQL.PQfinish () conn; ())

  fun closeRel ({result,...}:res) = (PGSQL.PQclear () result; ())

  fun connect connInfo =
      let
        val conn = PGSQL.PQconnectdb () connInfo
      in
        if conn = _NULL orelse PGSQL.PQstatus () conn <> PGSQL.CONNECTION_OK
        then raise Connect (if conn = _NULL then "NULL"
                            else PGSQL.getErrorMessage conn)
        else conn
      end

  fun getValue ({result, rowIndex, ...}:res, colIndex:int) =
      if PGSQL.PQgetisnull () (result, rowIndex, colIndex)
      then NONE
      else
        let
          val p = PGSQL.PQgetvalue () (result, rowIndex, colIndex)
          val len = PGSQL.PQgetlength () (result, rowIndex, colIndex)
        in
          SOME (Byte.bytesToString (Pointer.importBytes (p, len)))
        end

  fun intValue x = Int.fromString x
  fun intInfValue x = IntInf.fromString x
  fun wordValue x = StringCvt.scanString (Word.scan StringCvt.DEC) x
  fun realValue x = Real.fromString x
  fun stringValue (x:string) = SOME x
  fun charValue x = SOME (String.sub (x, 0)) handle Subscript => NONE
  fun timestampValue x = SOME (SMLSharp_SQL_TimeStamp.fromString x)
  fun decimalValue x = SOME (SMLSharp_SQL_Decimal.fromString x)
  fun floatValue x = SOME (SMLSharp_SQL_Float.fromString x)

  (* The boolean output conversion function of PostgreSQL-9.0.3, boolout,
   * returns "t" or "f".
   * The boolean input conversion function of PostgreSQL-9.0.3, boolin,
   * accepts prefixes of "true"/"false", "TRUE"/"FALSE", "yes"/"no",
   * "YES"/"NO" and complete "ON"/"OFF", "1"/"0".
   * We respected the former, and made readBool accept only "t" and "f".
   * See postgresql-version/src/backend/utils/adt/bool.c.
   *)

  fun boolValue x = case x of "t" => SOME true | "f" => SOME false | _ => NONE

  local

    fun valof (SOME x) = x
      | valof NONE = raise Format

    fun getString x = valof (stringValue (valof (getValue x)))
    fun getBool x = valof (boolValue (valof (getValue x)))

    fun translateType dbTypeName =
        case dbTypeName of
          "int4" => SMLSharp_SQL_BackendTy.INT
        | "float4" => SMLSharp_SQL_BackendTy.REAL32
        | "float8" => SMLSharp_SQL_BackendTy.REAL
        | "text" => SMLSharp_SQL_BackendTy.STRING
        | "varchar" => SMLSharp_SQL_BackendTy.STRING
        | "bool" => SMLSharp_SQL_BackendTy.BOOL
        | "timestamp" => SMLSharp_SQL_BackendTy.TIMESTAMP
        | _ => SMLSharp_SQL_BackendTy.UNSUPPORTED dbTypeName

    fun evalQuery (query, fetchFn, conn) =
        let
          val r = execQuery (conn, query)
          val tuples =
              List.tabulate (#numRows r, fn i => fetchFn (r # {rowIndex=i}))
              handle e => (closeRel r; raise e)
        in
            closeRel r;
            tuples
        end

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
          fun fetchFn res =
              {colname = getString (res, 0),
               nullable = not (getBool (res, 1)),
               ty = translateType (getString (res, 2))}
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
                    \AND pg_class.relkind = 'r' or pg_class.relkind = 'v'\
                    \ORDER BY pg_class.relname, pg_class.relkind"
        fun fetchFn res =
            {relname = getString (res, 0),
             oid = getString (res, 1)}
        val relOIDList = evalQuery (query, fetchFn, conn)
      in
        map (getTableSchema conn) relOIDList
      end

  end (* local *)

end
