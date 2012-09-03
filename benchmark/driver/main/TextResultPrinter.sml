(**
 * 
 * @author YAMATODANI Kiyoshi
 * @version $Id: TextResultPrinter.sml,v 1.5 2007/12/07 09:08:31 katsu Exp $
 *)
structure TextResultPrinter : RESULT_PRINTER =
struct

  (***************************************************************************)

  structure BT = BenchmarkTypes
  structure PU = PathUtility

  (***************************************************************************)

  type context = ChannelTypes.OutputChannel

  (***************************************************************************)

  fun printTo (channel:context) text = #print channel text

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
      (result : BT.benchmarkResult
       as {sourcePath, compileTime, executionTime, ...})
      =
      let val print = printTo resultChannel
      in
        print (sourcePath ^ "\n");
        resultChannel
      end

  fun printSummary
          (resultChannel : context)
          {messages, results : BT.benchmarkResult list} =
      let
        val cases = List.length results
      in
        printTo resultChannel ("cases:" ^ Int.toString cases);
        printTo resultChannel sectionSeparator;
        app (fn message => printTo resultChannel (message ^ "\n")) messages;
        printTo resultChannel sectionSeparator;
        resultChannel
      end

  (***************************************************************************)

end
