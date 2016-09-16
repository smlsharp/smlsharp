(**
 * SQL support for SML#
 * @author UENO Katsuhiro
 * @author ENDO hiroki
 * @copyright (c) 2009, 2010, Tohoku University.
 *)

structure SQL =
struct
  local
    open SMLSharp_SQL_Backend
    open SMLSharp_SQL_Prim
    open SMLSharp_SQL_Utils
  in   
    type backend = backend
    type 'a server = 'a server
    type ('a,'b) value = ('a,'b) value
    type 'a conn = 'a conn
    type 'a db = 'a db
    type ('a,'b) db' = ('a,'b) db'
    type ('a,'b) table = ('a,'b) table
    type ('a,'b) row = ('a,'b) row
    type 'a query = 'a query
    type command = command
    type 'a rel = 'a rel
    type 'w bool_value = 'w bool_value
  
    datatype schema = datatype schema
  
    type ('a,'w) toy = ('a,'w) toy
    type ('a,'b) selector = ('a,'b) selector
    type ('a,'w) raw_row = ('a,'w) raw_row
   
    datatype res_impl = datatype res_impl
  
    type qexp = qexp
    
    type decimal = decimal
    type timestamp = timestamp
    type float = float
  
    type ('row,'view,'w) table1 = ('row,'view,'w) table1 
    type ('row,'view,'w) table2 = ('row,'view,'w) table2 
    type ('row,'view,'w) table3 = ('row,'view,'w) table3 
    type ('row,'view,'w) table4 = ('row,'view,'w) table4 
    type ('row,'w) table5 = ('row,'w) table5 
   
    type schema_column = schema_column
  
    exception Format = Format
    exception Exec = Exec
    exception Connect = Connect
    exception Link = Link
    exception InvalidCommand = InvalidCommand
    exception NotOne = NotOne

    val op ^ = strcat
    val postgresql = postgresql
    val mysql = mysql
    val odbc = odbc
  
    val connect = connect 
    val fetch = fetch 
    val exec = exec
    val closeConn = closeConn 
    val closeRel = closeRel 
  
    val exists = exists
    val Some = Some 
    val Null  = Null
  
    val queryString = queryString
    val commandString = commandString

    val andAlso = andAlso
    val orElse = orElse
    val not = not
    val isNull = isNull
    val isNotNull = isNotNull

    val fetchAll = fetchAll
    val fetchOne = fetchOne
    
  end

  structure TimeStamp = SMLSharp_SQL_TimeStamp
  structure Decimal = SMLSharp_SQL_Decimal
  structure Float = SMLSharp_SQL_Float

  structure Prims =
  struct
    open SMLSharp_SQL_Backend
    open SMLSharp_SQL_Prim
    open SMLSharp_SQL_Utils
  end
end
