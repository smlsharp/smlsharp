(**
 * simple main entry for separate compilation
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure Main =
struct

  structure I = InterfaceName

  exception Error of string list

  datatype 'a try = RET of 'a | ERR of exn

  type 'a delay = unit -> 'a
  fun delay f =
      let val r = ref NONE
      in fn () => case !r of SOME x => x
                           | NONE => let val x = f () in r := SOME x; x end
      end
  fun force f = f ()

  fun defaultSystemBaseDir () =
      case ExecutablePath.getPath () of
        NONE => Filename.fromString SMLSharp_Version.DefaultSystemBaseDir
      | SOME path =>
        Filename.concatPath
          (Filename.dirname (Filename.fromString path),
           Filename.fromString "../lib/smlsharp")

  fun toAsmFile filename =
      Filename.replaceSuffix (SMLSharp_Config.ASMEXT ()) filename
  fun toObjFile filename =
      Filename.replaceSuffix (SMLSharp_Config.OBJEXT ()) filename
  fun toLLFile filename =
      Filename.replaceSuffix LLVM.ASMEXT filename
  fun toBCFile filename =
      Filename.replaceSuffix LLVM.OBJEXT filename
  fun toExeTarget filename =
      Filename.removeSuffix filename

  fun defaultExeTarget () =
      case SMLSharp_Config.HOST_OS_TYPE () of
        SMLSharp_Config.Mingw => Filename.fromString "a.exe"
      | _ => Filename.fromString "a.out"

  fun printVersion {llvmOptions={triple, ...}, ...} =
      print ("SML# " ^ SMLSharp_Version.Version
             ^ " (" ^ SMLSharp_Version.ReleaseDate ^ ") for "
             ^ triple
             ^ " with LLVM " ^ LLVM.getVersion ()
             ^ "\n")

  fun putsErr s =
      TextIO.output (TextIO.stdErr, s ^ "\n")

  fun userErrorToString e =
      Bug.prettyPrint (UserError.format_errorInfo e)
  fun locToString loc =
      Bug.prettyPrint (Loc.format_loc loc)
  fun sysErrToString (msg, err) =
      case err of
        NONE => msg
      | SOME err => msg ^ " (" ^ OS.errorName err ^ ")"

  fun printExn progname e =
      case e of
        Error msgs =>
        app (fn x => putsErr (progname ^ ": " ^ x)) msgs
      | UserError.UserErrors nil =>
        putsErr "[BUG] empty UserErrors"
      | UserError.UserErrors errs =>
        app (fn e => putsErr (userErrorToString e)) errs
      | LLVM.LLVMError msg =>
        putsErr ("LLVM error: " ^ msg)
      | IO.Io {name, function, cause} =>
        putsErr ("IO: " ^ function ^ ": " ^ name ^ ": "
                 ^ (case cause of
                      OS.SysErr x => sysErrToString x
                    | e => exnName e))
      | OS.SysErr x =>
        putsErr ("SysErr: " ^ sysErrToString x ^ "\n")
      | _ =>
        putsErr ("uncaught exception: " ^ exnMessage e)

  fun printWarnings errors =
      if !Control.printWarning
      then app (fn e => putsErr (userErrorToString e)) errors
      else ()

  datatype compile_mode =
      CompileOnly
    | AssemblyOnly

  datatype check_mode =
      SyntaxOnly
    | TypeCheckOnly

  datatype compiler_mode =
      Compile of compile_mode
    | Check of check_mode
    | MakeDependCompile of InterfaceName.file_place
    | MakeDependLink of InterfaceName.file_place
    | MakeMakefile
    | Help

  datatype command_line_args =
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
    | Mode of compiler_mode
    | SourceFile of string
    | SystemBaseDir of string
    | LinkerFlags of string list
    | LLCFlags of string list
    | OPTFlags of string list
    | ControlSwitch of string option
    | NoStdPath
    | NoStdLib
    | Verbose
    | UseCXX
    | LinkAll
    | EmitLLVM
    | FileMap of string
    | Require of string

  val optionDesc =
      let
        fun splitComma s = String.fields (fn c => #"," = c) s
        open GetOpt
      in
        [
          SHORT (#"o", REQUIRED OutputFile),
          SHORT (#"c", NOARG (Mode (Compile CompileOnly))),
          SHORT (#"S", NOARG (Mode (Compile AssemblyOnly))),
          SHORT (#"I", REQUIRED IncludePath),
          SHORT (#"L", REQUIRED LibraryPath),
          SHORT (#"l", REQUIRED Library),
          SHORT (#"v", NOARG Verbose),
          SHORT (#"B", REQUIRED SystemBaseDir),
          SHORT (#"M", NOARG (Mode (MakeDependCompile I.STDPATH))),
          SHORT (#"r", REQUIRED Require),
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
          SLONG ("MM", NOARG (Mode (MakeDependCompile I.LOCALPATH))),
          SLONG ("Ml", NOARG (Mode (MakeDependLink I.STDPATH))),
          SLONG ("MMl", NOARG (Mode (MakeDependLink I.LOCALPATH))),
          SLONG ("Mm", NOARG (Mode MakeMakefile)),
          SLONG ("Wl", REQUIRED (fn x => LinkerFlags (splitComma x))),
          SLONG ("Xlinker", REQUIRED (fn x => LinkerFlags [x])),
          SLONG ("Xllc", REQUIRED (fn x => LLCFlags [x])),
          SLONG ("Xopt", REQUIRED (fn x => OPTFlags [x])),
          SLONG ("fsyntax-only", NOARG (Mode (Check SyntaxOnly))),
          SLONG ("ftypecheck-only", NOARG (Mode (Check TypeCheckOnly))),
          SLONG ("emit-llvm", NOARG EmitLLVM),
          SLONG ("c++", NOARG UseCXX),
          DLONG ("link-all", NOARG LinkAll),
          SLONG ("filemap", REQUIRED FileMap),
          SLONG ("nostdpath", NOARG NoStdPath),
          SLONG ("nostdlib", NOARG NoStdLib),
          DLONG ("help", NOARG (Mode Help)),
          SHORT (#"d", OPTIONAL ControlSwitch)
        ]
      end

  fun modeToOption mode =
      case mode of
        Compile CompileOnly => "-c"
      | Compile AssemblyOnly => "-S"
      | Check SyntaxOnly => "-fsyntax-only"
      | Check TypeCheckOnly => "-ftypecheck-only"
      | MakeDependCompile I.STDPATH => "-M"
      | MakeDependCompile I.LOCALPATH => "-MM"
      | MakeDependLink I.STDPATH => "-Ml"
      | MakeDependLink I.LOCALPATH => "-MMl"
      | MakeMakefile => "-Mm"
      | Help => "--help"

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
      \  -r <file>          add a library preloaded in interactive mode\
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

  fun printHelp {progname, developerMode} =
      (
        #start Counter.printHelpTimeCounter();
        print (usageMessage progname);
        if developerMode then print (extraOptionUsageMessage ()) else ();
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

  fun loadBuiltin {systemBaseDir, ...} =
      Top.loadBuiltin
        (Filename.concatPath
           (systemBaseDir, Filename.fromString "builtin.smi"))

  fun loadPrelude {systemBaseDir,
                   topContext,
                   topOptions = {stdPath, loadPath, ...},
                   require, ...} =
      let
        val context = force topContext
        val (dependency, newContext) =
            Top.loadInterfaces
              {stopAt = Top.NoStop,
               stdPath = stdPath,
               loadPath = loadPath,
               loadMode = Top.NOLOCAL,
               outputWarnings = fn e => raise UserError.UserErrors e}
              context
              ((I.STDPATH,
                Filename.concatPath
                  (systemBaseDir, Filename.fromString "prelude.smi"))
               :: map (fn x => (I.LOCALPATH, x)) require)
      in
        (#depends dependency, Top.extendContext (context, newContext))
      end

  fun loadFileMap filename =
      FilenameMap.load filename
      handle FilenameMap.Load msg =>
             raise Error [Filename.toString filename
                          ^ ": failed to read filemap: " ^ msg]

  fun smiSourceToObjSource {fileMap, ...} ((place, filename):I.source) =
      case place of
        I.STDPATH => (place, toObjFile filename)
      | I.LOCALPATH =>
        case fileMap of
          NONE => (place, toObjFile filename)
        | SOME fileMap =>
          case FilenameMap.find (force fileMap, filename) of
            SOME filename => (place, filename)
          | NONE => raise Error ["object file is not found in filemap: "
                                 ^ Filename.toString filename]

  fun isBiggerPlace (I.STDPATH, I.LOCALPATH) = true
    | isBiggerPlace _ = false

  fun listDependsCompile limit deps =
      let
        val deps = map (fn I.LOCAL x => I.DEPEND x | x => x) deps
        val nodes = InterfaceName.listFileDependencyNodes false deps
      in
        List.mapPartial
          (fn ((p, file), _, _) =>
              if isBiggerPlace (p, limit) then NONE else SOME file)
          nodes
      end

  fun listDependsLink limit deps =
      List.filter
        (fn ((p, _), _, _) => not (isBiggerPlace (p, limit)))
        (InterfaceName.listFileDependencyNodes true deps)

  fun listLinkObjectFiles options limit deps =
      List.mapPartial
        (fn (source, I.INTERFACE iname, deps) =>
            SOME (#2 (smiSourceToObjSource options source), iname, deps)
          | _ => NONE)
        (listDependsLink limit deps)

  fun compileLLVMModule {llvmOptions, ...} (fileType, dstfile) module =
      let
        val _ = #start Counter.llvmOutputTimeCounter ()
        val r = RET (LLVMUtils.compile llvmOptions (module, fileType, dstfile))
                handle e => ERR e
        val _ = #stop Counter.llvmOutputTimeCounter ()
        val _ = LLVM.LLVMDisposeModule module
      in
        case r of RET () => () | ERR e => raise e
      end

  fun compileLLVMModuleToObjectFile options module =
      let
        val dstfile = TempFile.create ("." ^ SMLSharp_Config.OBJEXT ())
      in
        compileLLVMModule options (LLVMUtils.ObjectFile, dstfile) module;
        dstfile
      end

  fun compileLLVMBitcode options filename =
      let
        val context = LLVM.LLVMGetGlobalContext ()
        val filename = Filename.toString filename
        val buf = LLVM.LLVMCreateMemoryBufferWithContentsOfFile filename
        val module = RET (LLVM.LLVMParseBitcodeInContext (context, buf))
                     handle e => ERR e
      in
        LLVM.LLVMDisposeMemoryBuffer buf;
        case module of
          RET m => compileLLVMModuleToObjectFile options m
        | ERR (LLVM.LLVMError msg) =>
          raise Error [filename ^ ": " ^ msg]
        | ERR e => raise e
      end

  fun compileSML {llvmOptions, topOptions, topContext, ...} filename =
      let
        val io = Filename.TextIO.openIn filename
        val context = force topContext
        val topOptions = topOptions # {baseFilename = SOME filename}
        val input =
            Parser.setup
              {mode = Parser.File,
               read = fn (_, n) => TextIO.inputN (io, n),
               sourceName = Filename.toString filename,
               initialLineno = 1}
        val r =
            RET (Top.compile llvmOptions topOptions context input)
            handle e => ERR e
        val _ = TextIO.closeIn io
        val (dependency, module) =
            case r of
              ERR e => raise e
            | RET (dep, Top.RETURN (_, module)) => (dep, SOME module)
            | RET (dep, Top.STOPPED) => (dep, NONE)
      in
        {dependency = dependency, module = module}
      end

  fun compileSMLFile options {outputFileType, outputFilename} srcfile =
      case compileSML options srcfile of
        {module = NONE, dependency, ...} => dependency
      | {module = SOME module, dependency, ...} =>
        (compileLLVMModule options (outputFileType, outputFilename) module;
         dependency)

  fun loadSMI {topOptions, topContext, ...} filename =
      let
        val (dependency, _) =
            Top.loadInterfaces topOptions
                               (force topContext)
                               [(I.LOCALPATH, filename)]
      in
        {dependency = dependency, module = NONE}
      end

  fun loadSMLorSMI options filename =
      case Filename.suffix filename of
        SOME "smi" => loadSMI options filename
      | _ => compileSML options filename

  fun testFileExist filename =
      if CoreUtils.testExist filename
      then ()
      else raise Error ["file not found: " ^ Filename.toString filename]

  fun archive filenames =
      let
        val arfile = TempFile.create ("." ^ SMLSharp_Config.LIBEXT ())
      in
        BinUtils.archive {objects = filenames, archive = arfile};
        arfile
      end

  fun toLinkableFiles (options as {linkOptions={linkAll, ...}, ...})
                      compileResult =
      let
        val (mainfile, depends) =
            case compileResult of
              {module = SOME module, dependency = {depends, ...}, ...} =>
              (compileLLVMModuleToObjectFile options module, depends)
            | {module = NONE,
               dependency =
                 {interfaceNameOpt = NONE,
                  depends = [I.DEPEND (_, I.INTERFACE {source, ...}, deps)]},
               ...} =>
              (#2 (smiSourceToObjSource options source), deps)
            | _ =>
              raise Error ["invalid interface as program entry"]
        val objfiles =
            map #1 (rev (listLinkObjectFiles options I.STDPATH depends))
      in
        app testFileExist (mainfile :: objfiles);
        if linkAll
        then mainfile :: objfiles
        else case objfiles of
               nil => [mainfile]
             | _::_ => [mainfile, archive objfiles]
      end

  fun link (options as {llvmOptions = {systemBaseDir, ...},
                        linkOptions = {noStdLib, useCXX, LDFLAGS, LIBS, ...},
                        ...})
           {sourceFiles, outputFile} =
      let
        val objfiles =
            List.concat
              (map (fn srcfile =>
                       case Filename.suffix srcfile of
                         SOME "sml" =>
                         toLinkableFiles options (compileSML options srcfile)
                       | SOME "smi" =>
                         toLinkableFiles options (loadSMI options srcfile)
                       | SOME x =>
                         if x = LLVM.OBJEXT
                         then [compileLLVMBitcode options srcfile]
                         else [srcfile]
                       | NONE => [srcfile])
                   sourceFiles)
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
                       dst = outputFile,
                       useCXX = useCXX,
                       quiet = false}
      end

  fun interactive (options
                     as {llvmOptions,
                         linkOptions={LDFLAGS, LIBS, ...},
                         topOptions={stdPath, loadPath, outputWarnings, ...},
                         ...}) =
      let
        val (depends, topContext) = loadPrelude options
      in
        RunLoop.interactive
          {options = {llvmOptions = llvmOptions,
                      LDFLAGS = LDFLAGS,
                      LIBS = LIBS,
                      baseFilename = NONE,
                      stdPath = stdPath,
                      loadPath = loadPath,
                      outputWarnings = outputWarnings},
           errorOutput = TextIO.stdErr}
          topContext
          (map (fn (objfile, {hash, ...}, _) =>
                   {objfile = objfile, hash = hash})
               (listLinkObjectFiles options I.STDPATH depends))
      end

  fun printTo (NONE, f) = f TextIO.stdOut
    | printTo (SOME filename, f) =
      let
        val out = Filename.TextIO.openOut filename
        val () = f out handle e => (TextIO.closeOut out; raise e)
      in
        TextIO.closeOut out
      end

  local
    fun format w nil = nil
      | format w (h::t) =
        let
          val n = size h
        in
          if w = 0 then h :: format n t
          else if w + 1 + n <= 78 then " " :: h :: format (w + 1 + n) t
          else " \\\n " :: h :: format (1 + n) t
        end
  in
  fun printMakeRule out (target, sources) =
      (app (fn s => TextIO.output (out, s))
           (format 0 (target ^ ":" :: sources));
       TextIO.output (out, "\n"))
  end (* local *)

  fun printDependCompile options {limit, out} srcfile =
      let
        val {dependency, ...} = loadSMLorSMI options srcfile
        val depends =
            case dependency of
              {interfaceNameOpt = NONE, depends} => depends
            | {interfaceNameOpt = SOME (iname as {source, ...}), depends} =>
              depends @ [I.DEPEND (source, I.INTERFACE iname, nil)]
        val depfiles = map Filename.toString (listDependsCompile limit depends)
        val target = Filename.toString (toObjFile srcfile)
        val source = Filename.toString srcfile
      in
        printMakeRule out (target, source :: depfiles)
      end

  fun printDependLink options {limit, out} srcfile =
      let
        val {dependency, ...} = loadSMLorSMI options srcfile
        val depends =
            case dependency of
              {interfaceNameOpt = NONE, depends} => depends
            | {interfaceNameOpt = SOME (iname as {source, ...}), depends} =>
              [I.DEPEND (source, I.INTERFACE iname, depends)]
        val depfiles =
            map (fn (s, _, _) => Filename.toString s)
                (listLinkObjectFiles options limit depends)
        val target = Filename.toString (toExeTarget srcfile)
      in
        printMakeRule out (target, depfiles)
      end

  fun listLinkDependFiles options deps =
      let
        val objfiles =
            List.mapPartial
              (fn (s, I.INTERFACE _, _) => SOME (smiSourceToObjSource options s)
                | _ => NONE)
              deps
        val smifiles =
            List.mapPartial
              (fn (s, I.SML, _) => NONE | (s, _, _) => SOME s)
              deps
      in
        map (Filename.toString o #2) (objfiles @ smifiles)
      end

  fun generateMakefile (options as {topOptions, topContext, ...}) out srcfiles =
      let
        val ({depends, ...}, _) =
            Top.loadInterfaces topOptions
                               (force topContext)
                               (map (fn x => (I.LOCALPATH, x)) srcfiles)
        val targets =
            List.mapPartial
              (fn I.LOCAL _ => NONE
                | I.DEPEND (node as (source, t, deps)) =>
                  SOME (source, toExeTarget (#2 source), t, [I.DEPEND node]))
              depends
      in
        TextIO.output (out, "SMLSHARP = smlsharp\n");
        printMakeRule out ("all", map (Filename.toString o #2) targets);
        app
          (fn (source, target, ftype, deps) =>
              (printMakeRule
                 out
                 (Filename.toString target,
                  listLinkDependFiles
                    options
                    (listDependsLink I.LOCALPATH deps));
               case ftype of
                 I.INTERFACE _ =>
                 TextIO.output
                   (out, "\t$(SMLSHARP) $(LDFLAGS) -o $@ "
                         ^ Filename.toString (#2 source)
                         ^ " $(LIBS)\n")
               | _ => ()))
          targets;
        app
          (fn (objfile, iname, deps) =>
              let
                val dep = I.DEPEND (#source iname, I.INTERFACE iname, nil)
                val depfiles = listDependsCompile I.LOCALPATH (deps @ [dep])
                val smlfile = Filename.replaceSuffix "sml" objfile
              in
                printMakeRule
                  out
                  (Filename.toString objfile,
                   map Filename.toString (smlfile :: depfiles));
                TextIO.output
                  (out, "\t$(SMLSHARP) $(SMLFLAGS) -o $@ -c "
                        ^ Filename.toString smlfile
                        ^ "\n")
              end)
          (listLinkObjectFiles options I.LOCALPATH depends)
      end

  fun makeLLVMOptions {systemBaseDir, triple, arch, cpu, features,
                       optLevel, relocModel, LLCFLAGS, OPTFLAGS, ...} =
      {systemBaseDir =
         case systemBaseDir of
           SOME x => x
         | NONE => defaultSystemBaseDir (),
       triple =
         case triple of
           SOME x => x
         | NONE => SMLSharp_Config.TARGET_TRIPLE (),
       arch = arch,
       cpu = cpu,
       features = features,
       optLevel = optLevel,
       relocModel =
         case relocModel of
           SOME x => x
         | NONE => if SMLSharp_Config.PIC_DEFAULT ()
                   then LLVMUtils.RelocPIC
                   else LLVMUtils.RelocDefault,
       LLCFLAGS = LLCFLAGS,
       OPTFLAGS = OPTFLAGS}
      : LLVMUtils.compile_options

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

  fun loadConfig {systemBaseDir, ...} =
      (case systemBaseDir of
         NONE => ()
       | SOME dir =>
         SMLSharp_Config.loadConfig dir
         handle SMLSharp_Config.Load =>
                raise Error ["failed to read config.mk. Specify"
                             ^ " correct path by -B option."];
       app setExtraOption (SMLSharp_Config.EXTRA_OPTIONS ()))

  fun command (progname, commandLineArgs) =
      let
        val args =
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
              arch = "",
              cpu = "",
              features = "",
              outputFilename = NONE,
              srcfiles = nil,
              verbose = false,
              mode = NONE,
              developerMode = false,
              extraOptions = nil,
              fileMap = NONE,
              require = nil,
              useCXX = false,
              linkAll = false,
              emitLLVM = false
            }
        fun processArg (arg, args) =
            case arg of
              OutputFile file =>
              args # {outputFilename = SOME (Filename.fromString file)}
            | IncludePath path =>
              args # {loadPath = #loadPath args @ [Filename.fromString path]}
            | LibraryPath path =>
              args # {LDFLAGS = #LDFLAGS args @ ["-L" ^ path]}
            | Library lib =>
              args # {LIBS = #LIBS args @ ["-l" ^ lib]}
            | OptLevel level =>
              args # {optLevel = level}
            | RelocModel mode =>
              args # {relocModel = SOME mode}
            | TargetTriple s =>
              args # {triple = SOME s}
            | TargetArch arch =>
              args # {arch = arch}
            | TargetCPU cpu =>
              args # {cpu = cpu}
            | TargetAttrs attr =>
              args # {features = attr}
            | UseCXX =>
              args # {useCXX = true}
            | LinkAll =>
              args # {linkAll = true}
            | EmitLLVM =>
              args # {emitLLVM = true}
            | NoStdPath =>
              args # {noStdPath = true}
            | NoStdLib =>
              args # {noStdLib = true}
            | SourceFile file =>
              args # {srcfiles = #srcfiles args @ [Filename.fromString file]}
            | SystemBaseDir file =>
              args # {systemBaseDir = SOME (Filename.fromString file)}
            | LinkerFlags flags =>
              args # {LDFLAGS = #LDFLAGS args @ flags}
            | LLCFlags flags =>
              args # {LLCFLAGS = #LLCFLAGS args @ flags}
            | OPTFlags flags =>
              args # {OPTFLAGS = #OPTFLAGS args @ flags}
            | FileMap file =>
              args # {fileMap = SOME (Filename.fromString file)}
            | Require file =>
              args # {require = #require args @ [Filename.fromString file]}
            | ControlSwitch (SOME pair) =>
              args # {extraOptions = #extraOptions args @ [pair]}
            | ControlSwitch NONE =>
              args # {developerMode = true}
            | Verbose =>
              args # {verbose = true}
            | Mode Help =>
              args # {mode = SOME Help}
            | Mode newMode =>
              case #mode args of
                NONE => args # {mode = SOME newMode}
              | SOME oldMode =>
                if oldMode = newMode then args
                else raise Error ["cannot specify " ^ modeToOption oldMode
                                  ^ " with " ^ modeToOption newMode]

        val args = foldl processArg args (parseArgs commandLineArgs)

        (* If -B option is specified, SML# compiler reads "config.mk" file
         * in the given directory and configures the compiler itself
         * according to the config.mk file.  Otherwise, SML# compiler
         * uses built-in configurations. *)
        val _ = loadConfig args

        (* Set global control options according to args.
         * The order of extra options is siginificant; if the same option
         * is set twice or more, the latter one overwrites the former one. *)
        val _ = Control.printCommand
                  := (#verbose args orelse #developerMode args)
        val _ = app setExtraOption (#extraOptions args)

        (* Now we have done the global configuration of the compiler.
         * Fill unspecified settings with default settings according to the
         * global configurations. *)
        val llvmOptions = makeLLVMOptions args
        val systemBaseDir =
            #systemBaseDir llvmOptions
        val stdPath =
            if #noStdPath args then nil else [systemBaseDir]
        val stopAt =
            case #mode args of
              SOME (Compile _) => Top.NoStop
            | SOME (Check SyntaxOnly) => Top.SyntaxCheck
            | SOME (Check TypeCheckOnly) => Top.ErrorCheck
            | SOME (MakeDependCompile _) => Top.SyntaxCheck
            | SOME (MakeDependLink _) => Top.SyntaxCheck
            | SOME MakeMakefile => Top.SyntaxCheck
            | SOME Help => Top.SyntaxCheck
            | NONE => Top.NoStop
        val loadMode =
            case #mode args of
              SOME (Compile _) => Top.COMPILE
            | SOME (Check _) => Top.COMPILE
            | SOME (MakeDependCompile _) => Top.COMPILE
            | SOME (MakeDependLink _) => Top.COMPILE_AND_LINK
            | SOME MakeMakefile => Top.ALL
            | SOME Help => Top.COMPILE
            | NONE => Top.COMPILE_AND_LINK

        val options =
            {
              systemBaseDir = systemBaseDir,
              llvmOptions = llvmOptions,
              topOptions =
                {stopAt = stopAt,
                 baseFilename = NONE,
                 stdPath = stdPath,
                 loadPath = #loadPath args,
                 loadMode = loadMode,
                 outputWarnings = printWarnings} : Top.options,
              linkOptions =
                {LDFLAGS = #LDFLAGS args,
                 LIBS = #LIBS args,
                 noStdLib = #noStdLib args,
                 useCXX = #useCXX args,
                 linkAll = #linkAll args},
              topContext =
                delay (fn () => loadBuiltin llvmOptions),
              fileMap =
                Option.map (fn x => delay (fn () => loadFileMap x))
                           (#fileMap args),
              require = #require args
            }

        fun filetype (AssemblyOnly, true) = LLVMUtils.IRFile
          | filetype (AssemblyOnly, false) = LLVMUtils.AssemblyFile
          | filetype (CompileOnly, true) = LLVMUtils.BitcodeFile
          | filetype (CompileOnly, false) = LLVMUtils.ObjectFile
        fun defaultTarget (AssemblyOnly, true) = toLLFile
          | defaultTarget (AssemblyOnly, false) = toAsmFile
          | defaultTarget (CompileOnly, true) = toBCFile
          | defaultTarget (CompileOnly, false) = toObjFile
      in
        case args of
          {mode = SOME Help, ...} =>
          printHelp {progname = progname, developerMode = #developerMode args}
        | {mode = NONE, srcfiles = nil, verbose = true, ...} =>
          printVersion options
        | {mode = NONE, srcfiles = nil, verbose = false, ...} =>
          (printVersion options;
           interactive options)
        | {require = _::_, ...} =>
          raise Error ["cannot specify -r without interactive mode"]
        | {mode = SOME _, srcfiles = nil, ...} =>
          raise Error ["no input files"]
        | {mode = SOME (MakeDependCompile limit), srcfiles, ...} =>
          printTo
            (#outputFilename args,
             fn out =>
                app (printDependCompile options {limit = limit, out = out})
                    srcfiles)
        | {mode = SOME (MakeDependLink limit), srcfiles, ...} =>
          printTo
            (#outputFilename args,
             fn out =>
                app (printDependLink options {limit = limit, out = out})
                    srcfiles)
        | {mode = SOME MakeMakefile, srcfiles, ...} =>
          printTo
            (#outputFilename args,
             fn out => generateMakefile options out srcfiles)
        | {mode = SOME (m as Check _), outputFilename = SOME _, ...} =>
          raise Error ["cannot specify -o with " ^ modeToOption m]
        | {mode = SOME (Check _), outputFilename = NONE, srcfiles, ...} =>
          app (fn x => (loadSMLorSMI options x; ())) srcfiles
        | {mode = SOME (m as Compile _), outputFilename = SOME _,
           srcfiles = _::_::_, ...} =>
          raise Error ["cannot specify -o with " ^ modeToOption m
                       ^ " with multiple files"]
        | {mode = SOME (Compile m), outputFilename = SOME dstfile,
           srcfiles=[srcfile], emitLLVM, ...} =>
          (compileSMLFile
             options
             {outputFileType = filetype (m, emitLLVM),
              outputFilename = dstfile}
             srcfile;
           ())
        | {mode = SOME (Compile m), outputFilename = NONE, srcfiles, emitLLVM,
           ...} =>
          app (fn srcfile =>
                  (compileSMLFile
                     options
                     {outputFileType = filetype (m, emitLLVM),
                      outputFilename = defaultTarget (m, emitLLVM) srcfile}
                     srcfile;
                   ()))
              srcfiles
        | {mode = NONE, outputFilename, srcfiles, ...} =>
          let
            val _ =
                case List.filter
                       (fn srcfile =>
                           case Filename.suffix srcfile of
                             SOME "sml" => true
                           | SOME "smi" => true
                           | _ => false)
                       srcfiles
                of nil => ()
                 | [_] => ()
                 | _::_::_ => raise Error ["cannot specify multiple .sml/.smi \
                                           \files in link mode"]
            val outputFile =
                case outputFilename of
                  SOME filename => filename
                | NONE => defaultExeTarget ()
          in
            link options {sourceFiles = srcfiles, outputFile = outputFile}
          end
      end

  fun main (progname, args) =
      let
        val r = RET (command (progname, args)) handle e => ERR e
      in
        if !Control.doProfile
        then (print "Time Profile:\n"; print (Counter.dump ())) else ();
        TempFile.cleanup ();
        case r of
          RET () => OS.Process.success
        | ERR e => (printExn progname e; OS.Process.failure)
      end

end
