(*
 * simple example program using polymorphic SQL.
 *
 * Prior to running this program, create a database named "sample2" and
 * run "sample2.sql" on that database.
 *)

val db = _sqlserver "dbname=sample2"
         : {employee: {name:string, age:int, salary:int, deptid:int},
            department: {id:int, name:string}};

val conn = SQL.connect db;

fun fetch q =
    let val r = q conn
    in SQL.fetchAll r before SQL.closeRel r
    end

fun salaryRank condFn =
    _sql db => select #r.name as name, #r.salary as salary
               from #db.employee as r
               where condFn r
               order by #r.salary desc;

fun salaryRankOf (deptId:int) condFn =
    salaryRank (fn r => SQL.andAlso (SQL.== (#r.deptid, SQL.toSQL deptId),
                                     condFn r));

val depts =
    fetch
      (_sqleval
         (_sql db => select #r.name as deptName, #r.id as deptId
                     from #db.department as r
                     order by #r.name));

fun printList depts =
    app (fn {deptName, employees} =>
            (print (deptName ^ "\n");
             app (fn {name, salary} =>
                     print ("\t" ^ name ^ "\t" ^ Int.toString salary ^ "\n"))
                 employees))
        depts;

val cond1 = fn r => SQL.> (#r.salary, 500);
val list1 =
    map (fn {deptId, deptName} =>
            {deptName = deptName,
             employees = fetch (_sqleval (salaryRankOf deptId cond1))})
        depts;

val _ = print "List1:\n"
val _ = printList list1;

val cond2 = fn r => SQL.> (#r.age, 30);
val list2 =
    map (fn {deptId, deptName} =>
            {deptName = deptName,
             employees = fetch (_sqleval (salaryRankOf deptId cond2))})
        depts;
val _ = print "\nList2:\n"
val _ = printList list2;
