(*
val s = _sqlserver "dbname=ohori" : {persons: {name:string, age:int} list};
val c = SQL.connect s;
SQL.closeConn c;
SQL.closeConn c;
*)

val s = _sqlserver SQL.sqlite3 ":memory:" : {persons: {name:string, age:int} list};
val c = SQL.connectAndCreate s;
SQL.closeConn c;
SQL.closeConn c;

(*
複数回のcloseConnでSegmentation fault
TextIO.closeのように複数回をゆるすか、
または、ユーザエラーが望ましい。
*)
