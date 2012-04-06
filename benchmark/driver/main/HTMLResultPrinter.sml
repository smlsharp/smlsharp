(**
 *
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @version $Id: HTMLResultPrinter.sml,v 1.14 2007/12/07 09:08:31 katsu Exp $
 *)
structure HTMLResultPrinter : RESULT_PRINTER =
struct

  (***************************************************************************)

  structure C = Control
  structure BT = BenchmarkTypes
  structure PU = PathUtility

  (***************************************************************************)

  type context = {directory : string}

  (***************************************************************************)

  fun initialize {directory} = ({directory = directory} : context)

  fun finalize _ = ()

  fun printTo (channel:ChannelTypes.OutputChannel) text = #print channel text

  fun makeHTMLFilePath resultDirectory sourcePath =
      let
        val {dir, file} = PU.splitDirFile sourcePath
        val {base, ext} = PU.splitBaseExt file
      in
        {dir = resultDirectory, file = base ^ ".html"}
      end

  fun printCase context (result : BT.benchmarkResult) = context

  fun printTableHeader resultChannel =
    let
      val print = printTo resultChannel
    in
      print "<TR>\n";

      print "<TH>source file</TH>\n";
      print "<TH>compile(sys/usr/real)</TH>\n";
      print "<TH>execute(sys/usr/real)</TH>\n";
      print "<TH>exceptions</TH>\n";
      print "<TH>compile output</TH>";
      print "<TH>execution output</TH>";

      print "</TR>\n" 
    end

  fun printCaseResultEntry
          directory resultChannel (result : BT.benchmarkResult) =
    let
      val print = printTo resultChannel
      fun printElapsedTime {sys, usr, real} =
          app
            print
            [
              (Time.toString sys), "/", 
              (Time.toString usr), "/", 
              (Time.toString real)
            ]
      fun printException exn =
          (
            print (exnMessage exn);
            print "<br>";
            app
              (fn history => print (history ^ "<br>\n")) 
              (SMLofNJ.exnHistory exn)
          )
      val casePagePath as {file = casePageFileName, ...} =
          makeHTMLFilePath directory (#sourcePath result)
    in
      print "<TR>\n";

      (* source file *)
      print ("<TD>" ^ (#sourcePath result) ^ "</TD>\n");

      (* compile time *)
      print "<TD>";
      printElapsedTime (#compileTime result);
      print "</TD>";

      (* execution time *)
      print "<TD>";
      printElapsedTime (#executionTime result);
      print "</TD>";

      (* exceptions *)
      print "<TD>";
      app
        (fn exn => (printException exn; print "<p>\n"))  
        (!(#exceptions result));
      print "</TD>";

      (* output of compilation *)
      print "<TD>";
      case #compileOutputArrayOpt result of
        NONE => print "&nbsp;"
      | SOME outputArray => 
        (print (Byte.unpackString (Word8ArraySlice.slice (outputArray, 0, NONE))));
      print "</TD>";

      (* output of execution *)
      print "<TD>";
      case #executeOutputArrayOpt result of
        NONE => print "&nbsp;"
      | SOME outputArray => 
        (print (Byte.unpackString (Word8ArraySlice.slice(outputArray, 0, NONE))));
      print "</TD>";

      print "</TR>\n" 
    end

  fun printStatics resultChannel results =
      let
        val print = printTo resultChannel
      in
        print "<P>\n";
        print (Date.toString(Date.fromTimeLocal(Time.now ())) ^ "<BR>\n");
        print ("benchmarks: " ^ Int.toString (List.length results) ^ "<BR>\n");
        print "</P>\n"
      end

  fun printMessages resultPageChannel messages =
      let
        val print = printTo resultPageChannel
      in
        print "<P>\n";
        app (fn message => (print message; print "\n<br>")) messages;
        print "</P>\n"
      end

  fun printOptions resultPageChannel =
      let
        val print = printTo resultPageChannel
        fun printRow (name, switch) =
            (
              print "<tr>";
              print ("<td>" ^ name ^ "</td>");
              print ("<td>" ^ (C.switchToString switch) ^ "</td>");
              print "</tr>\n"
            )
      in
        print "<P>\n";
        print "<table BORDER=1>\n";
        print "<tr><th>name</th><th>value</th></tr>\n";
        app printRow (C.listSwitches ());
        print "</table>\n";
        print "</P>\n"
      end

  fun printSummary (context : context) {messages, results} =
      let
        val directory = #directory context
        val fileName = PU.joinDirFile{dir = directory, file = "index.html"}
        val resultPageChannel = FileChannel.openOut {fileName = fileName}
        val print = printTo resultPageChannel
      in
        (
          print "<HTML><BODY>\n";

          printStatics resultPageChannel results;

          printMessages resultPageChannel messages;

          print "<TABLE BORDER=1>\n";
          printTableHeader resultPageChannel;
          app (printCaseResultEntry directory resultPageChannel) results;
          print "</TABLE>\n";

          printOptions resultPageChannel;

          print "</BODY></HTML>\n"
        ) handle exn => (#close resultPageChannel (); raise exn);
        #close resultPageChannel ();
        context
      end

  (***************************************************************************)

end
