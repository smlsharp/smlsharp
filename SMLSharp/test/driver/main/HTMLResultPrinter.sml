(**
 *
 * @author YAMATODANI Kiyoshi
 * @author UENO Katsuhiro
 * @version $Id: HTMLResultPrinter.sml,v 1.14 2007/12/15 07:27:50 kiyoshiy Exp $
 *)
structure HTMLResultPrinter : RESULT_PRINTER =
struct

  (***************************************************************************)

  structure TT = TestTypes
  structure PU = PathUtility

  (***************************************************************************)

  type context = {directory : string}

  (***************************************************************************)

  fun initialize {directory} = ({directory = directory} : context)

  fun finalize _ = ()

  fun printTo (channel : ChannelTypes.OutputChannel) text = #print channel text

  fun makeHTMLFilePath resultDirectory sourcePath =
      let
        val {dir, file} = PU.splitDirFile sourcePath
        val {base, ext} = PU.splitBaseExt file
      in
        {dir = resultDirectory, file = base ^ ".html"}
      end

  fun stringToVector s = Byte.stringToBytes s
  fun vectorToString v = Byte.bytesToString v

  fun escape s =
      String.translate
        (fn #"<" => "&lt;"
          | #">" => "&gt;"
          | #"\"" => "&quot;"
          | #"&" => "&amp;"
          | c => str c)
        s

  local
    fun splitLine s =
        map Substring.string
            (Substring.fields (fn x => x = #"\n") (Substring.full s))
    fun deleteSpace s =
        implode (List.filter (fn c => not (Char.isSpace c)) (explode s))
    fun prepare str =
        map (fn x => (deleteSpace x, x)) (splitLine str)
    fun compare ((x,_),(y,_)) = x = y
    fun del x = "<STRONG><FONT COLOR=RED>" ^ x ^ "</FONT></STRONG>\n"
    fun ins x = "<STRONG><FONT COLOR=RED>" ^ x ^ "</FONT></STRONG>\n"
    fun keep x = x ^ "\n"
  in
  fun diff print (expected, output) =
      let
        val (expected, output) =
            foldr (fn (Diff.DEL (_,x),(el,ol)) => (del x :: el, ol)
                    | (Diff.ADD (_,x),(el,ol)) => (el, ins x :: ol)
                    | (Diff.KEEP(_,x),(el,ol)) => (keep x :: el, keep x :: ol))
                  (nil, nil)
                  (Diff.diff compare (prepare expected, prepare output))
      in
        (concat expected, concat output)
      end
  end

  fun makeCasePage
      resultChannel
      ({sourcePath, isSameContents, source, output, expected, exceptions}
       : TT.caseResult)
    =
    let
      fun makeTXTFilePath sourcePath =
          let
            val {dir, file} = PU.splitDirFile sourcePath
            val {base, ext} = PU.splitBaseExt file
          in
            {dir = "/tmp", file = base ^ ".out"}
          end
      val txtPath = makeTXTFilePath sourcePath
      val txtChannel = FileChannel.openOut{fileName = PU.joinDirFile txtPath}
      val _ = #sendVector txtChannel output
      val _ = #close txtChannel ()





      val print = printTo resultChannel
      val printBin = #sendVector resultChannel
      fun printException exn =
          (
            print (escape (exnMessage exn) ^ "\n");
            app
                (fn line => print (escape line ^ "\n"))
                (SMLofNJ.exnHistory exn);
            print "\n"
          )
      fun printExceptions () =
          if List.null exceptions
          then ()
          else
            (
              print ("<H2>exceptions</H2>\n");
              print "<PRE>\n";
              app printException exceptions;
              print "</PRE>\n";
              print "<HR>\n"
            )
      fun printPart (title, content) =
          (
            print ("<H2>" ^ title ^ "</H2>\n");
            print "<PRE style=\"font-family: courier, monospace\">\n";
            print content;
            print "</PRE>\n";
            print "<HR>\n"
          )
      fun printPartHalf (dir, title, content) =
          (
            print ("<DIV style=\"width: 50%; float: "^dir^"\">\n");
            print ("<H2>" ^ title ^ "</H2>\n");
            print "<PRE STYLE=\"width: 100%; \
                  \overflow: scroll; font-family: courier, monospace\">\n";
            print content;
            print "</PRE>\n";
            print "</DIV>\n"
          )
      val source = escape (vectorToString source)
      val expected = escape (vectorToString expected)
      val output = escape (vectorToString output)
      val (expected, output) =
          diff print (expected, output)
    in
      print "<HTML><BODY>\n";
      print ("<H1>" ^ sourcePath ^ "</H1>\n");
      printExceptions ();
      printPart ("source", source);
      printPartHalf ("left", "expected", expected);
      print "<HR STYLE=\"display: none\">\n";
      printPartHalf ("right", "output", output);
      print "<HR STYLE=\"clear: both\">\n";
      print "</BODY></HTML>"
    end

  fun printCase
      (context as {directory, ...} : context)
      (result
       as {sourcePath, isSameContents, source, output, expected, exceptions}
       : TT.caseResult) =
      let
        val pagePath as {file = pageFileName, ...} =
            makeHTMLFilePath directory sourcePath
        val pageChannel =
            FileChannel.openOut{fileName = PU.joinDirFile pagePath}
      in
        makeCasePage pageChannel result
        handle exn => (#close pageChannel (); raise exn);
        #close pageChannel ();
        context
      end

  fun printCaseResultEntry
      directory
      resultChannel
      (result
       as {sourcePath, isSameContents, source, output, expected, exceptions}
       : TT.caseResult)
    =
    let
      val print = printTo resultChannel
      val casePagePath as {file = casePageFileName, ...} =
          makeHTMLFilePath directory sourcePath
    in
      print "<TR>\n";
      print
      ("<TD>" ^
       "<A HREF=\"" ^ casePageFileName ^ "\">" ^ sourcePath ^ "</A>" ^
       "</TD>\n");
      print
          ("<TD>" ^
           (if isSameContents
            then "pass"
            else "<FONT COLOR=\"RED\">fail</FONT>") ^
           "</TD>\n");
      print "</TR>\n"
    end

  fun printStatics resultChannel results =
      let
        val print = printTo resultChannel
        fun summary ({isSameContents, ...} : TT.caseResult, (pass, fail)) =
            if isSameContents then (pass + 1, fail) else (pass, fail + 1)
        val (pass, fail) = foldl summary (0, 0) results
      in
        print "<P>\n";
        print (Date.toString(Date.fromTimeLocal(Time.now ())) ^ "<BR>\n");
        print ("pass: " ^ Int.toString pass ^ "<BR>\n");
        print
        ("fail: <FONT COLOR=\"RED\">" ^ Int.toString fail ^ "</FONT><BR>\n");
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

  fun printSummary (context as {directory} : context) {messages, results} =
      let
        val resultPageChannel =
            FileChannel.openOut
            {fileName = PU.joinDirFile{dir = directory, file = "index.html"}}
        val print = printTo resultPageChannel
      in
        (
          print "<HTML><BODY>\n";
          printStatics resultPageChannel results;
          printMessages resultPageChannel messages;
          print "<TABLE BORDER=1>\n";
          app (printCaseResultEntry directory resultPageChannel) results;
          print "</TABLE>\n";
          print "</BODY></HTML>\n"
        ) handle exn => (#close resultPageChannel (); raise exn);
        #close resultPageChannel ();
        context
      end

  (***************************************************************************)

end

