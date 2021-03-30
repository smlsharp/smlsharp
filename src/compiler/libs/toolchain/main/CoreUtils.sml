(**
 * compiler toolchain support - core utils
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)
structure CoreUtils : sig

  val newFile : Filename.filename -> unit
  val testExist : Filename.filename -> bool
  val testDir : Filename.filename -> bool
  val rm_f : Filename.filename -> unit
  val mkdir : Filename.filename -> unit
  val rmdir_f : Filename.filename -> unit
  val chdir : Filename.filename -> (unit -> 'a) -> 'a

  val makeTextFile : Filename.filename * string -> unit
  val makeBinFile : Filename.filename * Word8Vector.vector -> unit
  val makeTextFile' : Filename.filename * ((string -> unit) -> unit) -> unit
  val readTextFile : Filename.filename -> string
  val readBinFile : Filename.filename -> Word8Vector.vector

  val cp : Filename.filename -> Filename.filename -> unit
  val cat : Filename.filename list -> TextIO.outstream -> unit

end =
struct

  fun log msg =
      if !Control.printCommand
      then TextIO.output (TextIO.stdErr, msg ^ "\n")
      else ()

  fun newFile filename =
      BinIO.closeOut (BinIO.openAppend (Filename.toString filename))

  fun testExist filename =
      (OS.FileSys.fileSize (Filename.toString filename); true)
      handle e as OS.SysErr (_, SOME n) =>
             case OS.errorName n of
               "noent" => false
             | "efault" => false
             | "acces" => true
             | _ => raise e

  fun testDir filename =
      OS.FileSys.isDir (Filename.toString filename)
      handle e as OS.SysErr (_, SOME n) =>
             case OS.errorName n of
               "noent" => false
             | "efault" => false
             | "acces" => true
             | _ => raise e

  fun rm_f filename =
      let
        val filename = Filename.toString filename
      in
        log ("rm -f " ^ filename);
        OS.FileSys.remove filename
        handle e as OS.SysErr (_, SOME n) =>
               case OS.errorName n of
                 "noent" => ()
               | "efault" => ()
               | "acces" => ()
               | "isdir" => ()
               | _ => raise e
      end

  fun mkdir filename =
      let
        val filename = Filename.toString filename
      in
        log ("mkdir " ^ filename);
        OS.FileSys.mkDir filename
      end

  fun rmdir_f filename =
      let
        val filename = Filename.toString filename
      in
        log ("rmdir " ^ filename);
        OS.FileSys.rmDir filename
        handle e as OS.SysErr (_, SOME n) =>
               case OS.errorName n of
                 "noent" => ()
               | "efault" => ()
               | "acces" => ()
               | "notdir" => ()
               | _ => raise e
      end

  fun chdir filename f =
      let
        val oldpwd = OS.FileSys.getDir ()
        val _ = OS.FileSys.chDir (Filename.toString filename)
      in
        (f () before OS.FileSys.chDir oldpwd)
        handle e => (OS.FileSys.chDir oldpwd; raise e)
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

  fun copyBin s d =
      let
        val buf = BinIO.inputN (s, 4092)
      in
        if Word8Vector.length buf = 0
        then ()
        else (BinIO.output (d, buf); copyBin s d)
      end

  fun copyText s d =
      let
        val buf = TextIO.inputN (s, 4092)
      in
        if size buf = 0
        then ()
        else (TextIO.output (d, buf); copyText s d)
      end

  fun cp src dst =
      let
        val cmd = "cp " ^ Filename.toString src ^ " " ^ Filename.toString dst
        val _ = log cmd
        val s = Filename.BinIO.openIn src
      in
        let
          val d = Filename.BinIO.openOut dst
        in
          copyBin s d handle e => (BinIO.closeOut d; raise e);
          BinIO.closeOut d
        end
        handle e => (BinIO.closeIn s; raise e);
        BinIO.closeIn s
      end

  fun cat nil dst = ()
    | cat (file :: files) dst =
      let
        val s = Filename.TextIO.openIn file
      in
        copyText s dst handle e => (TextIO.closeIn s; raise e);
        TextIO.closeIn s;
        cat files dst
      end

end
