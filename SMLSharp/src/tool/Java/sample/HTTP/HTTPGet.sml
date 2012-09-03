(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

use "Java.sml";
use "./JavaCorePackages.sml";

val _ = Java.initialize [];
val _ = JavaCorePackages.static();

open JavaCorePackages;

val $ = Java.call;
val $$ = Java.referenceOf;

open java.lang;
open java.io;
open java.net;

structure HTTPGet =
struct
  val out = PrintStream(System.get'out())

  fun main(args) =
      let
        val url =
            URL.new'String(SOME "http://www.pllab.riec.tohoku.ac.jp/smlsharp/")
        val connection = URLConnection($url#openConnection())
        val inStream = InputStream($connection#getInputStream())
        val input =
            BufferedReader.new'Reader
                ($$(InputStreamReader.new'InputStream($$inStream)))
      in
        while $input#ready()
        do
          $out#println'String ($input#readLine())
      end
        handle Java.JavaException throwable =>
               if IOException.isInstance throwable
               then
                 $out#println'String ($(IOException(throwable))#toString())
               else
                 $(Exception(throwable))#printStackTrace();
end;

HTTPGet.main [];