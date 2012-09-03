(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: TextResultPrinter.sml,v 1.5 2005/09/05 03:06:07 kiyoshiy Exp $
 *)
structure TextResultPrinter : RESULT_PRINTER =
struct

  (***************************************************************************)

  structure TT = TestTypes
  structure PU = PathUtility

  (***************************************************************************)

  type context = ChannelTypes.OutputChannel

  (***************************************************************************)

  fun printTo channel text =
      #print (CharacterStreamWrapper.wrapOut channel) text

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
            #sendArray resultChannel source;
            print subSectionSeparator;
            print "OUTPUT:\n";
            #sendArray resultChannel output;
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