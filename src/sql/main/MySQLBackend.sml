(**
 * MySQL support for SML#
 * @author SATO Hiroyuki
 * @copyright (C) 2021 SML# Development Team.
 *)

structure SMLSharp_SQL_MySQLBackend : SMLSharp_SQL_SQLBACKEND =
struct

  structure MySQL = SMLSharp_SQL_MySQL
  structure KeyValuePair = SMLSharp_SQL_KeyValuePair

  type conn = MySQL.MYSQL
  type res = {result: MySQL.MYSQL_RES, rowIndex: word64 ref, numRows: word64}
  type value = string
  type server_desc = string

  exception Exec = SMLSharp_SQL_Errors.Exec
  exception Connect = SMLSharp_SQL_Errors.Connect
  exception Format = SMLSharp_SQL_Errors.Format

  fun execQuery (mysql, queryString) =
      let
        val r = MySQL.mysql_query () (mysql, queryString)
        val _ =
            if r = 0
            then ()
            else raise Exec (Int.toString (MySQL.mysql_errno () mysql)
                             ^ ": " ^ SMLSharp_Runtime.str_new
                                        (MySQL.mysql_error () mysql) ^"\n")
        val result = MySQL.mysql_store_result () mysql
      in
        {result = result,
         rowIndex = ref 0w0,
         numRows = MySQL.mysql_num_rows () result}
      end

  fun fetch (r as {result, rowIndex, numRows}:res) =
      if !rowIndex < numRows
      then (rowIndex := !rowIndex + 0w1; true)
      else false

  fun closeConn conn = (MySQL.mysql_close () conn; ())

  fun closeRes ({result,...}:res) = (MySQL.mysql_free_result () result; ())

  fun getValue ({result, rowIndex = ref rowIndex, ...}:res, colIndex:int) =
      let
        val _ = MySQL.mysql_data_seek () (result, rowIndex - 0w1)
        val row = MySQL.mysql_fetch_row () result
        val value = SMLSharp_Builtin.Pointer.deref
                      (SMLSharp_Builtin.Pointer.advance (row, colIndex))
      in
        if value = SMLSharp_Builtin.Pointer.null ()
        then NONE
        else SOME (SMLSharp_Runtime.str_new
                     (SMLSharp_Builtin.Pointer.fromUnitPtr value))
      end

  fun intValue x = Int.fromString x
  fun intInfValue x = IntInf.fromString x
  fun wordValue x = StringCvt.scanString (Word.scan StringCvt.DEC) x
  fun realValue x = Real.fromString x
  fun real32Value x = Real32.fromString x
  fun stringValue (x:string) = SOME x
  fun charValue x = SOME (String.sub (x, 0)) handle Subscript => NONE
  fun boolValue x = (print x; raise Fail "MySQL does'nt support boolean")
  fun timestampValue x = SOME (SMLSharp_SQL_TimeStamp.fromString x)
  fun numericValue x = SMLSharp_SQL_Numeric.fromString x

  fun columnTypeName ty =
      case ty of
        SMLSharp_SQL_BackendTy.INT => "INT"
      | SMLSharp_SQL_BackendTy.INTINF => ""
      | SMLSharp_SQL_BackendTy.WORD => ""
      | SMLSharp_SQL_BackendTy.CHAR => ""
      | SMLSharp_SQL_BackendTy.STRING => "TEXT"
      | SMLSharp_SQL_BackendTy.REAL => "FLOAT"
      | SMLSharp_SQL_BackendTy.REAL32 => "DOUBLE PRECISION"
      | SMLSharp_SQL_BackendTy.BOOL => ""
      | SMLSharp_SQL_BackendTy.TIMESTAMP => ""
      | SMLSharp_SQL_BackendTy.NUMERIC => "NUMERIC"
      | SMLSharp_SQL_BackendTy.UNSUPPORTED s => s

  local

    fun valof (SOME x) = x
      | valof NONE = raise Format

    fun getString x = valof (stringValue (valof (getValue x)))
    fun getBool x =
        case getValue x of SOME "NO" => false
                        | SOME "YES" => true
                        | _ => raise Format

    (* TODO: how to deal with time, date, binary,blob... *)
    fun translateType dbTypeName =
        case dbTypeName of
          "tinyint" => SMLSharp_SQL_BackendTy.INT
        | "smallint" => SMLSharp_SQL_BackendTy.INT
        | "mediumint" => SMLSharp_SQL_BackendTy.INT
        | "int" => SMLSharp_SQL_BackendTy.INT
        | "float" => SMLSharp_SQL_BackendTy.REAL32
        | "double" => SMLSharp_SQL_BackendTy.REAL
        | "varchar" => SMLSharp_SQL_BackendTy.STRING
        | "tinytext" => SMLSharp_SQL_BackendTy.STRING
        | "text" => SMLSharp_SQL_BackendTy.STRING
(*
        | "bigint" => NONE
        | "date" => NONE
        | "datetime" => NONE
        | "timestamp" => NONE
        | "time" => NONE
        | "year2" => NONE
        | "year4" => NONE
        | "char" => NONE
        | "binary" => NONE
        | "varbinary" => NONE
        | "mediumtext" => NONE
        | "longtext" => NONE
        | "tinyblob" => NONE
        | "blob" => NONE
        | "mediumblob" =>NONE
        | "longblob" => NONE
        | "enum" => NONE
        | "set" => NONE
        | "bool" => NONE
*)
        | _ => SMLSharp_SQL_BackendTy.UNSUPPORTED dbTypeName

    fun evalQuery (query, fetchFn, conn) =
        let
          val r = execQuery (conn, query)
          fun loop l r = if fetch r then loop (fetchFn r :: l) r else l
          val tuples = loop nil r handle e => (closeRes r; raise e)
        in
          closeRes r;
          rev tuples
        end

    fun getTableSchema conn {tabname, dbname} =
        let
          val query = "SELECT column_name,is_nullable,data_type \
                      \FROM information_schema.schemata, \
                      \information_schema.columns \
                      \WHERE columns.table_name = '" ^ tabname ^ "' \
                      \AND schemata.schema_name = '" ^ dbname ^ "' \
                      \ORDER BY columns.column_name"
          fun fetchFn res =
              (getString (res, 0),
               {nullable = getBool (res, 1),
                ty = translateType (getString (res, 2))})
        in
          (tabname, evalQuery (query, fetchFn, conn))
        end
  in

  fun getDatabaseSchema conn =
      let
        val query = "SELECT tables.table_name, tables.table_schema \
                    \FROM information_schema.tables"
        fun fetchFn res =
            {tabname = getString (res, 0),
             dbname = getString (res, 1)}
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
              | NONE => SMLSharp_Builtin.Pointer.null () : unit ptr
          val flags = findInt (pairs, "flags", 0)
        in
          MySQL.mysql_real_connect
            () (mysql, host, user, password, dbname, port, unix_socket, flags)
        end

  in

  fun connect connInfo =
      let
        val mysql = MySQL.mysql_init () (SMLSharp_Builtin.Pointer.null ())
      in
        if mysql = SMLSharp_Builtin.Pointer.null ()
        then raise Connect "mysql_init failed"
        else
          let
            val conn = real_connect mysql connInfo
          in
            if conn = SMLSharp_Builtin.Pointer.null ()
            then raise Connect (SMLSharp_Runtime.str_new
                                  (MySQL.mysql_error () mysql)
                                  ^ " (errno:"
                                  ^ Int.toString (MySQL.mysql_errno () mysql)
                                  ^ ")")
            else conn
          end
      end

  end (* local *)

end
