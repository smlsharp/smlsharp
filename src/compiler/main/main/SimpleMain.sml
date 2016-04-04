(**
 * simple main entry for separate compilation
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure Main : sig

  val main : string * string list -> OS.Process.status

end =
struct

  structure I = InterfaceName

  exception Error of string list

  val defaultSystemBaseDir =
      case ExecutablePath.getPath () of
        NONE => Filename.fromString SMLSharp_Version.DefaultSystemBaseDir
      | SOME path =>
        Filename.concatPath
          (Filename.dirname (Filename.fromString path),
           Filename.fromString "../lib/smlsharp")

  fun Ignore f () = (f (); ())
  fun Sequence l () = app (fn f => f ()) l
  fun Const x () = x

  fun thunk f =
      let
        val r = ref NONE
      in
        fn () => case !r of
                   SOME x => x
                 | NONE => let val x = f () in r := SOME x; x end
      end

  (* loading builtin.smi is delayed until it is needed. *)
  fun LoadBuiltin systemBaseDir =
      thunk (fn () => Top.loadBuiltin
                        (Filename.concatPath
                           (systemBaseDir, Filename.fromString "builtin.smi")))

  fun printErr s =
      TextIO.output (TextIO.stdErr, s)

  fun PrintVersion ({triple, ...}:LLVMUtils.compile_options) () =
      print ("SML# " ^ SMLSharp_Version.Version
             ^ " (" ^ SMLSharp_Version.ReleaseDate ^ ") for "
             ^ triple
             ^ " with LLVM " ^ LLVM.getVersion ()
             ^ "\n")

  local
    fun userErrorToString e =
        Control.prettyPrint (UserError.format_errorInfo e)
    fun locToString loc =
        Control.prettyPrint (Loc.format_loc loc)
(*
    fun printExnHistory e =
        case rev (SMLofNJ.exnHistory e) of
          nil => ()
        | h::t => (printErr ("    raised at: " ^ h ^ "\n");
                   case t of
                     nil => ()
                   | h::t => (printErr ("   handled at: " ^ h ^ "\n");
                              app (fn s => printErr ("\t\t" ^ s ^ "\n")) t))
*)
    fun sysErrToString (msg, err) =
        case err of
          NONE => msg
        | SOME err => msg ^ " (" ^ OS.errorName err ^ ")"
  in

  fun printExn progname e =
      case e of
        Error msgs =>
        app (fn x => printErr (progname ^ ": " ^ x ^ "\n")) msgs
      | UserError.UserErrors errs =>
        app (fn e => printErr (userErrorToString e ^ "\n")) errs
      | UserError.UserErrorsWithoutLoc errs =>
        app (fn (k,e) => printErr (userErrorToString (Loc.noloc,k,e) ^ "\n"))
            errs
      | LLVM.LLVMError msg =>
        printErr ("LLVM error: " ^ msg ^ "\n")
      | IO.Io {name, function, cause} =>
        printErr ("IO: " ^ function ^ ": " ^ name ^ ": "
                  ^ (case cause of
                       OS.SysErr x => sysErrToString x
                     | e => exnName e)
                  ^ "\n")
      | OS.SysErr x =>
        printErr ("SysErr: " ^ sysErrToString x ^ "\n")
      | _ =>
        printErr ("uncaught exception: " ^ exnMessage e ^ "\n")

  end (* local *)

  datatype compilerMode =
      CompileOnly
    | AssemblyOnly
    | SyntaxOnly
    | TypeCheckOnly
    | MakeDependCompile of {noStdPath: bool}
    | MakeDependLink of {noStdPath: bool}

  datatype commandLineArgs =
      OutputFile of string
    | IncludePath of string
    | LibraryPath of string
    | Library of string
    | OptLevel of LLVMUtils.opt_level
    | RelocModel of LLVMUtils.reloc_model
    | TargetTriple of string
    | TargetArch of string
    | TargetCPU of string
    | TargetAttrs of string
    | Mode of compilerMode
    | SourceFile of string
    | SystemBaseDir of string
    | LinkerFlags of string list
    | LLCFlags of string list
    | OPTFlags of string list
    | Help
    | ControlSwitch of string option
    | NoStdPath
    | NoStdLib
    | Verbose
    | UseCXX
    | LinkAll
    | EmitLLVM
    | FileMap of string

  val optionDesc =
      let
        fun splitComma s = String.fields (fn c => #"," = c) s
        open GetOpt
      in
        [
          SHORT (#"o", REQUIRED OutputFile),
          SHORT (#"c", NOARG (Mode CompileOnly)),
          SHORT (#"S", NOARG (Mode AssemblyOnly)),
          SHORT (#"I", REQUIRED IncludePath),
          SHORT (#"L", REQUIRED LibraryPath),
          SHORT (#"l", REQUIRED Library),
          SHORT (#"v", NOARG Verbose),
          SHORT (#"B", REQUIRED SystemBaseDir),
          SHORT (#"M", NOARG (Mode (MakeDependCompile {noStdPath=false}))),
          SLONG ("O0", NOARG (OptLevel LLVMUtils.O0)),
          SLONG ("O1", NOARG (OptLevel LLVMUtils.O1)),
          SLONG ("O", NOARG (OptLevel LLVMUtils.O2)),
          SLONG ("O2", NOARG (OptLevel LLVMUtils.O2)),
          SLONG ("O3", NOARG (OptLevel LLVMUtils.O3)),
          SLONG ("Os", NOARG (OptLevel LLVMUtils.Os)),
          SLONG ("Oz", NOARG (OptLevel LLVMUtils.Oz)),
          DLONG ("target", REQUIRED TargetTriple),
          SLONG ("march", REQUIRED TargetArch),
          SLONG ("mcpu", REQUIRED TargetCPU),
          SLONG ("mattr", REQUIRED TargetAttrs),
          SLONG ("fpic", NOARG (RelocModel LLVMUtils.RelocPIC)),
          SLONG ("fPIC", NOARG (RelocModel LLVMUtils.RelocPIC)),
          SLONG ("fno-pic", NOARG (RelocModel LLVMUtils.RelocStatic)),
          SLONG ("mdynamic-no-pic",
                 NOARG (RelocModel LLVMUtils.RelocDynamicNoPIC)),
          SLONG ("MM", NOARG (Mode (MakeDependCompile {noStdPath=true}))),
          SLONG ("Ml", NOARG (Mode (MakeDependLink {noStdPath=false}))),
          SLONG ("MMl", NOARG (Mode (MakeDependLink {noStdPath=true}))),
          SLONG ("Wl", REQUIRED (fn x => LinkerFlags (splitComma x))),
          SLONG ("Xlinker", REQUIRED (fn x => LinkerFlags [x])),
          SLONG ("Xllc", REQUIRED (fn x => LLCFlags [x])),
          SLONG ("Xopt", REQUIRED (fn x => OPTFlags [x])),
          SLONG ("fsyntax-only", NOARG (Mode SyntaxOnly)),
          SLONG ("ftypecheck-only", NOARG (Mode TypeCheckOnly)),
          SLONG ("emit-llvm", NOARG EmitLLVM),
          SLONG ("c++", NOARG UseCXX),
          DLONG ("link-all", NOARG LinkAll),
          SLONG ("filemap", REQUIRED FileMap),
          SLONG ("nostdpath", NOARG NoStdPath),
          SLONG ("nostdlib", NOARG NoStdLib),
          DLONG ("help", NOARG Help),
          SHORT (#"d", OPTIONAL ControlSwitch)
        ]
      end

  fun modeToOption mode =
      case mode of
        CompileOnly => "-c"
      | AssemblyOnly => "-S"
      | SyntaxOnly => "-fsyntax-only"
      | TypeCheckOnly => "-ftypecheck-only"
      | MakeDependCompile {noStdPath=false} => "-M"
      | MakeDependCompile {noStdPath=true} => "-MM"
      | MakeDependLink {noStdPath=false} => "-Ml"
      | MakeDependLink {noStdPath=true} => "-MMl"

  fun usageMessage progname =
    "Usage: " ^ progname ^ " [options] file ...\n\
    \Options:\n\
    \  --help             print this message\n\
    \  -v                 verbose mode\n\
    \  -o <file>          place the output to <file>\n\
    \  -c                 compile and assemble; do not link\n\
    \  -S                 compile only; do not assemble and link\n\
    \  -emit-llvm         emit LLVM code instead of native machine code\n\
    \  -O[0-3]            set optimization level to 0-3\n\
    \  -Os                optimize for code size\n\
    \  -Oz                optimize for code size aggressively\n\
    \  --target=<triple>  generate code for specified target\n\
    \  -march=<arch>      target a specific architecture\n\
    \  -mcpu=<cpu>        target a specific CPU type\n\
    \  -mattr=<attrs,...> target specific attributes\n\
    \  -mcmodel=<model>   set x86-64 code model (small, kernel, medium or large\n\
    \  -fpic              generate position independent code if possible\n\
    \  -fno-pic           don't generate position independent code\n\
    \  -mdynamic-no-pic   generate absolute addressing code suitable for executables\n\
    \  -M                 make dependency for compile\n\
    \  -MM                make dependency for compile but ignore system files\n\
    \  -Ml                make dependency for link\n\
    \  -MMl               make dependency for link but ignore system files\n\
    \  -c++               use C++ compiler driver as linker\n\
    \  -fsyntax-only      check for syntax errors, and exit\n\
    \  -ftypecheck-only   check for type errors, and exit\n\
    \  -filemap=<file>    specify a map from interface files to object files\n\
    \  -I <dir>           add <dir> to file search path\n\
    \  -L <dir>           add <dir> to library path of the linker\n\
    \  -l <libname>       link with <libname> to create an executable file\n\
    \  -Wl,<args>         pass comma-separated <args> to the linker\n\
    \  -Xlinker <arg>     pass <arg> to the linker\n\
    \  -Xllc <arg>        pass <arg> to llc command\n\
    \  -Xopt <arg>        pass <arg> to opt command\n\
    \  -nostdpath         no standard file search path is used\n\
    \  -d <key>=<value>   set extra option for compiler developers\n\
    \  -d                 print list of extra options\n"

  fun extraOptionUsageMessage () =
    "\n\
    \Extra options for compiler developers:\n\
    \  WARNING: The following options are for compiler developers only.\n\
    \           Don't specify them if you don't know what you do.\n\
    \\n\
    \key                        default  description\n"
    ^ String.concat
        (map
           (fn (name, desc, s) =>
               StringCvt.padRight #" " 26 name ^ " " ^
               StringCvt.padRight #" " 8 (Control.switchToString s) ^ " " ^
               desc ^ "\n")
           Control.switchTable)

  fun PrintHelp {progname, forDevelopers} () =
      (
        #start Counter.printHelpTimeCounter();
        print (usageMessage progname);
        if forDevelopers then print (extraOptionUsageMessage ()) else ();
        #stop Counter.printHelpTimeCounter()
      )

  fun parseArgs args =
      let
        val args = GetOpt.getopt optionDesc args
            handle GetOpt.NoArg name =>
                   raise Error ["option `" ^ name ^ "' requires an argument"]
                 | GetOpt.HasArg name =>
                   raise Error ["option `" ^ name ^ "' requires no argment"]
                 | GetOpt.Unknown name =>
                   raise Error ["invalid option `" ^ name ^ "'"]
      in
        map (fn GetOpt.ARG x => SourceFile x | GetOpt.OPTION x => x) args
      end

  type link_options =
       {systemBaseDir: Filename.filename,
        noStdLib: bool,
        useCXX: bool,
        LDFLAGS: string list,
        LIBS: string list,
        dstfile: Filename.filename}

  type depend_options =
       {noStdPath: bool,
        target: string,
        source: string}

  fun compileLLVMModule llvmOptions (module, fileType, dstfile) =
      (#start Counter.llvmOutputTimeCounter ();
       LLVMUtils.compile llvmOptions (module, fileType, dstfile);
       #stop Counter.llvmOutputTimeCounter ();
       LLVM.LLVMDisposeModule module)

  fun LLVMCompile (llvmOptions, moduleFn, fileType, dstfile) () =
      compileLLVMModule llvmOptions (moduleFn (), fileType, dstfile)

  fun compileLLVMModuleToObj llvmOptions module =
      let
        val dstfile = TempFile.create ("." ^ SMLSharp_Config.OBJEXT ())
      in
        compileLLVMModule llvmOptions (module, LLVMUtils.ObjectFile, dstfile);
        dstfile
      end

  fun loadBitcode filename =
      let
        val context = LLVM.LLVMGetGlobalContext ()
        val filename = Filename.toString filename
        val buf = LLVM.LLVMCreateMemoryBufferWithContentsOfFile filename
        val module = LLVM.LLVMParseBitcodeInContext (context, buf)
                     handle e => (LLVM.LLVMDisposeMemoryBuffer buf; raise e)
      in
        LLVM.LLVMDisposeMemoryBuffer buf;
        module
      end
      handle LLVM.LLVMError msg =>
             raise Error [Filename.toString filename ^ ": " ^ msg]

  datatype object_file =
      OBJ of Filename.filename
    | BC of Filename.filename

  datatype link_object =
      FILE of object_file
    | AR of object_file list
    | MODULE of LLVM.LLVMModuleRef

  fun OBJorBC filename =
      if Filename.suffix filename = SOME LLVM.OBJEXT
      then BC filename
      else OBJ filename

  fun evalObjectFile llvmOptions linkFile =
      case linkFile of
        BC bcfile => compileLLVMModuleToObj llvmOptions (loadBitcode bcfile)
      | OBJ objfile =>
        if CoreUtils.testExist objfile
        then objfile
        else raise Error ["file not found: " ^ Filename.toString objfile]

  fun evalLinkObject llvmOptions linkObj =
      case linkObj of
        FILE file => SOME (evalObjectFile llvmOptions file)
      | MODULE module => SOME (compileLLVMModuleToObj llvmOptions module)
      | AR nil => NONE
      | AR objs =>
        let
          val objfiles = map (evalObjectFile llvmOptions) objs
          val arfile = TempFile.create ("." ^ SMLSharp_Config.LIBEXT ())
        in
          BinUtils.archive {objects = objfiles, archive = arfile};
          SOME arfile
        end

  fun Link (llvmOptions,
            {systemBaseDir, noStdLib, useCXX, LDFLAGS, LIBS, dstfile},
            linkObjectFns) () =
      let
        val linkObjs = List.concat (map (fn f => f ()) linkObjectFns)
        val objfiles = List.mapPartial (evalLinkObject llvmOptions) linkObjs
        val runtimeDir = Filename.fromString "runtime"
        val runtimeDir = Filename.concatPath (systemBaseDir, runtimeDir)
        val libsmlsharp = Filename.fromString "libsmlsharp.a"
        val libsmlsharp = Filename.concatPath (runtimeDir, libsmlsharp)
        val smlsharpEntry = Filename.fromString "main.o"
        val smlsharpEntry = Filename.concatPath (runtimeDir, smlsharpEntry)
        val libs =
            if noStdLib then LIBS else Filename.toString libsmlsharp :: LIBS
        val objects =
            if noStdLib then objfiles else objfiles @ [smlsharpEntry]
      in
        BinUtils.link {flags = LDFLAGS,
                       libs = libs,
                       objects = objects,
                       dst = dstfile,
                       useCXX = useCXX,
                       quiet = false}
      end

  fun CompileSML (llvmOptions, topOptions, contextFn, smlFilename) () =
      let
        val context = contextFn ()
        val io = Filename.TextIO.openIn smlFilename
        val (depends, result) =
            Top.compile llvmOptions topOptions context
                        (Parser.setup
                           {mode = Parser.File,
                            read = fn (_,n) => TextIO.inputN (io, n),
                            sourceName = Filename.toString smlFilename,
                            initialLineno = 1})
            handle e => (TextIO.closeIn io; raise e)
        val _ = TextIO.closeIn io
        val module =
            case result of
              Top.RETURN (_, module) => SOME module
            | Top.STOPPED => NONE
      in
        {module = module, dependency = depends}
      end

  fun LoadSMI (options, contextFn, smiFilename) () =
      let
        val context = contextFn ()
        val (dependency, _) = Top.loadInterface options context smiFilename
      in
        {module = NONE, dependency = dependency}
      end

  fun ModuleOf compileFn () =
      case compileFn () of
        {module = NONE, ...} => raise Bug.Bug "ModuleOf"
      | {module = SOME module, ...} => module

  fun LoadFileMap NONE = (fn () => NONE)
    | LoadFileMap (SOME filename) =
      SOME
      o thunk (fn () => FilenameMap.load filename
                        handle FilenameMap.Load msg=>
                               raise Error [Filename.toString filename
                                            ^ ": failed to read filemap: "
                                            ^ msg])

  fun interfaceNameToObjectFile fileMap interfaceName =
      let
        fun toObjFile smifile =
            Filename.replaceSuffix (SMLSharp_Config.OBJEXT ()) smifile
        val objfile =
            case interfaceName of
              {hash, source = (I.STDPATH, path)} => toObjFile path
            | {hash, source = (I.LOCALPATH, path)} =>
              case fileMap of
                NONE => toObjFile path
              | SOME fileMap =>
                case FilenameMap.find (fileMap, path) of
                  SOME filename => filename
                | NONE => raise Error ["object file is not found in filemap: "
                                       ^ Filename.toString path]
      in
        OBJorBC objfile
      end

  fun ToLinkObjects ({linkAll}, fileMapFn, compileFn) () =
      let
        val fileMap = fileMapFn ()
        val (mainObj, requires) =
            case compileFn () of
              {module = SOME module,
               dependency = {link, ...} : InterfaceName.dependency} =>
              (MODULE module, link)
            | {module = NONE,
               dependency = {interfaceNameOpt = SOME name, link, ...}} =>
              (FILE (interfaceNameToObjectFile fileMap name), link)
            | {module = NONE,
               dependency = {interfaceNameOpt = NONE, link, ...}} =>
              raise Error ["invalid interface as program entry"]
        val requireObjs = map (interfaceNameToObjectFile fileMap) requires
      in
        if linkAll
        then mainObj :: map FILE requireObjs
        else [mainObj, AR requireObjs]
      end

  fun Interactive (options, contextFn) () =
      let
        val context = contextFn ()
        val newContext =
            Top.loadInteractiveEnv
              {stopAt = Top.NoStop,
               stdPath = [#systemBaseDir options],
               loadPath = nil}
              context
              (Filename.concatPath
                 (#systemBaseDir options, Filename.fromString "prelude.smi"))
        val context = Top.extendContext (context, newContext)
        val context = Top.incVersion context
      in
        RunLoop.interactive options context
      end

  fun PrintTo (NONE, f) () = f TextIO.stdOut ()
    | PrintTo (SOME outputFilename, f) () =
      let
        val out = Filename.TextIO.openOut outputFilename
        val () = f out () handle e => (TextIO.closeOut out; raise e)
      in
        TextIO.closeOut out
      end

  local
    fun format w nil = nil
      | format w (h::t) =
        let
          val n = size h
        in
          if w = 0
          then h :: format n t
          else if w + 1 + n > 78
          then " \\\n " :: h :: format (1 + n) t
          else " " :: h :: format (w + 1 + n) t
        end
  in
  fun printMakeRule out (target, sources) =
      (app (fn s => TextIO.output (out, s))
           (format 0 (target ^ ":" :: sources));
       TextIO.output (out, "\n"))
  end (* local *)

  fun filterLOCALPATH files =
      List.filter (fn (I.LOCALPATH, _) => true | (I.STDPATH, _) => false) files

  fun PrintDependCompile ({noStdPath, target, source, out}, compileFn) () =
      let
        val {compile, ...} : InterfaceName.dependency =
            #dependency (compileFn ())
        val depfiles =
            if noStdPath
            then filterLOCALPATH compile
            else compile
        val depfiles = map (fn (_,x) => Filename.toString x) depfiles
        val target = Filename.toString target
        val source = Filename.toString source
      in
        printMakeRule out (target, source :: depfiles)
      end

  fun PrintDependLink ({noStdPath, target, source, out}, compileFn) () =
      let
        val interfaces =
            case #dependency (compileFn ()) : InterfaceName.dependency of
              {interfaceNameOpt = SOME name, link, ...} => link @ [name]
            | {interfaceNameOpt = NONE, link, ...} => link
        val depfiles = map #source interfaces
        val depfiles =
            if noStdPath
            then filterLOCALPATH depfiles
            else depfiles
        val depfiles =
            map (fn (_,x) =>
                    Filename.toString
                      (Filename.replaceSuffix (SMLSharp_Config.OBJEXT ()) x))
                depfiles
        val target = Filename.toString target
        val source = Filename.toString source
      in
        printMakeRule out (target, depfiles)
      end

  fun setExtraOption src =
      let
        val ss = Substring.full src
        val (key, value) = Substring.splitl (fn c => #"=" <> c) ss
        val key = Substring.string key
        val value = Substring.string (Substring.triml 1 value)
      in
        case List.find (fn (x,_,_) => key = x) Control.switchTable of
          NONE =>
          raise Error ["unknown extra option `" ^ key ^ "'"]
        | SOME (_, _, switch) =>
          (
            Control.interpretControlOption (key, switch, value)
            handle Fail msg => raise Error [msg]
          )
      end

  fun toAsmTarget filename =
      Filename.replaceSuffix (SMLSharp_Config.ASMEXT ()) filename
  fun toObjTarget filename =
      Filename.replaceSuffix (SMLSharp_Config.OBJEXT ()) filename
  fun toLLTarget filename =
      Filename.replaceSuffix LLVM.ASMEXT filename
  fun toBCTarget filename =
      Filename.replaceSuffix LLVM.OBJEXT filename
  fun toExeTarget filename =
      Filename.removeSuffix filename

  fun defaultExeTarget () =
      case SMLSharp_Config.HOST_OS_TYPE () of
        SMLSharp_Config.Mingw => Filename.fromString "a.exe"
      | _ => Filename.fromString "a.out"

  fun interpretArgs (progname, args) =
      let
        val options =
            {
              systemBaseDir = NONE,
              noStdPath = false,
              noStdLib = false,
              loadPath = nil,
              LDFLAGS = nil,
              LIBS = nil,
              optLevel = LLVMUtils.O0,
              relocModel = NONE,
              LLCFLAGS = nil,
              OPTFLAGS = nil,
              triple = NONE,
              march = "",
              mcpu = "",
              mattr = "",
              outputFilename = NONE,
              sources = nil,
              verbose = false,
              help = NONE,
              mode = NONE,
              extraOptionsRev = nil,
              fileMap = NONE,
              useCXX = false,
              linkAll = false,
              emitLLVM = false
            }
        fun processArg (arg, opt) =
            case arg of
              OutputFile filename =>
              opt # {outputFilename = SOME (Filename.fromString filename)}
            | IncludePath path =>
              opt # {loadPath = #loadPath opt @ [Filename.fromString path]}
            | LibraryPath path =>
              opt # {LDFLAGS = #LDFLAGS opt @ ["-L" ^ path]}
            | Library lib =>
              opt # {LIBS = #LIBS opt @ ["-l" ^ lib]}
            | OptLevel level =>
              opt # {optLevel = level}
            | RelocModel mode =>
              opt # {relocModel = SOME mode}
            | TargetTriple s =>
              opt # {triple = SOME s}
            | TargetArch arch =>
              opt # {march = arch}
            | TargetCPU cpu =>
              opt # {mcpu = cpu}
            | TargetAttrs attr =>
              opt # {mattr = attr}
            | UseCXX =>
              opt # {useCXX = true}
            | LinkAll =>
              opt # {linkAll = true}
            | EmitLLVM =>
              opt # {emitLLVM = true}
            | NoStdPath =>
              opt # {noStdPath = true}
            | NoStdLib =>
              opt # {noStdLib = true}
            | SourceFile filename =>
              opt # {sources = #sources opt @ [Filename.fromString filename]}
            | SystemBaseDir filename =>
              opt # {systemBaseDir = SOME (Filename.fromString filename)}
            | LinkerFlags flags =>
              opt # {LDFLAGS = #LDFLAGS opt @ flags}
            | LLCFlags flags =>
              opt # {LLCFLAGS = #LLCFLAGS opt @ flags}
            | OPTFlags flags =>
              opt # {OPTFLAGS = #OPTFLAGS opt @ flags}
            | FileMap filename =>
              opt # {fileMap = SOME (Filename.fromString filename)}
            | ControlSwitch (SOME pair) =>
              opt # {extraOptionsRev = pair :: #extraOptionsRev opt}
            | ControlSwitch NONE =>
              opt # {help = SOME true}
            | Help =>
              opt # {help = SOME false}
            | Verbose =>
              opt # {verbose = true}
            | Mode newMode =>
              case #mode opt of
                NONE => opt # {mode = SOME newMode}
              | SOME oldMode =>
                if oldMode = newMode then opt
                else raise Error ["cannot specify " ^ modeToOption oldMode
                                  ^ " with " ^ modeToOption newMode]

        val options = foldl processArg options args

        (* If -B option is specified, SML# compiler reads "config.mk" file
         * in the given directory and configures the compiler itself
         * according to the config.mk file.  Otherwise, SML# compiler
         * uses built-in configurations. *)
        val _ =
            case #systemBaseDir options of
              NONE => ()
            | SOME systemBaseDir =>
              SMLSharp_Config.loadConfig systemBaseDir
              handle SMLSharp_Config.Load =>
                     raise Error ["failed to read config.mk. Specify"
                                  ^ " correct path by -B option."]

        val _ = Control.printCommand := #verbose options
        val _ = app setExtraOption (SMLSharp_Config.EXTRA_OPTIONS ())
        val _ = app setExtraOption (rev (#extraOptionsRev options))

        val systemBaseDir =
            case #systemBaseDir options of
              NONE => defaultSystemBaseDir
            | SOME dir => dir

        val triple =
            case #triple options of
              NONE => SMLSharp_Config.TARGET_TRIPLE ()
            | SOME x => x

        val relocModel =
            case #relocModel options of
              SOME mode => mode
            | NONE => if SMLSharp_Config.PIC_DEFAULT ()
                      then LLVMUtils.RelocPIC
                      else LLVMUtils.RelocDefault

        val stdPath =
            if #noStdPath options then nil else [systemBaseDir]

        val BuiltinContext = LoadBuiltin systemBaseDir
        val UserFileMap = LoadFileMap (#fileMap options)

        val llvmOptions =
            {systemBaseDir = systemBaseDir,
             triple = triple,
             arch = #march options,
             cpu = #mcpu options,
             features = #mattr options,
             optLevel = #optLevel options,
             relocModel = relocModel,
             LLCFLAGS = #LLCFLAGS options,
             OPTFLAGS = #OPTFLAGS options} : LLVMUtils.compile_options

        fun defaultAsmTarget srcfile =
            if #emitLLVM options
            then toLLTarget srcfile else toAsmTarget srcfile
        fun defaultObjTarget srcfile =
            if #emitLLVM options
            then toBCTarget srcfile else toObjTarget srcfile
        fun WriteAsm dstfile module =
            LLVMCompile
              (llvmOptions,
               module,
               if #emitLLVM options
               then LLVMUtils.IRFile else LLVMUtils.AssemblyFile,
               dstfile)
        fun WriteObj dstfile module =
            LLVMCompile
              (llvmOptions,
               module,
               if #emitLLVM options
               then LLVMUtils.BitcodeFile else LLVMUtils.ObjectFile,
               dstfile)
        fun LoadSmi stopAt srcfile =
            LoadSMI ({stopAt = stopAt,
                      stdPath = stdPath,
                      loadPath = #loadPath options,
                      loadAllInterfaceFiles = true},
                     BuiltinContext,
                     srcfile)
        fun CompileSml' loadAll stopAt srcfile =
            CompileSML (llvmOptions,
                        {stopAt = stopAt,
                         baseFilename = SOME srcfile,
                         stdPath = stdPath,
                         loadPath = #loadPath options,
                         loadAllInterfaceFiles = loadAll},
                        BuiltinContext,
                        srcfile)
        fun CompileSml stopAt srcfile = CompileSml' false stopAt srcfile
        fun Load' stopAt loadAll srcfile =
            case Filename.suffix srcfile of
              SOME "smi" => LoadSmi stopAt srcfile
            | _ => CompileSml' loadAll stopAt srcfile
        fun Load stopAt srcfile = Load' stopAt false srcfile
        fun LoadAll stopAt srcfile = Load' stopAt true srcfile
      in
        case options of
          {help = SOME devhelp, ...} =>
          PrintHelp {progname = progname, forDevelopers = devhelp}
        | {mode = NONE, sources = nil, ...} =>
          if #verbose options
          then PrintVersion llvmOptions
          else Sequence
                 [PrintVersion llvmOptions,
                  Interactive ({systemBaseDir = systemBaseDir,
                                stdPath = stdPath,
                                loadPath = #loadPath options,
                                LDFLAGS = #LDFLAGS options,
                                LIBS = #LIBS options,
                                llvmOptions = llvmOptions,
                                errorOutput = TextIO.stdOut},
                               BuiltinContext)]
        | {mode = SOME _, sources = nil, ...} =>
          raise Error ["no input files"]
        | {mode = SOME (MakeDependCompile {noStdPath}), ...} =>
          PrintTo
            (#outputFilename options,
             fn out =>
                Sequence
                  (map (fn srcfile =>
                           PrintDependCompile
                             ({noStdPath = noStdPath,
                               source = srcfile,
                               target = defaultObjTarget srcfile,
                               out = out},
                              Load Top.SyntaxCheck srcfile))
                       (#sources options)))
        | {mode = SOME (MakeDependLink {noStdPath}), ...} =>
          PrintTo
            (#outputFilename options,
             fn out =>
                Sequence
                  (map (fn srcfile =>
                           PrintDependLink
                             ({noStdPath = noStdPath,
                               source = srcfile,
                               target = toExeTarget srcfile,
                               out = out},
                              LoadAll Top.SyntaxCheck srcfile))
                       (#sources options)))
        | {mode = SOME SyntaxOnly, outputFilename = SOME _, ...} =>
          raise Error ["cannot specify -o with -fsyntax-only"]
        | {mode = SOME SyntaxOnly, outputFilename = NONE, sources, ...} =>
          Sequence (map (fn x => Ignore (Load Top.SyntaxCheck x)) sources)
        | {mode = SOME TypeCheckOnly, outputFilename = SOME _, ...} =>
          raise Error ["cannot specify -o with -ftypecheck-only"]
        | {mode = SOME TypeCheckOnly, outputFilename = NONE, sources, ...} =>
          Sequence (map (fn x => Ignore (Load Top.ErrorCheck x)) sources)
        | {mode = SOME AssemblyOnly, outputFilename = NONE, sources, ...} =>
          Sequence
            (map (fn srcfile =>
                     Ignore
                       (WriteAsm (defaultAsmTarget srcfile)
                                 (ModuleOf (CompileSml Top.NoStop srcfile))))
                 sources)
        | {mode = SOME AssemblyOnly, outputFilename = SOME _,
           sources = _::_::_, ...} =>
          raise Error ["cannot specify -o with -S with multiple files"]
        | {mode = SOME AssemblyOnly, outputFilename = SOME dstname,
           sources = [source], ...} =>
          Ignore (WriteAsm dstname (ModuleOf (CompileSml Top.NoStop source)))
        | {mode = SOME CompileOnly, outputFilename = NONE, sources, ...} =>
          Sequence
            (map (fn srcfile =>
                     Ignore
                       (WriteObj (defaultObjTarget srcfile)
                                 (ModuleOf (CompileSml Top.NoStop srcfile))))
                 sources)
        | {mode = SOME CompileOnly, outputFilename = SOME _,
           sources = _::_::_, ...} =>
          raise Error ["cannot specify -o with -c with multiple files"]
        | {mode = SOME CompileOnly, outputFilename = SOME dstname,
           sources = [source], ...} =>
          Ignore (WriteObj dstname (ModuleOf (CompileSml Top.NoStop source)))
        | {mode = NONE, outputFilename, sources, ...} =>
          let
            val srcfiles =
                map (fn srcfile =>
                        case Filename.suffix srcfile of
                          SOME "sml" => (true, srcfile)
                        | SOME "smi" => (true, srcfile)
                        | _ => (false, srcfile))
                    sources
            val _ =
                case List.filter #1 srcfiles of
                  nil => ()
                | [_] => ()
                | _::_::_ => raise Error ["cannot specify multiple .sml/.smi \
                                          \files in link mode"]
            val linkObjs =
                map (fn (false, srcfile) =>
                        Const [FILE (OBJorBC srcfile)]
                      | (true, srcfile) =>
                        ToLinkObjects
                          ({linkAll = #linkAll options},
                           UserFileMap,
                           LoadAll Top.NoStop srcfile))
                    srcfiles
            val dstfile =
                case outputFilename of
                  SOME filename => filename
                | NONE => defaultExeTarget ()
          in
            Link (llvmOptions,
                  {systemBaseDir = systemBaseDir,
                   noStdLib = #noStdLib options,
                   useCXX = #useCXX options,
                   LDFLAGS = #LDFLAGS options,
                   LIBS = #LIBS options,
                   dstfile = dstfile},
                  linkObjs)
          end
      end

  fun main (progname, args) =
      let
        val args = parseArgs args
        val proc = interpretArgs (progname, args)
        val _ = proc ()
      in
        if !Control.doProfile
        then (print "Time Profile:\n"; print (Counter.dump ())) else ();
        TempFile.cleanup ();
        OS.Process.success
      end
      handle e =>
        (
          TempFile.cleanup ();
          printExn progname e;
          OS.Process.failure
        )

end
