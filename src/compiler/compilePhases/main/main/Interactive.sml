(**
 * interactive program execution
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure Interactive =
struct

  val sml_run = _import "sml_run" : int -> ()

  exception UncaughtException of exn
  exception LinkError of exn

  fun isWindows () =
      case SMLSharp_Config.HOST_OS_TYPE () of
        SMLSharp_Config.Unix => false
      | SMLSharp_Config.Cygwin => true
      | SMLSharp_Config.Mingw => true

  type options =
      {baseFilename : Filename.filename option,
       stdPath : Filename.filename list,
       loadPath : Filename.filename list,
       LDFLAGS : string list,
       LIBS : string list,
       llvmOptions : LLVMUtils.compile_options,
       outputWarnings : UserError.errorInfo list -> unit}

  type session =
      {options : options, libfiles : Filename.filename list ref}

  (* version number must be global since codes are loaded in the
   * global scope *)
  val version = ref 0

  fun start (options as {llvmOptions={systemBaseDir, ...}, ...}:options) =
      let
        val libfiles =
            if isWindows ()
            then [Filename.concatPath
                    (systemBaseDir,
                     Filename.fromString "compiler/smlsharp.lib")]
            else nil
      in
        {options = options, libfiles = ref libfiles} : session
      end

  fun loadObj ({options={LDFLAGS, LIBS, ...}, libfiles}:session) objfiles =
      let
        val sofile = TempFile.create ("." ^ SMLSharp_Config.DLLEXT ())
        val ldflags =
            case SMLSharp_Config.HOST_OS_TYPE () of
              SMLSharp_Config.Unix => nil
            | SMLSharp_Config.Cygwin =>
              ["-Wl,-out-implib,"
               ^ Filename.toString (Filename.replaceSuffix "lib" sofile)]
            | SMLSharp_Config.Mingw =>
              ["-Wl,--out-implib="
               ^ Filename.toString (Filename.replaceSuffix "lib" sofile)]
        val _ =
            BinUtils.link
              {flags = SMLSharp_Config.RUNLOOP_DLDFLAGS () :: LDFLAGS @ ldflags,
               libs = map Filename.toString (!libfiles) @ LIBS,
               objects = objfiles,
               dst = sofile,
               useCXX = false,
               quiet = not (!Control.printCommand)}
        val so =
            DynamicLink.dlopen' (Filename.toString sofile,
                                 DynamicLink.GLOBAL,
                                 DynamicLink.NOW)
      in
        if isWindows ()
        then libfiles := Filename.replaceSuffix "lib" sofile :: !libfiles
        else ();
        so
      end

  fun load (session as {options={llvmOptions, ...}, ...}) module =
      let
        val objfile = TempFile.create ("." ^ SMLSharp_Config.OBJEXT ())
        val _ = #start Counter.llvmOutputTimeCounter()
        val _ = LLVMUtils.compile llvmOptions
                                  (module, LLVMUtils.ObjectFile, objfile)
        val _ = #stop Counter.llvmOutputTimeCounter()
        val _ = LLVM.LLVMDisposeModule module
      in
        loadObj session [objfile]
      end

  fun run (session as {options={stdPath, loadPath, llvmOptions, baseFilename,
                                outputWarnings, ...}, ...})
          context input =
      let
        val context = context # {version = SOME (!version)}
        val topOptions = {stopAt = Top.NoStop,
                          baseFilename = baseFilename,
                          stdPath = stdPath,
                          loadPath = loadPath,
                          loadMode = Top.COMPILE,
                          outputWarnings = outputWarnings} : Top.options
        val _ = Counter.reset ()
        val (_, result) = Top.compile llvmOptions topOptions context input
        val (newContext, module) =
            case result of
              Top.RETURN x => x
            | Top.STOPPED => raise Bug.Bug "run"
        (* If Control.interactiveMode is false, NameEval does not generate
         * EXPORT declarations.  To avoid inconsistency between the
         * toplevel context and exported symbol set, make newContext empty
         * if Control.interactiveMode is false. *)
        val newContext =
            if !Control.interactiveMode
            then newContext else Top.emptyNewContext
      in
        load session module handle e => raise LinkError e;
        version := !version + 1;
        sml_run 0 handle e => raise UncaughtException e;
        newContext
      end

  structure WSet =
    BinarySetFn(type ord_key = Word64.word val compare = Word64.compare)

  val toplevelIds = ref NONE

  val sml_toplevel_ids = _import "sml_toplevel_ids" : Word64.word ptr ref -> int

  fun getToplevelIds () =
      case !toplevelIds of
        SOME x => x
      | NONE =>
        let
          val idsptr = ref (Pointer.NULL ())
          val numIds = sml_toplevel_ids idsptr
          fun read s p 0 = s
            | read s p n =
              read (WSet.add (s, Pointer.load p)) (Pointer.advance (p, 1)) (n-1)
          val ids = read WSet.empty (!idsptr) numIds
        in
          toplevelIds := SOME ids;
          ids
        end

  type objfile = {objfile : Filename.filename, hash : InterfaceName.hash}

  fun loadObjectFiles session objfiles =
      let
        val (ids, objfilesRev) =
            foldl
              (fn ({objfile, hash}, z as (ids, objfilesRev)) =>
                  let
                    val hash = InterfaceName.hashToWord64 hash
                  in
                    if WSet.member (ids, hash)
                    then z
                    else (WSet.add (ids, hash), objfile :: objfilesRev)
                  end)
              (getToplevelIds (), nil)
              objfiles
      in
        case objfilesRev of
          nil => ()
        | _::_ =>
          (toplevelIds := SOME ids;
           loadObj session (rev objfilesRev) handle e => raise LinkError e;
           sml_run 1 handle e => raise UncaughtException e;
           ())
      end

end
