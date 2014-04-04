(**
 * The entry point to smlformat for invocation as a standalone command.
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 * @version $Id: Main.sml,v 1.8 2008/08/10 13:44:01 kiyoshiy Exp $
 *)
structure Main =
struct

  (***************************************************************************)

  local
    structure FG = FormatterGenerator
  in

  fun main(programName:string, commandLineArgs:string list) =
      let
        (* ToDo : use GetOpt library to process commandline arguments. *)
        val (options, sourceFileNames) =
            List.partition (String.isPrefix "--") commandLineArgs

        (* NOTE: Following code is not efficient, but we assume here
         * that so many command options are not given.
         *)
        val toStandardOut =
            List.exists (fn option => option = "--stdout") options
        val withLineDirective =
            List.exists (fn option => option = "--with-line-directive") options
        val outputFilename =
            case List.find (String.isPrefix "--output=") options of
              SOME s => SOME (String.substring (s, 9, size s - 9))
            | NONE => NONE

        val (openOut, closeOut, removeOut) =
            case (toStandardOut, outputFilename) of
              (true, _) => 
              (fn _ => TextIO.stdOut, fn _ => (), fn _ => ())
            | (false, SOME filename) =>
              (
                fn _ => TextIO.openOut filename,
                TextIO.closeOut,
                fn _ => OS.FileSys.remove filename
              )
            | (false, NONE) =>
              (
                fn sourceFileName => TextIO.openOut (sourceFileName ^ ".sml"),
                TextIO.closeOut,
                fn sourceFileName => OS.FileSys.remove (sourceFileName ^ ".sml")
              )

        val _ =
            if List.null sourceFileNames
            then raise Fail "filename is required."
            else ()
      in
        app
        (fn sourceFileName =>
            let val sourceStream = TextIO.openIn sourceFileName
            in
              let val outputStream = openOut sourceFileName
              in
                PPGMain.main
                {
                  sourceFileName = sourceFileName,
                  sourceStream = sourceStream,
                  destinationStream = outputStream,
                  withLineDirective = withLineDirective
                }
                handle error => (closeOut outputStream;
                                 removeOut sourceFileName;
                                 raise error);
                closeOut outputStream
              end
                handle error => (TextIO.closeIn sourceStream; raise error);
              TextIO.closeIn sourceStream
            end)
        sourceFileNames;
        OS.Process.success
      end
        handle e =>
               let
                 val errorMessages =
                     case e of
                       PPGMain.Error messages => messages
                     | _ => [General.exnMessage e]
               in
                 (
                   app (fn message =>
                           TextIO.output (TextIO.stdErr, message ^ "\n"))
                       errorMessages;
(*
                   app
                       (fn history => print ("  " ^ history ^ "\n"))
                       (SMLofNJ.exnHistory e);
*)
                   OS.Process.failure
                 )
               end

  end

  (***************************************************************************)

end
