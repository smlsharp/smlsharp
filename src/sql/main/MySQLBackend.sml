(**
 * MySQL support for SML#
 * @author SATO Hiroyuki
 * @copyright (c) 2010, Tohoku University.
 *)

structure SMLSharp_SQL_MySQLBackend :> SMLSharp_SQL_SQLBACKEND =
struct

  structure MySQL = SMLSharp_SQL_MySQL
  structure KeyValuePair = SMLSharp_SQL_KeyValuePair

  type conn = MySQL.MYSQL
  type res = MySQL.MYSQL_RES
  type sqltype = string

  exception Exec of string
  exception Connect of string
  exception Format

  fun eof (r,rowIndex)=
      rowIndex >= (MySQL.mysql_num_rows () r)

  fun execQuery (mysql, queryString) =
      let
        val r = MySQL.mysql_query () (mysql, queryString)
      in
        if r = 0
        then MySQL.mysql_store_result () mysql
        else raise Exec (Int.toString (MySQL.mysql_errno () mysql)
                         ^ ": " ^ SMLSharpRuntime.str_new
                                    (MySQL.mysql_error () mysql) ^"\n")
      end

  fun closeConn conn = (MySQL.mysql_close () conn; ())

  fun closeRel r = (MySQL.mysql_free_result () r; ())

  fun numOfRows r = MySQL.mysql_num_rows () r

  fun getValue convFn (result, rowIndex:int, colIndex:int) =
      let
        val _ = MySQL.mysql_data_seek () (result,rowIndex)
        val row = MySQL.mysql_fetch_row () result
        val value = SMLSharp.Pointer.deref_ptr
                      (SMLSharp.Pointer.advance (row, colIndex))
      in
        if value = _NULL
        then NONE
        else
          case convFn (SMLSharpRuntime.str_new
                         (SMLSharp.Pointer.fromUnitPtr value)) of
            SOME x => SOME x
          | NONE => raise Format
      end

  fun readInt x = Int.fromString x
  fun readWord x = StringCvt.scanString (Word.scan StringCvt.DEC) x
  fun readReal x = Real.fromString x
  fun readString (x:string) = SOME x
  fun readChar x = SOME (String.sub (x, 0)) handle Subscript => NONE
  fun readBool x = (print x; raise Exec "MySQL does'nt support boolean")

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
              List.tabulate (numOfRows r, fn i => fetchFn i r)
              handle e => (closeRel r; raise e)
        in
          closeRel r; tuples
        end

    fun readIsnull x =
        case x of "NO" => false
                | "YES" => true
                | _ => raise Format

    fun nonnull (SOME x) = x
      | nonnull NONE = raise Format

    fun getTableSchema conn {tabname, dbname} =
        let
          val query = "SELECT column_name,is_nullable,data_type \
                      \FROM information_schema.schemata, \
                      \information_schema.columns \
                      \WHERE columns.table_name = '" ^ tabname ^ "' \
                      \AND schemata.schema_name = '" ^ dbname ^ "' \
                      \ORDER BY columns.column_name"
          fun fetchFn r conn =
              {colname = nonnull (getString (conn, r, 0)),
               isnull = readIsnull (valOf (getString (conn, r, 1)))
               handle Option => raise Format,
               typename = nonnull (getString (conn, r, 2))}
        in
          (tabname, evalQuery (query, fetchFn, conn))
        end
  in

  fun getDatabaseSchema conn =
      let
        val query = "SELECT tables.table_name, tables.table_schema \
                    \FROM information_schema.tables"
        fun fetchFn r conn = {tabname = nonnull (getString (conn, r, 0)),
                              dbname = nonnull (getString (conn, r, 1))}
        val tableDBList = evalQuery (query, fetchFn, conn)
      in
        map (getTableSchema conn) tableDBList
      end

  end (* local *)

  local

    fun find (pairs, key, default) =
        case KeyValuePair.find (pairs, key) of
          SOME value => value
        | NONE => default

    fun findInt (pairs, key, default) =
        case KeyValuePair.find (pairs, key) of
          NONE => default
        | SOME value =>
          case Int.fromString value of
            SOME x => x
          | NONE => raise Connect (key ^ " requires integer")

    (*
     * Avaliable keys for connection information:
     *   key          type      description
     *  --------------------------------------------------------------
     *   host         string    hostname of MySQL server
     *   port         int       port number of MySQL server
     *   user         string    user name of the connection
     *   password     string    password to connect the server
     *   dbname       string    database name (required)
     *   unix_socket  string    filename of UNIX socket to be connected
     *   flags        int       flags for protocol
     *)
    val availableKeys =
        ["host", "port", "user", "password", "dbname", "unix_socket", "flags"]

    fun real_connect mysql connInfo =
        let
          val pairs = KeyValuePair.parse connInfo
              handle KeyValuePair.ParseError =>
                     raise Connect "syntax error in server string"
          val _ =
              case KeyValuePair.findExcept availableKeys pairs of
                SOME (key, _) => raise Connect ("invalid keyword: " ^ key)
              | NONE => ()

          val host = find (pairs, "host", "localhost")
          val user = find (pairs, "user", "")
          val password = find (pairs, "password", "")
          val dbname =
              case KeyValuePair.find (pairs, "dbname") of
                SOME x => x
              | NONE => raise Connect "dbname is required"
          val port = findInt (pairs, "port", 0)
          val unix_socket =
              case KeyValuePair.find (pairs, "unix_socket") of
                SOME x => raise Connect "unix_socket is not supported"
              | NONE => _NULL
          val flags = findInt (pairs, "flags", 0)
        in
          MySQL.mysql_real_connect
            () (mysql, host, user, password, dbname, port, unix_socket, flags)
        end

  in

  fun connect connInfo =
      let
        val mysql = MySQL.mysql_init () _NULL
      in
        if mysql = _NULL then raise Connect "mysql_init failed"
        else
          let
            val conn = real_connect mysql connInfo
          in
            if conn = _NULL
            then raise Connect (SMLSharpRuntime.str_new
                                  (MySQL.mysql_error () mysql)
                                  ^ " (errno:"
                                  ^ Int.toString (MySQL.mysql_errno () mysql)
                                  ^ ")")
            else conn
          end
      end

  end (* local *)

  (* TODO: how to deal with time, date, binary,blob... *)
  fun translateType dbTypeName =
      case dbTypeName of
        "tinyint" => SOME "int"
      | "smallint" => SOME "int"
      | "mediumint" => SOME "int"
      | "int" => SOME "int"
      | "bigint" => NONE
      | "float" => SOME "real"
      | "double" => SOME "real"
      | "date" => NONE
      | "datetime" => NONE
      | "timestamp" => NONE
      | "time" => NONE
      | "year2" => NONE
      | "year4" => NONE
      | "varchar" => SOME "string"
      | "char" => NONE
      | "binary" => NONE
      | "varbinary" => NONE
      | "tinytext" => SOME "string"
      | "text" => SOME "string"
      | "mediumtext" => NONE
      | "longtext" => NONE
      | "tinyblob" => NONE
      | "blob" => NONE
      | "mediumblob" =>NONE
      | "longblob" => NONE
      | "enum" => NONE
      | "set" => NONE
      | "bool" => NONE
      | _ => NONE

end
