(**
 * The entry point to smlformat for invokation as a standalone command.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.6 2006/02/07 12:49:33 kiyoshiy Exp $
 *)
structure Main =
struct

  (***************************************************************************)

  local
    structure FG = FormatterGenerator
  in

  fun main(programName, commandLineArgs) =
      let
        (* ToDo : use GetOpt library to process commandline arguments. *)
        val (options, sourceFileNames) =
            List.partition (String.isPrefix "--") commandLineArgs

        val toStandardOut =
            List.exists (fn option => option = "--stdout") options

        val (openOut, closeOut) =
            if toStandardOut
            then (fn _ => TextIO.stdOut, fn _ => ())
            else
              (
                fn sourceFileName => TextIO.openOut (sourceFileName ^ ".sml"),
                TextIO.closeOut
              )

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
                  destinationStream = outputStream
                }
                handle error => (closeOut outputStream; raise error);
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
                   app (fn message => print (message ^ "\n")) errorMessages;
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