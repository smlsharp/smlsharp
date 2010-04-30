(**
 * print test result into channel.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)
structure ParsableResultPrinter : RESULT_PRINTER =
struct

  type context = {directory : string}

  fun initialize {directory} = ({directory = directory} : context)

  fun finalize _ = ()

  fun printTo (channel:ChannelTypes.OutputChannel) text = #print channel text

  fun printCase context (result : BenchmarkTypes.benchmarkResult) = context

  fun formatElapsedTime {sys, usr, real} =
      Time.toString sys ^ " / "
      ^ Time.toString usr ^ " / "
      ^ Time.toString real

  fun noBreak string =
      String.translate (fn #"\n" => " " | c => str c) string

  fun formatKey key =
      String.translate
          (fn #":" => "_"
            | c => if Char.isSpace c then "_" else str c)
          key

  fun appi f l =
      let
        fun loop (n, nil) = ()
          | loop (n, h::t) = (f (h,n) : unit; loop (n+1,t))
      in
        loop (0, l)
      end

  fun printOutput out prefix NONE = ()
    | printOutput out prefix (SOME array) =
      let
        val str = Byte.unpackString (Word8ArraySlice.slice (array, 0, NONE))
        val lines = String.fields (fn c => c = #"\n") str
      in
        app (fn line => printTo out (prefix ^ line ^ "\n")) lines
      end

  fun printResult out no (result : BenchmarkTypes.benchmarkResult) =
      let
        val prefix = "result:" ^ Int.toString no ^ ":"
        fun toKey (setName, timerName, time) =
            formatKey (setName ^ "." ^ timerName)
      in
        printTo out (prefix ^ "sourcePath: " ^ #sourcePath result ^ "\n");
        printTo out (prefix ^ "compileTime: "
                     ^ formatElapsedTime (#compileTime result) ^ "\n");

        app (fn x => printTo out (prefix ^ "compileProfile:keys: "
                                  ^ toKey x ^ "\n"))
            (#compileProfile result);

        app
          (fn profile as (setName, timerName, time) =>
              printTo out (prefix ^ "compileProfile:"
                           ^ toKey profile ^ ": " ^ Time.toString time ^ "\n"))
          (#compileProfile result);
          
        printTo out (prefix ^ "executionTime: "
                     ^ formatElapsedTime (#executionTime result) ^ "\n");
        
        printTo out (prefix ^ "exitStatus: "
                     ^ (if OS.Process.isSuccess (#exitStatus result)
                        then "0"
                        else "failed")
                     ^ "\n");

        app
          (fn exn =>
              (
                printTo out (prefix ^ "exceptions: " ^ exnMessage exn
                             ^ "\n");
                app (fn history =>
                        printTo out (prefix ^ "exceptions: "
                                     ^ "\t" ^ history ^ "\n"))
                    (SMLofNJ.exnHistory exn)
              ))
          (!(#exceptions result));

        printOutput out (prefix ^ "compileOutput: ")
                        (#compileOutputArrayOpt result);
        printOutput out (prefix ^ "executeOutput: ")
                        (#executeOutputArrayOpt result);
                                  
       ()
     end

  fun printSummary (context : context) {messages, results} =
      let
        val filename = PathUtility.joinDirFile {dir = #directory context,
                                                file = "result.txt"}
        val _ = print ("output file: " ^ filename ^ "\n")
        val out = FileChannel.openOut {fileName = filename}
        val now = Date.fromTimeLocal (Time.now ())
      in
        printTo out ("date: " ^ Date.toString now ^ "\n");
        printTo out ("numResults: " ^ Int.toString (length results)
                     ^ "\n");

        app
          (fn (name, switch) =>
              printTo out ("option:keys: " ^ formatKey name ^ "\n"))
          Control.switchTable;

        app
          (fn (name, switch) =>
                printTo out ("option:" ^ formatKey name ^ ": "
                             ^ noBreak (Control.switchToString switch)
                             ^ "\n"))
          Control.switchTable;

        app
          (fn msg =>
              printTo out ("message: " ^ msg ^ "\n"))
          messages;

        foldl
          (fn (result, no) => 
              (printResult out no result; no + 1))
          1 results;

        #close out ();
        context
      end

end
