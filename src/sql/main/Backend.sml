(**
 * SQL backends
 * @author UENO Katsuhiro
 * @copyright (c) 2013, Tohoku University.
 *)

structure SQLBackendTypes =
struct

  type schema_column =
       {colname: string, ty: SMLSharp_SQL_BackendTy.ty, nullable: bool}
  type schema_table = string * schema_column list
  type schema = schema_table list

  datatype res_impl =
       R of {closeRel : unit -> unit,
             fetch : unit -> res_impl option,
             getInt : int -> int option,
             getIntInf : int -> IntInf.int option,
             getWord : int -> word option,
             getReal : int -> real option,
             getString : int -> string option,
             getChar : int -> char option,
             getBool : int -> bool option,
             getTimestamp : int -> SMLSharp_SQL_TimeStamp.timestamp option,
             getDecimal : int -> SMLSharp_SQL_Decimal.decimal option,
             getFloat : int -> SMLSharp_SQL_Float.float option}
         
  type conn_impl =
       {closeConn : unit -> unit,
        getDatabaseSchema : unit -> schema,
        execQuery : string -> res_impl}

  type server_impl =
       {connect : unit -> conn_impl}

  datatype backend = BACKEND of server_impl

end

functor Backend(B : SMLSharp_SQL_SQLBACKEND) =
struct
  local

    fun getValue convFn x =
        case B.getValue x of
          NONE => NONE
        | SOME x =>
          case convFn x of
            NONE => raise SMLSharp_SQL_Errors.Format
          | SOME x => SOME x

    fun resImpl res =
        SQLBackendTypes.R {
          closeRel = fn () => B.closeRel res,
          fetch = fn () => Option.map resImpl (B.fetch res),
          getInt = fn i => getValue B.intValue (res, i),
          getIntInf = fn i => getValue B.intInfValue (res, i),
          getWord = fn i => getValue B.wordValue (res, i),
          getReal = fn i => getValue B.realValue (res, i),
          getString = fn i => getValue B.stringValue (res, i),
          getChar = fn i => getValue B.charValue (res, i),
          getBool = fn i => getValue B.boolValue (res, i),
          getTimestamp = fn i => getValue B.timestampValue (res, i),
          getDecimal = fn i => getValue B.decimalValue (res, i),
          getFloat = fn i => getValue B.floatValue (res, i)
        }

    fun execQuery conn query =
        resImpl (B.execQuery (conn, query))

    fun connect serverDesc () =
        let
          val conn = B.connect serverDesc
        in
          {
            closeConn = fn () => B.closeConn conn,
            getDatabaseSchema = fn () => B.getDatabaseSchema conn,
            execQuery = execQuery conn
          }
        end

    fun prepare serverDesc =
        {
          connect = connect serverDesc
        }

  in

  fun backend serverDesc =
      SQLBackendTypes.BACKEND (prepare serverDesc)

  end (* local *)
end

structure SMLSharp_SQL_Backend =
struct

  open SQLBackendTypes

  structure PGSQL = Backend(SMLSharp_SQL_PGSQLBackend)
  structure MySQL = Backend(SMLSharp_SQL_MySQLBackend)
  structure ODBC = Backend(SMLSharp_SQL_ODBCBackend)

  val postgresql = PGSQL.backend
  val mysql = MySQL.backend
  val odbc = ODBC.backend
  val default = postgresql

end
