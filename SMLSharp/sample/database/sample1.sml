(*
 * simple example program using SQL.
 *
 * Prior to running this program, create a database named "sample1" and
 * run "sample1.sql" on that database.
 *)

(* declare a database server *)
val server =
    _sqlserver "dbname=sample1"
    : {people: {name:string, age:int}};

(* connect to the database server *)
val conn = SQL.connect server;

(* INSERT INTO people (name, age) VALUES ('Alice', 24) *)
val q =
    _sql db =>
         insert into #db.people (name, age)
         values ("Alice", 24);

(* execute query q on the server *)
val _ = _sqlexec q conn;

(* INSERT INTO people (name, age) VALUES ('Bob', 25) *)
val q =
    _sql db =>
         insert into #db.people (name, age)
         values ("Bob", 25);

val _ = _sqlexec q conn;

(* SELECT name, age FROM people WHERE age >= 25 *)
val q =
    _sql db =>
         select #person.name as name,
                #person.age as age
         from #db.people as person
         where SQL.>= (#person.age, 25);

(* use "_sqleval" instead of "_sqlexec" to run SELECT query *)
val r = _sqleval q conn;

(* fetch all tuples from the result *)
val x = SQL.fetchAll r;

(* close the result *)
val _ = SQL.closeRel r;

(* close the connection *)
val _ = SQL.closeConn conn;
