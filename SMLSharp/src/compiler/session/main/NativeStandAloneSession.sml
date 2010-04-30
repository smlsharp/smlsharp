(**
 * session implementation for batch mode native code compile.
 *
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)
(* FIXME: temporally version. More refinement is needed. *)
structure NativeStandAloneSession : sig
  include SESSION
  datatype compileMode =
           Executable
         | StaticLibrary
         | ObjectFile
         | AssemblyCode
end =
struct

  datatype compileMode =
           Executable
         | StaticLibrary
         | ObjectFile
         | AssemblyCode

  type InitialParameter =
      {
        outputFileName: string,
        preludeLibraryFileName: string option,
        compileMode: compileMode
      }

  fun join [x] = x
    | join (h::t) = h ^ " " ^ join t
    | join nil = ""

  fun left (s,n) = substring (s, size s - n, n)
  fun pad0 (s,n) = if size s > n then s else left ("000" ^ s, n)
  fun fmt3 i = pad0 (Int.fmt StringCvt.DEC i, 3)

  fun system command =
      (
        if !Control.switchTrace andalso !Control.traceFileLoad
        then TextIO.output (TextIO.stdErr, command ^ "\n")
        else ();
        if OS.Process.isSuccess (OS.Process.system command)
        then ()
        else raise Fail ("command failed : " ^ command)
      )

  fun rm_f filenames =
      (
        if !Control.switchTrace andalso !Control.traceFileLoad
        then TextIO.output (TextIO.stdErr, "rm -f "^join filenames^"\n")
        else ();
        app (fn x => OS.FileSys.remove x handle OS.SysErr _ => ()) filenames
      )

  fun makeFilename (baseFilename, seqno, newExt) =
      let
        val {base, ext} = OS.Path.splitBaseExt baseFilename
        val base = base ^ "-" ^ fmt3 seqno
      in
        OS.Path.joinBaseExt {base = base, ext = SOME newExt}
      end

  fun openSession {outputFileName, preludeLibraryFileName, compileMode} =
      let
        val useTmp =
            case compileMode of
              Executable => true
            | StaticLibrary => true
            | ObjectFile => true
            | AssemblyCode => false
        val useTmp =
            useTmp andalso not (!Control.keepAsm)

        val count = ref 0
        val objectFiles = ref nil

        fun execute (SessionTypes.ASMFILE asmFn) =
            let
              val (tmpfiles, asmfile, objfile) =
                  if useTmp
                  then
                    let
                      (* Assume that tmpName appended any suffix is also
                       * unique and race condition doesn't occur.
                       * We want to use mktemp(3) but Standard ML Basis
                       * Library doesn't provide it.
                       *)
                      val basename = OS.FileSys.tmpName ()
                    in
                      ([basename], basename ^ ".s", basename ^ ".o")
                    end
                  else
                    (nil,
                     makeFilename (outputFileName, !count, "s"),
                     makeFilename (outputFileName, !count, "o"))

              val allfiles =
                  if !Control.keepAsm
                  then objfile :: tmpfiles
                  else objfile :: asmfile :: tmpfiles

              val asmout = TextIO.openOut asmfile
              val e = (asmFn (fn s => TextIO.output (asmout, s)); NONE)
                      handle e => SOME e
              val _ = TextIO.closeOut asmout
              val _ = case e of NONE => () | SOME e => (rm_f allfiles; raise e)
            in
              if (case compileMode of
                    Executable => true
                  | StaticLibrary => true
                  | ObjectFile => true
                  | AssemblyCode => false)
              then
                (system (Configuration.CC ^ " " ^
                         !Control.CFLAGS ^ " -c " ^ asmfile ^
                         " -o " ^ objfile)
                 handle e => (rm_f allfiles; raise e);
                 if !Control.keepAsm then () else rm_f [asmfile];
                 objectFiles := objfile :: !objectFiles)
              else ();
              rm_f tmpfiles;
              count := !count + 1
            end
          | execute _ = raise Control.Bug "NativeStandAloneSession: execute"

        fun close () =
            case !objectFiles of
              nil => ()
            | _ =>
              let
                val objectFiles = rev (!objectFiles) before objectFiles := nil
                val files = case preludeLibraryFileName of
                              SOME filename => filename::objectFiles
                            | NONE => objectFiles
                val files = join files

                val e =
                    (case compileMode of
                       Executable =>
                       (
                         system (Configuration.CC ^ " " ^
                                 Configuration.LDFLAGS ^ " \
                                 \-L" ^ Configuration.LibDirectory ^ " " ^
                                 !Control.LDFLAGS ^ " " ^
                                 files ^ " " ^
                                 " -lsmlsharp_entry -lsmlsharp " ^
                                 Configuration.LIBS ^ " \
                                 \ -o " ^ outputFileName);
                         NONE
                       )
                     | StaticLibrary =>
                       (* FIXME: this doesn't work due to weak definition. *)
                       (
                         system (Configuration.AR ^ " cru " ^
                                 outputFileName ^ " " ^ files);
                         system (Configuration.RANLIB ^ " " ^ outputFileName);
                         NONE
                       )
                     | ObjectFile =>
                       (
                         system (Configuration.LD ^ " " ^
                                 Configuration.LDFLAGS ^ " " ^
                                 !Control.LDFLAGS ^ " " ^ " -r " ^
                                 files ^ " -o " ^ outputFileName);
                         NONE
                       )
                     | AssemblyCode => NONE)
                    handle e => SOME e
              in
                rm_f objectFiles;
                case e of NONE => ()
                        | SOME e => (rm_f [outputFileName]; raise e)
              end
      in
        {
          execute = execute,
          close = close
        }
      end

end
