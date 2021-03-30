(**
 * temporary file management
 * @copyright (C) 2021 SML# Development Team.
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
  datatype tmp_item = FILE | DIR 
  val tmpFiles = ref nil : (tmp_item * Filename.filename) list ref
  val tmpFileCount = ref 0

  fun mktemp_d retry =
      if retry <= 0
      then raise Fail "failed to make temporally directory"
      else
        let
          (*
           * Basis Library specification says that OS.FileSys.tmpName
           * creates a new file.  However, on combination of UNIX and SML/NJ,
           * OS.FileSys.tmpName does not create a file because it is
           * implemented by tmpnam(3).
           *)
          val tmpname = OS.FileSys.tmpName ()
          val tmpname = Filename.fromString tmpname
        in
          (CoreUtils.rm_f tmpname;
           CoreUtils.mkdir tmpname;
           tmpname)
          handle e as OS.SysErr (_, SOME n) =>
                 if OS.errorName n = "exist"
                 then mktemp_d (retry - 1)
                 else raise e
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

  fun freshName () =
      let
        val count = !tmpFileCount
        val _ = tmpFileCount := !tmpFileCount + 1;
        val s = Int.fmt StringCvt.DEC count
      in 
        if size s < 6
        then StringCvt.padLeft #"0" 6 s
        else s
      end

  fun create name =
      let
        val tmpDir = tmpDirName ()
        val tmpName = freshName ()
        val filename =
            if name = "" orelse String.isPrefix "." name then
              Filename.concatPath (tmpDir, Filename.fromString (tmpName ^ name))
            else
              let
                val tmpName = Filename.fromString tmpName
                val tmpDir = Filename.concatPath (tmpDir, tmpName)
              in
                CoreUtils.mkdir tmpDir;
                tmpFiles := (DIR, tmpDir) :: !tmpFiles;
                Filename.concatPath (tmpDir, Filename.fromString name)
              end
      in
        CoreUtils.newFile filename;
        tmpFiles := (FILE, filename) :: !tmpFiles;
        filename
      end

  fun cleanup () =
      let
        fun loop nil = ()
          | loop ((FILE, file) :: t) = (CoreUtils.rm_f file; loop t)
          | loop ((DIR, dir) :: t) = (CoreUtils.rmdir_f dir; loop t)
      in
        loop (!tmpFiles);
        Option.map CoreUtils.rmdir_f (!tmpDir);
        tmpDir := NONE;
        tmpFiles := nil;
        tmpFileCount := 0
      end

end
