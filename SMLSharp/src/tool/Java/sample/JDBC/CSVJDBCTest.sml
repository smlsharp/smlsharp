(*
 * JDBC sample code.
 * See README.txt.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: CSVJDBCTest.sml,v 1.4 2010/04/24 07:48:03 kiyoshiy Exp $
 *)

use "Java.sml";

nonfix before; (* Some classes in JDBC has 'before' method. *)
use "./JDBC.sml";

val DriverClass = "org.relique.jdbc.csv.CsvDriver";

(*
 * Class path of CSV JDBC driver is specified in bootclasspath property to
 * let the boot class loader find the driver.
 * See 
 *     http://csvjdbc.sourceforge.net/
 *
 * And, CSV JDBC driver is specified in jdbc.drivers property to load it in
 * initialization of JDBC.
 * So, it is not necessary to load the JDBC driver by using Class.forName
 *   Class.forName "org.relique.jdbc.csv.CsvDriver"
 * which causes a problem for class loader.
 *)
val _ = Java.initialize
            ([
               "-Xbootclasspath/a:./csvjdbc.jar",
               "-Djdbc.drivers=" ^ DriverClass
             ]);
(* 
val _ = Class.forName'String(SOME DriverClass);
val _ = Class.forName'StringZClassLoader
              (
                SOME DriverClass,
                true,
                ClassLoader.getSystemClassLoader()
              );
*)

val _ = JDBC.static ();

local
  open JDBC.java.sql
  open JDBC.java.lang

  fun T stringOpt = Option.getOpt (stringOpt, "NULL")
  val $ = Java.call
in
fun main () =
    let
      val URL = "jdbc:relique:csv:./tables"
      val conn = Connection(DriverManager.getConnection'String(SOME URL))
      val stmt = Statement($conn#createStatement())
      val results =
          ResultSet
              ($stmt#executeQuery(SOME "SELECT NAME, TYPE FROM languages"))
    in
      while $results#next() 
      do 
        print
            ("NAME = "
             ^ T($results#getString'String(SOME "TYPE"))
             ^ "   TYPE = "
             ^ T($results#getString'String(SOME "NAME"))
             ^ "\n");

      $results#close();
      $stmt#close();
      $conn#close()
    end
end;
