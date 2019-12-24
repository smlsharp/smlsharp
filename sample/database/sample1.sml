(*
 * simple example program using SQL.
 *
 * Prior to running this program, create a database named "sample1" and
 * run "sample1.sql" on that database.
 *)

(* declare a database server *)
val server = _sqlserver "dbname=sample1"
             : {people: {name:string, age:int} list}

(* connect to the database server *)
val conn = SQL.connect server

(* INSERT INTO people (name, age) VALUES ('Alice', 24) *)
val q1 = _sql db => insert into #db.people (name, age)  values ("Alice", 24)

(* execute the command q1 on the server *)
val _ = q1 conn

(* INSERT INTO people (name, age) VALUES ('Bob', 25) *)
val q2 = _sql db => insert into #db.people (name, age) values ("Bob", 25)

(* execute the command q2 on the server *)
val _ = q2 conn

(* SELECT name, age FROM people WHERE age >= 25 *)
val q3 = _sql db => select #person.name as name, #person.age as age
                    from #db.people as person
                    where #person.age >=  25

(* execute the query q3 on the server and obtain the cursor of the result *)
val r = q3 conn

(* fetch all tuples from the result *)
val x = SQL.fetchAll r

(* close the cursor *)
val _ = SQL.closeCursor r

(* close the connection *)
val _ = SQL.closeConn conn

(* print the result *)
val _ = Dynamic.pp x
