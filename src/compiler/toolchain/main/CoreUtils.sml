(**
 * compiler toolchain support - core utils
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure CoreUtils : sig

  exception Failed of {command: string, message: string}

  val join : string list -> string
  val quote : string -> string

  val newFile : Filename.filename -> unit
  val testExist : Filename.filename -> bool
  val rm : Filename.filename -> unit
  val rm_f : Filename.filename -> unit
  val mkdir : Filename.filename -> unit
  val rmdir_f : Filename.filename -> unit
  val system : {command : string, quiet : bool} -> unit

  val makeTextFile : Filename.filename * string -> unit
  val makeBinFile : Filename.filename * Word8Vector.vector -> unit
  val makeTextFile' : Filename.filename * ((string -> unit) -> unit) -> unit
  val readTextFile : Filename.filename -> string
  val readBinFile : Filename.filename -> Word8Vector.vector

end =
struct

  exception Failed of {command: string, message: string}

  fun join args =
      String.concatWith " " args

  fun quote "" = "\"\""
    | quote x = x (* FIXME *)

  fun log msg =
      if !Control.printCommand
      then TextIO.output (TextIO.stdErr, msg ^ "\n")
      else ()

  fun handleSysErr (cmd, e) =
      case e of
        OS.SysErr (msg, _) =>
        (log ("FAILED: " ^ msg); raise Failed {command=cmd, message=msg})
      | _ => raise e

  fun ignoreSysErr e =
      case e of
        OS.SysErr (msg, _) => ()
      | _ => raise e

  fun newFile filename =
      BinIO.closeOut (BinIO.openOut (Filename.toString filename))

  fun testExist filename =
      (OS.FileSys.fileSize (Filename.toString filename); true)
      handle OS.SysErr _ => false

  fun rm filename =
      let
        val filename = Filename.toString filename
        val cmd = "rm " ^ filename
      in
        log cmd;
        OS.FileSys.remove filename handle e => handleSysErr (cmd, e)
      end

  fun rm_f filename =
      let
        val filename = Filename.toString filename
        val cmd = "rm -f " ^ filename
      in
        log cmd;
        OS.FileSys.remove filename handle e => ignoreSysErr e
      end

  fun mkdir filename =
      let
        val filename = Filename.toString filename
        val cmd = "mkdir " ^ filename
      in
        log cmd;
        OS.FileSys.mkDir filename handle e => handleSysErr (cmd, e)
      end

  fun rmdir_f filename =
      let
        val filename = Filename.toString filename
        val cmd = "rmdir " ^ filename
      in
        log cmd;
        OS.FileSys.rmDir filename handle e => ignoreSysErr e
      end

  fun system {command, quiet} =
      let
        val command =
            case (quiet, SMLSharp_Config.HOST_OS_TYPE ()) of
              (true, SMLSharp_Config.Unix) => command ^ " > /dev/null 2>&1"
            | (true, SMLSharp_Config.Cygwin) => command ^ " > /dev/null 2>&1"
            | (true, SMLSharp_Config.Mingw) => command ^ " > nul 2>&1"
            | (false, _) => command
      in
        log command;
        if OS.Process.isSuccess (OS.Process.system command)
        then ()
        else (log ("FAILED: command: " ^ command);
              raise Failed {command=command, message="command failed"})
      end

  fun makeTextFile (filename, content) =
      let
        val f = Filename.TextIO.openOut filename
        val _ = TextIO.output (f, content)
                handle e => (TextIO.closeOut f; rm_f filename; raise e)
      in
        TextIO.closeOut f
      end

  fun makeBinFile (filename, content) =
      let
        val f = Filename.BinIO.openOut filename
        val _ = BinIO.output (f, content)
                handle e => (BinIO.closeOut f; rm_f filename; raise e)
      in
        BinIO.closeOut f
      end

  fun makeTextFile' (filename, contentFn) =
      let
        val f = Filename.TextIO.openOut filename
        val () = contentFn (fn s => TextIO.output (f, s))
                 handle e => (TextIO.closeOut f; rm_f filename; raise e)
      in
        TextIO.closeOut f
      end

  fun readTextFile filename =
      let
        val f = Filename.TextIO.openIn filename
        val s = TextIO.inputAll f handle e => (TextIO.closeIn f; raise e)
      in
        TextIO.closeIn f;
        s
      end

  fun readBinFile filename =
      let
        val f = Filename.BinIO.openIn filename
        val s = BinIO.inputAll f handle e => (BinIO.closeIn f; raise e)
      in
        BinIO.closeIn f;
        s
      end
end
