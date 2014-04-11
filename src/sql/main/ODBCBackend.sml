(**
 * ODBC support for SML#
 * @author ENDO Masanori
 * @copyright (c) 2013, Tohoku University.
 *)

structure SMLSharp_SQL_ODBCBackend :> SMLSharp_SQL_SQLBACKEND =
struct
  structure U = UNIXODBC
  structure P = Pointer

  type conn = U.SQLHDBC
  type res = U.SQLHSTMT
  type value = string

  exception Exec = SMLSharp_SQL_Errors.Exec
  exception Connect = SMLSharp_SQL_Errors.Connect
  exception Format = SMLSharp_SQL_Errors.Format

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

  fun importString (ary, len) =
      Byte.unpackString (Word8ArraySlice.slice (ary, 0, SOME len))

  fun getDiag (handleType, dbhandle) =
      let
        val state = Word8Array.array (6, 0w0)
        val nativeError = ref 0
        val message = Word8Array.array (248, 0w0)
        val len = ref 0
        val r = U.GetDiagRec () (handleType, dbhandle, 1, state,
                                 nativeError, message, 248, len)
        val (r, message) =
            if r = U.SQL_SUCCESS_WITH_INFO
            then let
                   val message = Word8Array.array (!len + 1, 0w0)
                 in
                   (U.GetDiagRec () (handleType, dbhandle, 1, state,
                                     nativeError, message, !len + 1, len),
                    message)
                 end
            else (r, message)
      in
        if r = U.SQL_SUCCESS
        then {state = importString (state, 5),
              message = importString (message, !len)}
        else raise Exec "GetDiagRec failed"
      end

  fun getDiagString name x =
      let
        val {state, message} = getDiag x
      in
        name ^ ": " ^ state ^ " - " ^ message
      end

  fun join (x, y) = x ^ ": " ^ y

  fun checkReturn name h r =
      if r = U.SQL_SUCCESS
      then ()
      else if r = U.SQL_SUCCESS_WITH_INFO
      then TextIO.output (TextIO.stdErr,
                          "ODBC Warning: " ^ getDiagString name h ^ "\n")
      else raise Exec ("ODBC Error: " ^ getDiagString name h)

  fun SQLAllocHandle (args as {1=handleType, 2=parent, ...}) =
      checkReturn "SQLAllocHandle" (handleType, parent)
                  (U.AllocHandle () args)
  fun SQLConnect (args as {1=hdbc, ...}) =
      checkReturn "SQLConnect" (U.SQL_HANDLE_DBC, hdbc)
                  (U.Connect () args)
  fun SQLSetEnvAttr (args as {1=henv, ...}) =
      checkReturn "SQLSetEnvAttr" (U.SQL_HANDLE_ENV, henv)
                  (U.SetEnvAttr () args)
  fun SQLSetStmtAttr (args as {1=hstmt, ...}) =
      checkReturn "SQLSetStmtAttr" (U.SQL_HANDLE_STMT, hstmt)
                  (U.SetStmtAttr () args)
  fun SQLExecDirect (args as {1=hstmt, ...}) =
      checkReturn "SQLExecDirect" (U.SQL_HANDLE_STMT, hstmt)
                  (U.ExecDirect () args)
  fun SQLRowCount (args as {1=hstmt, ...}) =
      checkReturn "SQLRowCount" (U.SQL_HANDLE_STMT, hstmt)
                  (U.RowCount () args)
  fun SQLNumResultCols (args as {1=hstmt, ...}) =
      checkReturn "SQLNumResultCols" (U.SQL_HANDLE_STMT, hstmt)
                  (U.NumResultCols () args)
  fun SQLSetPos (args as {1=hstmt, ...}) =
      checkReturn "SQLSetPos" (U.SQL_HANDLE_STMT, hstmt)
                  (U.SetPos () args)
  fun SQLColumns (args as {1=hstmt, ...}) =
      checkReturn "SQLColumns" (U.SQL_HANDLE_STMT, hstmt)
                  (U.Columns () args)
  fun SQLTables (args as {1=hstmt, ...}) =
      checkReturn "SQLTables" (U.SQL_HANDLE_STMT, hstmt)
                  (U.Tables () args)
  fun SQLDisconnect hdbc =
      checkReturn "SQLDisconnect" (U.SQL_HANDLE_DBC, hdbc)
                  (U.Disconnect () hdbc)
  fun SQLFreeHandle args =
      checkReturn "SQLFreeHandle" args
                  (U.FreeHandle () args)

  val AllocEnv =
      lazy (fn _ =>
               let
                 val env = ref U.NULL_HANDLE
               in
                 SQLAllocHandle (U.SQL_HANDLE_ENV, U.NULL_HANDLE, env);
                 SQLSetEnvAttr (!env, U.ATTR_ODBC_VERSION, U.OV_ODBC3, 0);
                 !env
               end)

  fun getData (res, colIndex) =
      let
        val buf = Word8Array.array (248, 0w0)
        val len = ref 0
        val r = U.GetData () (res, colIndex, U.C_CHAR, buf, 248, len)
      in
        if r = U.SQL_SUCCESS
        then if !len = U.NULL_DATA
             then NONE
             else if !len < 0
             then raise Exec "ODBC Error: SQLGetData: unknown indicator value"
             else SOME (importString (buf, !len))
        else if r = U.SQL_SUCCESS_WITH_INFO
                andalso #state (getDiag (U.SQL_HANDLE_STMT, res)) = "01004"
        then 
          let
            val len2 = !len + 1
            val buf2 = Word8Array.array (len2, 0w0)
            val r = U.GetData () (res, colIndex, U.C_CHAR, buf2, len2, len)
          in
            checkReturn "SQLGetData" (U.SQL_HANDLE_STMT, res) r;
            SOME (importString (buf, 248 - 1) ^ importString (buf2, !len))
          end
        else (checkReturn "SQLGetData" (U.SQL_HANDLE_STMT, res) r; NONE)
      end

  fun getValue (res, colIndex) =
      getData (res, Word.fromInt colIndex + 0w1)

  fun fetch res =
      let
        val r = U.Fetch () res
      in
        if r = U.SQL_NO_DATA
        then NONE
        else (checkReturn "SQLFetch" (U.SQL_HANDLE_STMT, res) r; SOME res)
      end

  fun execQuery (conn, queryString) =
      let
        val res = ref U.NULL_HANDLE
      in
        SQLAllocHandle (U.SQL_HANDLE_STMT, conn, res);
        SQLExecDirect (!res, queryString, size queryString);
        !res
      end

  fun closeConn conn =
      (SQLDisconnect conn;
       SQLFreeHandle (U.SQL_HANDLE_DBC, conn))

  fun closeRel res =
      SQLFreeHandle (U.SQL_HANDLE_STMT, res)

  fun translateType dbTypeName =
      case dbTypeName of
        "0" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_UNKNOWN_TYPE"
      | "1" => SMLSharp_SQL_BackendTy.STRING (* SQL_CHAR *)
      | "2" => SMLSharp_SQL_BackendTy.DECIMAL (* SQL_NUMERIC *)
      | "3" => SMLSharp_SQL_BackendTy.DECIMAL (* SQL_DECIMAL *)
      | "4" => SMLSharp_SQL_BackendTy.INT (* SQL_INTEGER *)
      | "5" => SMLSharp_SQL_BackendTy.INT (* SQL_SMALLINT; should be Int16 *)
      | "6" => SMLSharp_SQL_BackendTy.FLOAT (* SQL_FLOAT *)
      | "7" => SMLSharp_SQL_BackendTy.REAL32 (* SQL_REAL *)
      | "8" => SMLSharp_SQL_BackendTy.REAL (* SQL_DOUBLE *)
      | "9" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_DATE"
      | "10" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_TIME"
      | "11" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_TIMESTAMP"
      | "12" => SMLSharp_SQL_BackendTy.STRING (* SQL_VARCHAR *)
      | "91" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_TYPE_DATE"
      | "92" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_TYPE_TIME"
      | "93" => SMLSharp_SQL_BackendTy.TIMESTAMP (* SQL_TYPE_TIMESTAMP *)
      | "-1" => SMLSharp_SQL_BackendTy.STRING (* SQL_LONGVARCHAR *)
      | "-2" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_BINARY"
      | "-3" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_VARBINARY"
      | "-4" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_LONGVARBINARY"
      | "-5" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_BIGINT"
      | "-6" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_TINYINT"
      | "-7" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_BIT"
      | "-11" => SMLSharp_SQL_BackendTy.UNSUPPORTED "SQL_GUID"
      (* FIXME: The followings seem to be MS SQLServer specific. *)
      | "-9" => SMLSharp_SQL_BackendTy.STRING (* nvarchar *)
      | _ => SMLSharp_SQL_BackendTy.UNSUPPORTED dbTypeName

  fun getColumnInfo res =
      case fetch res of
        NONE => nil
      | SOME res =>
        let
          val colname = case getData (res, U.COLUMN_NAME) of
                          SOME s => s
                        | NONE => raise Format
          val ty = case getData (res, U.DATA_TYPE) of
                     SOME s => translateType s
                   | NONE => raise Format
          val nullable = case getData (res, U.NULLABLE) of
                           SOME "0" => false
                         | SOME "1" => true
                         | _ => raise Format
        in
          (* Fetchする順番に注意。行の順番が保存されるようにリストを作る。 *)
          {colname = colname,
           ty = ty,
           nullable = nullable} :: getColumnInfo res
        end

  fun escape s =
      String.translate (fn #"%" => "\\%"
                         | #"_" => "\\_"
                         | #"\\" => "\\\\"
                         | c => str c)
                       s

  fun getTableInfo dbc table =
      let
        val res = ref U.NULL_HANDLE
        val _ = SQLAllocHandle (U.SQL_HANDLE_STMT, dbc, res)
        val tbl = escape table
        val _ = SQLColumns (!res, "", 0, "", 0, tbl, size tbl, "%", 1)
        val colInfo = getColumnInfo (!res)
        val _ = closeRel (!res)
      in
        (table, colInfo)
      end

  fun getTableName res =
      case fetch res of
        NONE => nil
      | SOME res =>
        (* Fetchする順番に注意。行の順番が保存されるようにリストを作る。 *)
        case getData (res, 0w3) of
          SOME s => s :: getTableName res
        | NONE => raise Format

  fun getDatabaseSchema dbc =
      let
        val res = ref U.NULL_HANDLE
        val _ = SQLAllocHandle (U.SQL_HANDLE_STMT, dbc, res)
        val _ = SQLTables (!res, "", 0, "", 0, "%", 1, "TABLE,VIEW", 10)
        val tables = getTableName (!res)
        val _ = closeRel (!res)
      in
        map (getTableInfo dbc) tables
      end

  (* [databasename] [username] [password] *)
  fun connect connInfo =
      let
        val conn = ref U.NULL_HANDLE
        val _ = SQLAllocHandle (U.SQL_HANDLE_DBC, AllocEnv (), conn)
        val (dsn, username, password) =
            case String.fields Char.isSpace connInfo of
              dsn :: usrname :: pass :: nil => (dsn, usrname, pass)
            | _ => raise Connect "syntax error in server string"
        val _ = SQLConnect (!conn,
                            dsn, size dsn,
                            username, size username,
                            password, size password)
      in
        !conn
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
  (* 1 = true, 0 = false *)
  fun boolValue x = case x of "1" => SOME true
                            | "0" => SOME false
                            | _ => raise Format

end
