(**
 * temporary file management
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure TempFile : sig

  (* creates a fresh temporary file whose name is the given file name.
   * If an empty string is given, this function generates a random name.
   * If the given file name starts with ".", this function regards the
   * given name as a suffix and generates a name at random.
   *)
  val create : string -> Filename.filename
                                      
  val cleanup : unit -> unit

end =
struct
  val mktempRetryCount = 5
  val tmpDir = ref NONE : Filename.filename option ref
  val tmpFiles = ref nil : (Filename.filename * Filename.filename) list ref
  val tmpFileCount = ref 0

  fun mktemp_d retry =
      if retry <= 0
      then raise Fail "failed to make temporally directory"
      else
        let
          (*
           * Basis Library specification says that OS.FileSys.tmpName creates
           * a new file. tmpName of SML/NJ for UNIX doesn't create a file
           * because it is implemented by tmpnam(3).
           *)
          val tmpname = OS.FileSys.tmpName ()
          val tmpname = Filename.fromString tmpname
        in
          (CoreUtils.rm_f tmpname;
           CoreUtils.mkdir tmpname;
           tmpname)
          handle OS.SysErr _ => mktemp_d (retry - 1)
        end

  fun tmpDirName () =
      case !tmpDir of
        SOME dir => dir
      | NONE =>
        let
          val dirname = mktemp_d mktempRetryCount
        in
          tmpDir := SOME dirname;
          dirname
        end

  fun split template =
      let
        val ss = Substring.full template
        val (base, suffix) = Substring.splitr (fn c => c <> #".") ss
        val base = Substring.dropr (fn c => c = #".") base
      in
        (Substring.string base, Substring.string suffix)
      end

  fun makeFilename (dir, base, suffix, seqno) =
      let
        val num = StringCvt.padLeft #"0" 3 (Int.fmt StringCvt.DEC seqno)
        val base = if base = "" then num else base ^ "-" ^ num
        val filename = Filename.fromString base
        val absname = Filename.concatPath (dir, filename)
      in
        if suffix = "" then absname else Filename.addSuffix (absname, suffix)
      end

  fun freshName template =
      let
        val dir = tmpDirName ()
        val (base, suffix) = split template
        fun loop () =
            let
              val filename = makeFilename (dir, base, suffix, !tmpFileCount)
            in
              if CoreUtils.testExist filename
              then (tmpFileCount := !tmpFileCount + 1; loop ())
              else filename
            end
      in
        loop ()
      end

  fun create name =
      let
        val d = StringCvt.padLeft #"0" 3 (Int.fmt StringCvt.DEC (!tmpFileCount))
        val _ = tmpFileCount := !tmpFileCount + 1
        val name = if name = "" orelse String.isPrefix "." name
                   then "tmp_" ^ d ^ name
                   else name
        val tmpDir = tmpDirName ()
        val dir = Filename.concatPath (tmpDir, Filename.fromString d)
        val _ = CoreUtils.mkdir dir
        val tmpfile = Filename.concatPath (dir, Filename.fromString name)
        val _ = tmpFiles := (dir, tmpfile) :: !tmpFiles
      in
        CoreUtils.newFile tmpfile;
        tmpfile
      end

  fun cleanup () =
      (
        app (fn (dir, file) => (CoreUtils.rm_f file; CoreUtils.rmdir_f dir))
            (rev (!tmpFiles));
        Option.map CoreUtils.rmdir_f (!tmpDir);
        tmpDir := NONE;
        tmpFiles := nil;
        tmpFileCount := 0
      )

end
