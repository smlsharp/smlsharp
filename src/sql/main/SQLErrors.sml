structure SQL = (* give exceptions print name beginning with "SQL." *)
struct

  (* unexpected error occurred during parsing query results *)
  exception Format

  (* unexpected error occurred when executing an SQL query *)
  exception Exec of string

  (* unexpected error occurred when connecting to a server *)
  exception Connect of string

  (* error occurred when linking a database connection to an SML program *)
  exception Link of string

end

structure SMLSharp_SQL_Errors = SQL
