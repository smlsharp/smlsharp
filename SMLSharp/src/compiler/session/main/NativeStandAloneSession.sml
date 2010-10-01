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
         | ObjectFile of {isPrelude: bool}
         | AssemblyCode
end =
struct

  datatype compileMode =
           Executable
         | StaticLibrary
         | ObjectFile of {isPrelude: bool}
         | AssemblyCode

  type InitialParameter =
      {
        outputFileName: string,
        preludeLibraryFileName: string option,
        entryObjectFileName: string option,
        compileMode: compileMode
      }

  val mktempRetryCount = 5
  val maxCommandLineSize = 1024
  val OBJEXT = "o"
  val LIBEXT = "a"
  val ASMEXT = "s"

  structure Try : sig
    type ('a,'b) cont
    val try : (unit -> 'a) -> ('a,'b) cont -> 'b
    val catch : ('a, (exn -> 'a) -> ('a,'b) cont -> 'b) cont
    val if_error : ('a, (exn -> unit) -> ('a,'b) cont -> 'b) cont
    val finally : ('a, (unit -> unit) -> ('a,'b) cont -> 'b) cont
    val end_try : ('a,'a) cont
  end = struct
    datatype 'a ret = RET of 'a | ERROR of exn
    type ('a,'b) cont = 'a ret -> 'b
    fun try tryFn cont = cont (RET (tryFn ()) handle e => ERROR e)
    fun catch (x as RET _) catchFn cont = cont x
      | catch (ERROR e) catchFn cont = cont (RET (catchFn e))
    fun if_error (x as RET _) catchFn cont = cont x
      | if_error (x as ERROR e) catchFn cont = (catchFn e : unit; cont x)
    fun finally x finalFn cont = (finalFn () : unit; cont x)
    fun end_try (RET x) = x
      | end_try (ERROR e) = raise e
  end
  open Try

  fun join [x] = x
    | join (h::t) = h ^ " " ^ join t
    | join nil = ""

  fun left (s,n) = substring (s, size s - n, n)
  fun pad0 (s,n) = if size s > n then s else left ("000" ^ s, n)
  fun fmt3 i = pad0 (Int.fmt StringCvt.DEC i, 3)

  fun take maxSize strs =
      let
        fun loop (nil, s) = (s, nil)
          | loop (h::t, "") = loop (t, h)
          | loop (l as h::t, s) =
            if size s + 1 + size h > maxSize
            then (s, l)
            else loop (t, s ^ " " ^ h)
      in
        loop (strs, "")
      end

  fun take2 maxSize nil = ("", nil)
    | take2 maxSize (h::t) =
      let
        val (s, l) = take (maxSize - (size h + 1)) t
      in
        (h ^ " " ^ s, l)
      end

  fun log msg =
      if !Control.switchTrace andalso !Control.traceFileLoad
      then TextIO.output (TextIO.stdErr, msg ^ "\n")
      else ()

  fun mktemp_d retry =
      if retry <= 0
      then raise Fail "failed to make temporally directory"
      else
        let
          (*
           * Basis Library specification says that OS.FileSys.tmpName creates
           * a new file, so we need to remove the file later.
           * 
           * tmpName of SML/NJ for UNIX doesn't create a file because it is
           * implemented by tmpnam(3).
           *)
          val tmpname = OS.FileSys.tmpName ()
          (*
           * we assume that tmpname ^ ".tmp" is also an unique name for
           * temporally file.
           *)
          val dirname = tmpname ^ ".tmp"
        in
          log ("mkdir " ^ dirname);
          (OS.FileSys.mkDir dirname; (tmpname, dirname))
          handle OS.SysErr (e, _) =>
                 (log ("mkdir failed : " ^ e); mktemp_d (retry - 1))
        end

  fun rmdir dirname =
      (
        log ("rmdir " ^ dirname);
        OS.FileSys.rmDir dirname
        handle OS.SysErr (e, _) => log ("rmdir failed : " ^ e ^ " (ignored)")
      )

  fun rm_f filenames =
      (
        log ("rm -f " ^ join filenames);
        app (fn x => OS.FileSys.remove x handle OS.SysErr (e, _) => ())
            filenames
      )

  fun system command =
      (
        log command;
        if OS.Process.isSuccess (OS.Process.system command)
        then ()
        else raise Fail ("command failed : " ^ command)
      )

  fun makeFilename (dir, basename, seqno, newExt) =
      let
        val base = #base (OS.Path.splitBaseExt basename)
        val base = base ^ "-" ^ fmt3 seqno
        val filename = OS.Path.joinBaseExt {base = base, ext = SOME newExt}
      in
        if dir = "" then filename
        else OS.Path.joinDirFile {dir = dir, file = filename}
      end

  fun replaceSuffix filename suffix =
      let
        val {base, ext} = OS.Path.splitBaseExt filename
      in
        OS.Path.joinBaseExt {base = base, ext = SOME suffix}
      end

  fun openSession {outputFileName, preludeLibraryFileName,
                   entryObjectFileName, compileMode} =
      let
        val doAssemble =
            case compileMode of
              Executable => true
            | StaticLibrary => true
            | ObjectFile _ => true
            | AssemblyCode => false

        val basename = #file (OS.Path.splitDirFile outputFileName)

        val tmpDir = ref NONE
        val tmpFiles = ref nil
        val count = ref 0
        val objectFiles = ref nil
        val nextDummyCodeFn = ref NONE

        fun tmpfile suffix =
            let
              val dir =
                  case !tmpDir of
                    SOME dir => dir
                  | NONE =>
                    let
                      val (file, dir) = mktemp_d mktempRetryCount
                    in
                      tmpFiles := file :: !tmpFiles;
                      tmpDir := SOME dir;
                      dir
                    end
              val _ = count := !count + 1;
              val filename = makeFilename (dir, basename, !count, suffix)
            in
              tmpFiles := filename :: !tmpFiles;
              filename
            end

        fun assemble asmCodeFn =
            let
              val objfile = tmpfile OBJEXT
              val asmfile =
                  if !Control.keepAsm
                  then makeFilename ("", outputFileName, !count, ASMEXT)
                  else replaceSuffix objfile ASMEXT

              val asmout = TextIO.openOut asmfile
              val _ =
                  try (fn _ => asmCodeFn (fn s => TextIO.output (asmout, s)))
                  finally (fn _ => TextIO.closeOut asmout)
                  if_error (fn _ => rm_f [asmfile])
                  end_try
            in
              if doAssemble then
                (try (fn _ => system (Configuration.CC ^ " " ^
                                      !Control.CFLAGS ^ " -c " ^ asmfile ^
                                      " -o " ^ objfile))
                 if_error (fn _ => rm_f [objfile])
                 finally (fn _ => if !Control.keepAsm
                                  then () else rm_f [asmfile])
                 end_try;
                 objectFiles := objfile :: !objectFiles)
              else ()
            end

        fun link (pre, post) files =
            let
              val maxSize = maxCommandLineSize - (size pre + size post)
              val preLD = Configuration.LD ^ " " ^
                          Configuration.LDFLAGS ^ " " ^
                          !Control.LDFLAGS ^ " " ^ " -r "

              fun loop (nil, linked) = loop (linked, nil)
                | loop (files, linked) =
                  case take maxSize (linked @ files) of
                    (args, nil) => system (pre ^ args ^ post)
                  | _ =>
                    case files of
                      [file] => loop (nil, linked @ [file])
                    | _ =>
                      let
                        val objfile = tmpfile OBJEXT
                        val postLD = " -o " ^ objfile
                        val maxSize = maxCommandLineSize
                                      - (size preLD + size postLD)
                        val (args, rest) = take2 maxSize files
                      in
                        system (preLD ^ args ^ postLD);
                        loop (rest, linked @ [objfile])
                      end
            in
              loop (files, nil)
            end

        fun archive outputFilename files =
            let
              val _ = rm_f [outputFilename]
              val pre = Configuration.AR ^ " qc " ^ outputFilename ^ " "
              val maxSize = maxCommandLineSize - size pre
              fun loop nil = ()
                | loop args =
                  let
                    val (args, rest) = take maxSize args
                  in
                    system (pre ^ args);
                    loop rest
                  end
            in
              loop files
            end

        fun execute (SessionTypes.ASMFILE {code, nextDummy}) =
            (assemble code;
             nextDummyCodeFn := nextDummy)
          | execute _ = raise Control.Bug "NativeStandAloneSession: execute"

        fun cleanup () =
            (
              rm_f (!tmpFiles);
              case !tmpDir of SOME dir => rmdir dir | NONE => ();
              tmpDir := NONE;
              tmpFiles := nil;
              count := 0;
              objectFiles := nil;
              nextDummyCodeFn := NONE
            )

        fun final () =
            let
              val _ = if (case compileMode of
                            Executable => true
                          | StaticLibrary => false
                          | ObjectFile {isPrelude} => not isPrelude
                          | AssemblyCode => true)
                      then
                        case !nextDummyCodeFn of
                          SOME codeFn => assemble codeFn
                        | NONE => ()
                      else ()

              val entry =
                  case entryObjectFileName of
                    SOME filename => filename ^ " "
                  | NONE => ""
              val prelude =
                  case preludeLibraryFileName of
                    SOME filename => filename ^ " "
                  | NONE => ""
              val objfiles = rev (!objectFiles)
            in
              case compileMode of
                Executable =>
                link (Configuration.CC ^ " " ^
                      Configuration.LDFLAGS ^
                      " -L" ^ Configuration.LibDirectory ^ " " ^
                      !Control.LDFLAGS ^ " " ^
                      entry ^ prelude,
                      " -lsmlsharp " ^ Configuration.LIBS ^
                      " -o " ^ outputFileName)
                     objfiles
              | StaticLibrary =>
                (
                  archive outputFileName objfiles;
                  system (Configuration.RANLIB ^ " " ^ outputFileName)
                )
              | ObjectFile _ =>
                link (Configuration.LD ^ " " ^
                      Configuration.LDFLAGS ^ " " ^
                      !Control.LDFLAGS ^ " " ^ " -r ",
                      " -o " ^ outputFileName)
                     objfiles
              | AssemblyCode => ()
            end

        fun close () =
            case (!objectFiles, !nextDummyCodeFn) of
              (nil, NONE) => ()
            | _ =>
              try final
              finally cleanup
              if_error (fn _ => rm_f [outputFileName])
              end_try
      in
        {
          execute = execute,
          close = close
        }
      end

end
