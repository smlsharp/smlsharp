(**
 * interactive program execution
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)
structure Interactive =
struct

  datatype arg = datatype ShellUtils.arg

  val sml_gcroot_load =
      _import "sml_gcroot_load"
      : (codeptr vector, word) -> unit ptr

  exception UncaughtException of exn
  exception LinkError of exn

  fun isWindows () =
      case Config.HOST_OS_TYPE () of
        Config.Unix => false
      | Config.Cygwin => true
      | Config.Mingw => true

  type options =
      {baseFilename : Filename.filename option,
       loadPath : InterfaceName.source list,
       LDFLAGS : ShellUtils.arg list,
       LIBS : ShellUtils.arg list,
       llvmOptions : LLVMUtils.compile_options,
       outputWarnings : UserError.errorInfo list -> unit}

  type session =
      {options : options, libfiles : Filename.filename list ref}

  (* version number must be global since codes are loaded in the
   * global scope *)
  val version = ref 0

  fun start (options as {llvmOptions={systemBaseExecDir, ...}, ...}:options) =
      let
        val libfiles =
            if isWindows ()
            then [Filename.concatPaths
                    [systemBaseExecDir,
                     Filename.fromString "compiler",
                     Filename.fromString "smlsharp.lib"]]
            else nil
      in
        {options = options, libfiles = ref libfiles} : session
      end

  fun loadObj ({options={LDFLAGS, LIBS, ...}, libfiles}:session) objfiles =
      let
        val sofile = TempFile.create ("." ^ Config.DLLEXT ())
        val ldflags =
            case Config.HOST_OS_TYPE () of
              Config.Unix => nil
            | Config.Cygwin =>
              [ARG ("-Wl,-out-implib,"
                    ^ Filename.toString (Filename.replaceSuffix "lib" sofile))]
            | Config.Mingw =>
              [ARG ("-Wl,--out-implib="
                    ^ Filename.toString (Filename.replaceSuffix "lib" sofile))]
        val _ =
            BinUtils.link
              {flags = EXPAND (Config.RUNLOOP_DLDFLAGS ())
                       :: LDFLAGS @ ldflags,
               libs = map (ARG o Filename.toString) (!libfiles) @ LIBS,
               objects = map #objfile objfiles,
               dst = sofile,
               useCXX = false}
        val so =
            DynamicLink.dlopen' (Filename.toString sofile,
                                 DynamicLink.GLOBAL,
                                 DynamicLink.NOW)
        val _ =
            if isWindows ()
            then libfiles := Filename.replaceSuffix "lib" sofile :: !libfiles
            else ()
        val smlloads =
            map (fn {name, objfile} =>
                    DynamicLink.dlsym (so, ToplevelSymbol.loadName name))
                objfiles
        val _ = sml_gcroot_load (Vector.fromList smlloads,
                                 Word.fromInt (length smlloads))
        val smlmains =
            map (fn {name, objfile} =>
                    DynamicLink.dlsym (so, ToplevelSymbol.mainName name))
                objfiles
      in
        case smlmains of
          f::nil => f : _import () -> ()
        | _ => fn () => app (fn f => (f : _import () -> ()) ()) smlmains
      end

  fun load (session as {options={llvmOptions, ...}, ...}) bcfile =
      let
        val objfile = TempFile.create ("." ^ Config.OBJEXT ())
        val _ = #start Counter.llvmOutputTimeCounter()
        val _ = LLVMUtils.compile llvmOptions
                                  {srcfile = bcfile,
                                   dstfile = (LLVMUtils.ObjectFile, objfile)}
        val _ = #stop Counter.llvmOutputTimeCounter()
      in
        loadObj session [{objfile=objfile, name=NONE}]
      end

  fun run (session as {options={loadPath, llvmOptions, baseFilename,
                                outputWarnings, ...}, ...})
          context input =
      let
        val context = context # {version = InterfaceName.STEP (!version)}
        val topOptions = {stopAt = Top.NoStop,
                          baseFilename = baseFilename,
                          loadPath = loadPath,
                          loadMode = InterfaceName.COMPILE,
                          defaultInterface = fn x => x,
                          outputWarnings = outputWarnings} : Top.options
        val _ = Counter.reset ()
        val (_, result) = Top.compile llvmOptions topOptions context input
        val (newContext, bcfile) =
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
        val main = load session bcfile handle e => raise LinkError e
      in
        version := !version + 1;
        main () handle e => raise UncaughtException e;
        newContext
      end

  fun isLoaded name =
      let
        val mainName = ToplevelSymbol.mainName (SOME name)
      in
        (DynamicLink.dlsym' (DynamicLink.default (), mainName); true)
        handle DynamicLink.Error _ => false
      end

  type objfile =
      {objfile : Filename.filename, name : InterfaceName.interface_name}

  fun loadObjectFiles session objfiles =
      case List.filter (not o isLoaded o #name) objfiles of
        nil => ()
      | objfiles as _::_ =>
        let
          val objfiles =
              map (fn {name, objfile} => {name = SOME name, objfile = objfile})
                  objfiles
          val main = loadObj session objfiles handle e => raise LinkError e
        in
          main () handle e => raise UncaughtException e
        end
handle e as LinkError x =>
(print "LinkError: ";
 print (exnMessage x);
 print "\n";
 raise e)

end
