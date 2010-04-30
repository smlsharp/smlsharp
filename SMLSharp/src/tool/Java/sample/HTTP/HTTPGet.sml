use "Java.sml";
use "./HTTP.sml";

val _ = Java.initialize [];
val _ = HTTP.static();

local
  open HTTP.java.io
  open HTTP.java.net
  open HTTP.java.lang

  fun T stringOpt = Option.getOpt (stringOpt, "NULL")
  val $ = Java.call
  val $$ = Java.referenceOf
in
fun main() =
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
        print(T($input#readLine()) ^ "\n")
    end
      handle Java.JavaException throwable =>
             if IOException.isInstance throwable
             then
               print(T($(IOException(throwable))#toString()))
             else
               $(Exception(throwable))#printStackTrace()
end;
