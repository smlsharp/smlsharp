(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: TextResultPrinter.sml,v 1.8 2007/12/15 07:27:50 kiyoshiy Exp $
 *)
structure TextResultPrinter : RESULT_PRINTER =
struct

  (***************************************************************************)

  structure TT = TestTypes
  structure PU = PathUtility

  (***************************************************************************)

  type context = ChannelTypes.OutputChannel

  (***************************************************************************)

  fun printTo (channel : ChannelTypes.OutputChannel) text =
      #print channel text

  val subSectionSeparator = 
      "\n------------------------------------------------------------\n"
  val sectionSeparator = 
      "\n============================================================\n"

  fun initialize {directory} =
      let
        val resultChannel =
            FileChannel.openOut
            {fileName = PU.joinDirFile{dir = directory, file = "result.txt"}}
      in
        resultChannel
      end

  fun finalize (resultChannel : context) = #close resultChannel ()

  fun printCase
          (resultChannel : context)
          ({sourcePath, isSameContents, source, output, expected, exceptions}
           : TT.caseResult) =
      let val print = printTo resultChannel
      in
        app
        print
        [sourcePath, " : ", if isSameContents then "pass" else "fail", "\n"];
        if false = isSameContents
        then
          (
            print subSectionSeparator;
            print "SOURCE:\n";
            #sendVector resultChannel source;
            print subSectionSeparator;
            print "OUTPUT:\n";
            #sendVector resultChannel output;
            print sectionSeparator
          )
        else ();
        resultChannel
      end

  fun printSummary
          (resultChannel : context)
          {messages, results : TT.caseResult list} =
      let
        val cases = List.length results
        val successes =
            List.length
            (List.filter (fn result => #isSameContents result) results)
        val fails = cases - successes
      in
        printTo
            resultChannel
            ("cases:" ^ Int.toString cases ^ ", " ^
             "success:" ^ Int.toString successes ^ ", " ^
             "fail:" ^ Int.toString fails);
        printTo resultChannel sectionSeparator;
        app (fn message => printTo resultChannel (message ^ "\n")) messages;
        printTo resultChannel sectionSeparator;
        resultChannel
      end

  (***************************************************************************)

end