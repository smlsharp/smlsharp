(**
 * temporary file management
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure TempFile : sig

  (* takes a template of filename, and generates a fresh filename based on
   * the template, and create a file of that name.
   * The template must be of the form "<base>.<suffix>". ".<suffix>" may be
   * omitted. If the template is empty string, a random name will be used.
   *)
  val create : string -> Filename.filename

  val cleanup : unit -> unit

end =
struct
  val mktempRetryCount = 5
  val tmpDir = ref NONE : Filename.filename option ref
  val tmpFiles = ref nil : Filename.filename list ref
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

  fun create template =
      let
        val filename = freshName template
      in
        CoreUtils.newFile filename;
        tmpFiles := filename :: !tmpFiles;
        filename
      end

  fun cleanup () =
      (
        app CoreUtils.rm_f (rev (!tmpFiles));
        Option.map CoreUtils.rmdir_f (!tmpDir);
        tmpDir := NONE;
        tmpFiles := nil;
        tmpFileCount := 0
      )

end
