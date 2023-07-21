(**
 * simple main entry for separate compilation
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)

structure Main =
struct

  structure I = InterfaceName
  structure S = ShellUtils

  exception Error of string list

  datatype 'a try = RET of 'a | ERR of exn

  type 'a delay = unit -> 'a
  fun delay f =
      let val r = ref NONE
      in fn () => case !r of SOME x => x
                           | NONE => let val x = f () in r := SOME x; x end
      end
  fun force f = f ()

  fun consOpt (SOME x, y) = x :: y
    | consOpt (NONE, y) = y

  fun defaultSystemBaseDir () =
      case ExecutablePath.getPath () of
        NONE => Filename.fromString SMLSharp_Version.DefaultSystemBaseDir
      | SOME path =>
        Filename.concatPaths
          [Filename.dirname (Filename.fromString path),
           Filename.dotdot,
           Filename.fromString "lib",
           Filename.fromString "smlsharp"]

  fun suffixOf LLVMUtils.IRFile = LLVMUtils.ASMEXT
    | suffixOf LLVMUtils.BitcodeFile = LLVMUtils.OBJEXT
    | suffixOf LLVMUtils.AssemblyFile = Config.ASMEXT ()
    | suffixOf LLVMUtils.ObjectFile = Config.OBJEXT ()

  fun lookupFilename fileMap filename =
      case fileMap of
        NONE => filename
      | SOME fileMap =>
        case UserFileMap.find (force fileMap, filename) of
          SOME filename => filename
        | NONE => raise Error ["file not found in filemap: "
                               ^ Filename.toString filename]

  fun substituteSource {fileMap, ...} suffix ((place, filename):I.source) =
      let
        val defaultResult = Filename.replaceSuffix suffix filename
      in
        case place of
          Loc.STDPATH => defaultResult
        | Loc.USERPATH => lookupFilename fileMap defaultResult
      end

  fun sourceToObjFile options source =
      substituteSource options (Config.OBJEXT ()) source

  fun printVersion {llvmOptions={triple, ...}, ...} =
      print ("SML# " ^ SMLSharp_Version.Release
             ^ " for " ^ triple
             ^ " with LLVM " ^ LLVMUtils.getVersion ()
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
      | IO.Io {name, function, cause} =>
        putsErr ("IO: " ^ function ^ ": " ^ name ^ ": "
                 ^ (case cause of
                      OS.SysErr x => sysErrToString x
                    | e => exnName e))
      | OS.SysErr x =>
        putsErr ("SysErr: " ^ sysErrToString x ^ "\n")
      | ShellUtils.Fail {command, status, output = {stderr, ...}} =>
        (putsErr ("command failed at status " ^ Int.toString status
                  ^ ": " ^ command);
         CoreUtils.cat [stderr] TextIO.stdErr)
      | UserLevelPrimitive.UserLevelPrimError (loc, exn) =>
        putsErr (userErrorToString (loc, UserError.Error, exn))
      | _ =>
        putsErr ("uncaught exception: " ^ exnMessage e)

  fun printWarnings errors =
      if !Control.printWarning
      then app (fn e => putsErr (userErrorToString e)) errors
      else ()

  datatype file_place_limit =
      ALL_PLACE
    | USERPATH_ONLY

  datatype compile_mode =
      CompileOnly
    | AssemblyOnly

  datatype check_mode =
      SyntaxOnly
    | TypeCheckOnly

  datatype compiler_mode =
      Compile of compile_mode
    | Check of check_mode
    | MakeDependCompile of file_place_limit
    | MakeDependLink of file_place_limit
    | MakeMakefile of file_place_limit
    | AnalyzeFiles of string option
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
    | SystemBaseDir of Filename.filename
    | SystemBaseExecDir of Filename.filename
    | LinkerFlags of ShellUtils.arg list
    | LLCFlags of ShellUtils.arg list
    | OPTFlags of ShellUtils.arg list
    | ControlSwitch of string option
    | NoStdPath
    | NoStdLib
    | Verbose
    | UseCXX
    | EmitLLVM
    | FileMap of string
    | Require of string

  val optionDesc =
      let
        fun splitComma s = map S.ARG (String.fields (fn c => #"," = c) s)
        open GetOptLong
      in
        [
          SHORT (#"o", REQUIRED OutputFile),
          SHORT (#"c", NOARG (Mode (Compile CompileOnly))),
          SHORT (#"S", NOARG (Mode (Compile AssemblyOnly))),
          SHORT (#"I", REQUIRED IncludePath),
          SHORT (#"L", REQUIRED LibraryPath),
          SHORT (#"l", REQUIRED Library),
          SHORT (#"v", NOARG Verbose),
          SHORT (#"A", OPTIONAL (Mode o AnalyzeFiles)),
          SHORT (#"B", REQUIRED (SystemBaseDir o Filename.fromString)),
          SLONG ("BX", REQUIRED (SystemBaseExecDir o Filename.fromString)),
          SHORT (#"M", NOARG (Mode (MakeDependCompile ALL_PLACE))),
          SHORT (#"r", REQUIRED Require),
          SLONG ("O0", NOARG (OptLevel LLVMUtils.O0)),
          SLONG ("O1", NOARG (OptLevel LLVMUtils.O1)),
          SLONG ("O", NOARG (OptLevel LLVMUtils.O2)),
          SLONG ("O2", NOARG (OptLevel LLVMUtils.O2)),
          SLONG ("O3", NOARG (OptLevel LLVMUtils.O3)),
          SLONG ("Os", NOARG (OptLevel LLVMUtils.Os)),
          SLONG ("Oz", NOARG (OptLevel LLVMUtils.Oz)),
          SLONG ("target", REQUIRED TargetTriple),
          SLONG ("march", REQUIRED TargetArch),
          SLONG ("mcpu", REQUIRED TargetCPU),
          SLONG ("mattr", REQUIRED TargetAttrs),
          SLONG ("fpic", NOARG (RelocModel LLVMUtils.RelocPIC)),
          SLONG ("fPIC", NOARG (RelocModel LLVMUtils.RelocPIC)),
          SLONG ("fno-pic", NOARG (RelocModel LLVMUtils.RelocStatic)),
          SLONG ("mdynamic-no-pic",
                 NOARG (RelocModel LLVMUtils.RelocDynamicNoPIC)),
          SLONG ("MM", NOARG (Mode (MakeDependCompile USERPATH_ONLY))),
          SLONG ("Ml", NOARG (Mode (MakeDependLink ALL_PLACE))),
          SLONG ("MMl", NOARG (Mode (MakeDependLink USERPATH_ONLY))),
          SLONG ("Mm", NOARG (Mode (MakeMakefile ALL_PLACE))),
          SLONG ("MMm", NOARG (Mode (MakeMakefile USERPATH_ONLY))),
          SLONG ("Wl", REQUIRED (fn x => LinkerFlags (splitComma x))),
          SLONG ("Xlinker", REQUIRED (fn x => LinkerFlags [S.ARG x])),
          SLONG ("Xllc", REQUIRED (fn x => LLCFlags [S.ARG x])),
          SLONG ("Xopt", REQUIRED (fn x => OPTFlags [S.ARG x])),
          SLONG ("fsyntax-only", NOARG (Mode (Check SyntaxOnly))),
          SLONG ("ftypecheck-only", NOARG (Mode (Check TypeCheckOnly))),
          SLONG ("emit-llvm", NOARG EmitLLVM),
          SLONG ("c++", NOARG UseCXX),
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
      | MakeDependCompile ALL_PLACE => "-M"
      | MakeDependCompile USERPATH_ONLY => "-MM"
      | MakeDependLink ALL_PLACE => "-Ml"
      | MakeDependLink USERPATH_ONLY => "-MMl"
      | MakeMakefile ALL_PLACE => "-Mm"
      | MakeMakefile USERPATH_ONLY => "-MMm"
      | AnalyzeFiles _ => "-A"
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
      \  -A                 analyze a source file tree\n\
      \  -M                 make dependency for compile\n\
      \  -MM                make dependency for compile but ignore system files\n\
      \  -Ml                make dependency for link\n\
      \  -MMl               make dependency for link but ignore system files\n\
      \  -c++               use C++ compiler driver as linker\n\
      \  -fsyntax-only      check for syntax errors, and exit\n\
      \  -ftypecheck-only   check for type errors, and exit\n\
      \  -filemap=<file>    specify a map from interface files to object files\n\
      \  -r <file>          add a library preloaded in interactive mode\n\
      \  -I <dir>           add <dir> to file search path\n\
      \  -L <dir>           add <dir> to library path of the linker\n\
      \  -l <libname>       link with <libname> to create an executable file\n\
      \  -Wl,<args>         pass comma-separated <args> to the linker\n\
      \  -Xlinker <arg>     pass <arg> to the linker\n\
      \  -Xllc <arg>        pass <arg> to llc command\n\
      \  -Xopt <arg>        pass <arg> to opt command\n\
      \  -nostdpath         no standard file search path is used\n\
      \  -d <key>=<value>   set extra option for compiler developers\n\
      \  -d                 turn on developer mode\n\
      \  -d --help          print list of extra options\n"

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
        val args = GetOptLong.getopt optionDesc args
            handle GetOptLong.NoArg name =>
                   raise Error ["option `" ^ name ^ "' requires an argument"]
                 | GetOptLong.HasArg name =>
                   raise Error ["option `" ^ name ^ "' requires no argment"]
                 | GetOptLong.Unknown name =>
                   raise Error ["invalid option `" ^ name ^ "'"]
      in
        map (fn GetOptLong.ARG x => SourceFile x | GetOptLong.OPTION x => x)
            args
      end


  fun loadBuiltin {systemBaseDir, ...} =
      let
        val filePlace = if Filename.isAbsolute systemBaseDir 
                        then Loc.STDPATH else Loc.USERPATH
      in
        Top.loadBuiltin
          (filePlace,
           Filename.concatPath
             (systemBaseDir, Filename.fromString "builtin.smi"))
      end

  fun loadPrelude {linkOptions = {systemBaseDir, ...},
                   topContext,
                   topOptions = {loadPath, ...},
                   require, ...} =
      let
        val context = force topContext
        val (dependency, newContext) =
            Top.loadInterfaces
              {stopAt = Top.NoStop,
               loadPath = loadPath,
               loadMode = I.NOLOCAL,
               outputWarnings = fn e => raise UserError.UserErrors e}
              context
              ((Loc.STDPATH,
                Filename.concatPath
                  (systemBaseDir, Filename.fromString "prelude.smi"))
               :: map (fn x => (Loc.USERPATH, x)) require)
      in
        (dependency, Top.extendContext (context, newContext))
      end

  fun loadFileMap filename =
      UserFileMap.load filename
      handle UserFileMap.Load {msg, lineno} =>
             raise Error [Filename.toString filename
                          ^ ":" ^ Int.toString lineno
                          ^ ": " ^ msg]

  fun compileLLVMBitcode {llvmOptions, ...} (fileType, dstfile) bcfile =
      let
        val _ = #start Counter.llvmOutputTimeCounter ()
        val r = RET (LLVMUtils.compile llvmOptions
                                       {srcfile = bcfile,
                                        dstfile = (fileType, dstfile)})
                handle e => ERR e
        val _ = #stop Counter.llvmOutputTimeCounter ()
      in
        case r of RET () => () | ERR e => raise e
      end

  fun compileLLVMBitcodeToObjectFile options bcfile =
      let
        val dstfile = TempFile.create ("." ^ Config.OBJEXT ())
      in
        compileLLVMBitcode options (LLVMUtils.ObjectFile, dstfile) bcfile;
        dstfile
      end

  fun compileSML {llvmOptions, topOptions, topContext, ...} filename =
      let
        val io = Filename.TextIO.openIn filename
        val context = force topContext
        val topOptions = topOptions # {baseFilename = SOME filename}
        val input =
            Parser.setup
              {source = Loc.FILE (Loc.USERPATH, filename),
               read = fn (_, n) => TextIO.inputN (io, n),
               initialLineno = 1}
(*
       val _ = UserLevelPrimitive.initFind
                 {findId = NameEvalEnvPrims.findId,
                  findTstr = NameEvalEnvPrims.findTstr}
*)
        val r =
            RET (Top.compile llvmOptions topOptions context input)
            handle e => ERR e
        val _ = TextIO.closeIn io
        val (dependency, bcfile) =
            case r of
              ERR e => raise e
            | RET (dep, Top.RETURN (_, bcfile)) => (dep, SOME bcfile)
            | RET (dep, Top.STOPPED) => (dep, NONE)
        val {root, ...} = dependency
(*
        val _ = 
            print
            (Bug.prettyPrint
               (InterfaceName.format_file_dependency_root root))
*)
      in
        {dependency = dependency, bcfile = bcfile}
      end

  fun compileSMLFile options {outputFileType, outputFilename} srcfile =
      case compileSML options srcfile of
        {bcfile = NONE, dependency, ...} => dependency
      | {bcfile = SOME bcfile, dependency, ...} =>
        let
          val suffix = suffixOf outputFileType
          val output =
              case outputFilename of
                SOME filename => filename
              | NONE =>
                case #edges (#root dependency) of
                  (I.PROVIDE, I.FILE {source, ...},_) :: _ =>
                  Filename.replaceSuffix suffix (sourceToObjFile options source)
                | _ => Filename.replaceSuffix suffix srcfile
        in
          compileLLVMBitcode options (outputFileType, output) bcfile;
          dependency
        end

  fun loadSMI {topOptions, topContext, ...} filename =
      let
        val loadMode =
            case #loadMode topOptions of
              I.NOLOCAL => I.NOLOCAL
            | I.COMPILE => I.NOLOCAL
            | I.LINK => I.LINK
            | I.COMPILE_AND_LINK => I.LINK
            | I.ALL => I.ALL
            | I.ALL_USERPATH => I.ALL_USERPATH
        val (dependency, _) =
            Top.loadInterfaces (topOptions # {loadMode = loadMode})
                               (force topContext)
                               [(Loc.USERPATH, filename)]
      in
        {dependency = dependency, bcfile = NONE}
      end

  fun loadSMLorSMI options filename =
      case Filename.suffix filename of
        SOME "smi" => loadSMI options filename
      | _ => compileSML options filename

  fun testFileExist filename =
      if CoreUtils.testExist filename
      then ()
      else raise Error ["file not found: " ^ Filename.toString filename]

  fun archive nil = nil
    | archive filenames =
      let
        val arfile = TempFile.create ("." ^ Config.LIBEXT ())
      in
        BinUtils.archive {objects = filenames, archive = arfile};
        [arfile]
      end

  fun subsumes (ALL_PLACE, _) = true
    | subsumes (USERPATH_ONLY, Loc.USERPATH) = true
    | subsumes (USERPATH_ONLY, Loc.STDPATH) = false

  fun listCompileSources limit allNodes =
      List.mapPartial
        (fn I.FILE {source, ...} =>
            if subsumes (limit, #1 source)
            then SOME (#2 source)
            else NONE)
        allNodes

  fun listLinkObjects options limit allNodes =
      List.mapPartial
        (fn I.FILE {source, fileType = I.INTERFACE hash, ...} =>
            if subsumes (limit, #1 source)
            then SOME {name = {hash = hash, source = source},
                       objfile = sourceToObjFile options source}
            else NONE
          | _ => NONE)
        allNodes

  fun resultToLinkableFiles options compileResult =
      let
        val {bcfile, dependency as {allNodes, root}, ...} = compileResult
        val provides =
            List.mapPartial
              (fn (I.PROVIDE, I.FILE node, _) => SOME (#source node)
                | (I.INCLUDE, I.FILE node, _) => SOME (#source node)
                | _ => NONE)
              (#edges root)
        val mainObjectFiles =
            case bcfile of
              SOME bcfile => [compileLLVMBitcodeToObjectFile options bcfile]
            | NONE => map (sourceToObjFile options) provides
        val allNodes =
            case provides of
              nil => allNodes
            | provides =>
              List.filter
                (fn I.FILE {source, ...} =>
                    List.all (fn x => source <> x) provides)
                allNodes
        val objectFiles =
            map #objfile (listLinkObjects options ALL_PLACE allNodes)
      in
        (SOME dependency, mainObjectFiles @ archive objectFiles)
      end

  fun makeLinkableFiles options srcfile =
      case Filename.suffix srcfile of
        SOME "sml" => resultToLinkableFiles options (compileSML options srcfile)
      | SOME "smi" => resultToLinkableFiles options (loadSMI options srcfile)
      | SOME x =>
        if x = LLVMUtils.OBJEXT
        then (NONE, [compileLLVMBitcodeToObjectFile options srcfile])
        else (NONE, [srcfile])
      | NONE => (NONE, [srcfile])

  fun link (options as {linkOptions = {systemBaseDir, noStdLib, useCXX, 
                                       LDFLAGS, LIBS, ...}, ...})
           {sourceFiles, outputFile} =
      let
        val objects = map (makeLinkableFiles options) sourceFiles
        val objfiles = List.concat (map #2 objects)
        val dependency = List.mapPartial #1 objects
        val runtimeDir = Filename.fromString "runtime"
        val runtimeDir = Filename.concatPath (systemBaseDir, runtimeDir)
        val libsmlsharp = Filename.fromString "libsmlsharp.a"
        val libsmlsharp = Filename.concatPath (runtimeDir, libsmlsharp)
        val smlsharpEntry = Filename.fromString "main.o"
        val smlsharpEntry = Filename.concatPath (runtimeDir, smlsharpEntry)
        val libs = if noStdLib
                   then LIBS
                   else S.ARG (Filename.toString libsmlsharp) :: LIBS
        val objects =
            if noStdLib then objfiles else smlsharpEntry :: objfiles
      in
        BinUtils.link {flags = LDFLAGS,
                       libs = libs,
                       objects = objects,
                       dst = outputFile,
                       useCXX = useCXX};
        dependency
      end

  fun interactive (options
                     as {llvmOptions,
                         linkOptions={LDFLAGS, LIBS, ...},
                         topOptions={loadPath, outputWarnings, ...},
                         ...}) =
      let
        val ({allNodes, ...}, topContext) = loadPrelude options
        val objectFiles = listLinkObjects options ALL_PLACE allNodes
      in
        RunLoop.interactive
          {options = {llvmOptions = llvmOptions,
                      LDFLAGS = LDFLAGS,
                      LIBS = LIBS,
                      baseFilename = NONE,
                      loadPath = loadPath,
                      outputWarnings = outputWarnings},
           errorOutput = TextIO.stdErr}
          topContext
          objectFiles
      end

  fun printTo (NONE, f) = f (fn s => TextIO.output (TextIO.stdOut, s))
    | printTo (SOME filename, f) =
      let
        val out = Filename.TextIO.openOut filename
        val outFn = fn s => TextIO.output (out, s)
        val () = f outFn handle e => (TextIO.closeOut out; raise e)
      in
        TextIO.closeOut out
      end

  fun printMakeLine out w nil = out "\n"
    | printMakeLine out w (h :: t) =
      let
        val n = size h
      in
        if w + 1 + n > !Control.printWidth
        then (out " \\\n "; out h; printMakeLine out (1 + n) t)
        else if w + 1 + n + 2 <= !Control.printWidth
        then (out " "; out h; printMakeLine out (w + 1 + n) t)
        else case t of
               nil => (out " "; out h; out "\n")
             | _::_ => (out " \\\n "; out h; printMakeLine out (1 + n) t)
      end

  fun printMakeRule out (target, sources) =
      let
        val target = Filename.toString target
        val sources = map Filename.toString sources
      in
        out target;
        out ":";
        if !Control.printWidth <= 0
        then (app (fn x => (out " "; out x)) sources; out "\n")
        else printMakeLine out (size target + 1) sources
      end

  fun printDependCompile options {limit, out} srcfile =
      let
        val {dependency = {allNodes, root = {fileType, edges, ...}}, ...} =
            loadSMLorSMI options srcfile
        val target = sourceToObjFile options (Loc.USERPATH, srcfile)
        val rootfile =
            case fileType of
              I.ROOT_SML source => Option.map #2 source
            | I.ROOT_INCLUDES => NONE
        val depfiles = listCompileSources limit allNodes
      in
        printMakeRule out (target, consOpt (rootfile, depfiles))
      end

  fun printDependLink options {limit, out} srcfile =
      let
        val {dependency = {allNodes, root = {fileType, edges, ...}}, ...} =
            loadSMLorSMI options srcfile
        val target = Filename.removeSuffix srcfile
        val rootfile =
            case fileType of
              I.ROOT_SML source => Option.map #2 source
            | I.ROOT_INCLUDES => NONE
        val depfiles = listCompileSources limit allNodes
        val objfiles = map #objfile (listLinkObjects options limit allNodes)
      in
        printMakeRule out (target, consOpt (rootfile, depfiles @ objfiles))
      end

  fun generateMakefile (options as {generateMakefileOptions =
                                      {programName,
                                       systemBaseDir,
                                       systemBaseDirSpecified,
                                       systemBaseExecDir,
                                       systemBaseExecDirSpecified, ...},
                                    topOptions,
                                    topContext, ...})
                       {limit, out} smifiles =
      let
        val command = [programName]
        val command =
            if systemBaseDirSpecified
            then command @ ["-B", Filename.toString systemBaseDir]
            else command
        val command =
            if systemBaseExecDirSpecified
            then command @ ["-BX", Filename.toString systemBaseExecDir]
            else command
        val ({allNodes, root = {edges, ...}}, _) =
            Top.loadInterfaces
              (topOptions # {loadMode = I.ALL_USERPATH})
              (force topContext)
              (map (fn x => (Loc.USERPATH, x)) smifiles)
        val targets =
            List.mapPartial
              (fn edge as (I.INCLUDE, I.FILE {source, ...}, _) =>
                  SOME {target = Filename.removeSuffix (#2 source),
                        smifile = #2 source,
                        root = {fileType = I.ROOT_INCLUDES,
                                mode = I.LINK,
                                edges = [edge]}}
                | _ => NONE)
              edges
      in
        out "SMLSHARP ="; printMakeLine out 10 command;
        out "SMLFLAGS ="; printMakeLine out 10 ["-O2"];
        out "LIBS =\n";
        printMakeRule out (Filename.fromString "all", map #target targets);
        (* print link rules *)
        app
          (fn {target, smifile, root} =>
              let
                val {allNodes, ...} = LoadFile.revisit root
                val sources = listCompileSources limit allNodes
                val objects =
                    map #objfile (listLinkObjects options limit allNodes)
              in
                printMakeRule out (target, sources @ objects);
                out "\t$(SMLSHARP)";
                printMakeLine out 19 ["$(LDFLAGS)",
                                      "-o", Filename.toString target,
                                      Filename.toString smifile, "$(LIBS)"]
              end)
          targets;
        (* print compile rules *)
        app
          (fn node as I.FILE {source, fileType = I.INTERFACE _, ...} =>
              if subsumes (USERPATH_ONLY, #1 source) then
                let
                  val root = {fileType = I.ROOT_SML NONE,
                              mode = I.COMPILE,
                              edges = [(I.PROVIDE, node, Loc.noloc)]}
                  val {allNodes, ...} = LoadFile.revisit root
                  val sources = listCompileSources limit allNodes
                  val target = sourceToObjFile options source
                  val smlfile = Filename.replaceSuffix "sml" target
                in
                  printMakeRule out (target, smlfile :: sources);
                  out "\t$(SMLSHARP)";
                  printMakeLine out 19 ["$(SMLFLAGS)",
                                        "-o", Filename.toString target,
                                        "-c", Filename.toString smlfile]
                end
              else ()
            | _ => ())
          allNodes
      end

  fun makeLLVMOptions {systemBaseExecDir, triple, arch, cpu, features,
                       optLevel, relocModel, LLCFLAGS, OPTFLAGS, ...} =
      {systemBaseExecDir = systemBaseExecDir,
       triple =
         case triple of
           SOME x => x
         | NONE => LLVMUtils.getDefaultTarget (),
       arch = arch,
       cpu = cpu,
       features = features,
       optLevel = optLevel,
       relocModel =
         case relocModel of
           SOME x => x
         | NONE => if Config.PIC_DEFAULT ()
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
      let
        val config_mk = Filename.fromString "config.mk"
        val config_mk = Filename.concatPath (systemBaseDir, config_mk)
      in
        Config.loadConfig config_mk;
        app setExtraOption (Config.EXTRA_OPTIONS ())
      end

  fun command (progname, commandLineArgs) =
      let
        val defaultSystemBaseDir = defaultSystemBaseDir ()
        val args =
            {
              programName = progname,
              systemBaseDir = defaultSystemBaseDir,
              systemBaseDirSpecified = false,
              systemBaseExecDir = defaultSystemBaseDir,
              systemBaseExecDirSpecified = false,
              noStdPath = false,
              noStdLib = false,
              localPath = nil,
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
              emitLLVM = false
            }
        fun processArg (arg, args) =
            case arg of
              OutputFile file =>
              args # {outputFilename = SOME (Filename.fromString file)}
            | IncludePath path =>
              args # {localPath = #localPath args @ [Filename.fromString path]}
            | LibraryPath path =>
              args # {LDFLAGS = #LDFLAGS args @ [S.ARG ("-L" ^ path)]}
            | Library lib =>
              args # {LIBS = #LIBS args @ [S.ARG ("-l" ^ lib)]}
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
            | EmitLLVM =>
              args # {emitLLVM = true}
            | NoStdPath =>
              args # {noStdPath = true}
            | NoStdLib =>
              args # {noStdLib = true}
            | SourceFile file =>
              args # {srcfiles = #srcfiles args @ [Filename.fromString file]}
            | SystemBaseDir filename =>
              args # {systemBaseDir = filename,
                      systemBaseDirSpecified = true,
                      systemBaseExecDir = if #systemBaseExecDirSpecified args
                                          then #systemBaseExecDir args
                                          else filename}
            | SystemBaseExecDir filename =>
              args # {systemBaseExecDir = filename,
                      systemBaseExecDirSpecified = true}
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

        (* read "config.mk" file in the system base directory and configure
         * the compiler itself according to that file. *)
        val _ = loadConfig args
                handle Config.Load err =>
                       (printExn progname err;
                        raise Error ["failed to read config.mk. Specify\
                                     \ correct path by -B option."])

        (* Set global control options according to args.
         * The order of extra options is siginificant; if the same option
         * is set twice or more, the latter one overwrites the former one. *)
        val _ = Control.printCommand
                  := (#verbose args orelse #developerMode args)
        val _ = app setExtraOption (#extraOptions args)

        (* Now we have done the global configuration of the compiler.
         * Fill unspecified settings with default settings according to the
         * global configurations. *)
        val stdPath =
            if #noStdPath args then nil
            else [(Loc.STDPATH, #systemBaseDir args)]
        val loadPath =
            map (fn x => (Loc.USERPATH, x)) (#localPath args) @ stdPath
        val stopAt =
            case #mode args of
              SOME (Compile _) => Top.NoStop
            | SOME (Check SyntaxOnly) => Top.SyntaxCheck
            | SOME (Check TypeCheckOnly) => Top.ErrorCheck
            | SOME (MakeDependCompile _) => Top.SyntaxCheck
            | SOME (MakeDependLink _) => Top.SyntaxCheck
            | SOME (MakeMakefile _) => Top.SyntaxCheck
            | SOME (AnalyzeFiles _) => Top.NameRef
            | SOME Help => Top.SyntaxCheck
            | NONE => Top.NoStop
        val loadMode =
            case #mode args of
              SOME (Compile _) => I.COMPILE
            | SOME (Check _) => I.COMPILE
            | SOME (MakeDependCompile _) => I.COMPILE
            | SOME (MakeDependLink _) => I.COMPILE_AND_LINK
            | SOME (MakeMakefile _) => I.ALL
            | SOME (AnalyzeFiles _) => I.COMPILE_AND_LINK
            | SOME Help => I.COMPILE
            | NONE => I.COMPILE_AND_LINK
        val fileMap =
            Option.map (fn x => delay (fn () => loadFileMap x)) (#fileMap args)

        val options =
            {
              generateMakefileOptions =
                {programName = #programName args,
                 systemBaseDir = #systemBaseDir args,
                 systemBaseDirSpecified = #systemBaseDirSpecified args,
                 systemBaseExecDir = #systemBaseExecDir args,
                 systemBaseExecDirSpecified = #systemBaseExecDirSpecified args},
              llvmOptions = makeLLVMOptions args,
              topOptions =
                {stopAt = stopAt,
                 baseFilename = NONE,
                 loadPath = loadPath,
                 loadMode = loadMode,
                 outputWarnings = printWarnings,
                 defaultInterface = lookupFilename fileMap} : Top.options,
              linkOptions =
                {systemBaseDir = #systemBaseDir args,
                 LDFLAGS = #LDFLAGS args,
                 LIBS = #LIBS args,
                 noStdLib = #noStdLib args,
                 useCXX = #useCXX args},
              topContext =
                delay (fn () => loadBuiltin args),
              fileMap = fileMap,
              require = #require args
            }

        fun filetype (AssemblyOnly, true) = LLVMUtils.IRFile
          | filetype (AssemblyOnly, false) = LLVMUtils.AssemblyFile
          | filetype (CompileOnly, true) = LLVMUtils.BitcodeFile
          | filetype (CompileOnly, false) = LLVMUtils.ObjectFile
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
             fn out => app (printDependCompile
                              options
                              {limit = limit, out = out})
                           srcfiles)
        | {mode = SOME (MakeDependLink limit), srcfiles, ...} =>
          printTo
            (#outputFilename args,
             fn out => app (printDependLink
                              options
                              {limit = limit, out = out})
                           srcfiles)
        | {mode = SOME (MakeMakefile limit), srcfiles, ...} =>
          printTo
            (#outputFilename args,
             fn out => generateMakefile
                         options
                         {limit = limit, out = out}
                         srcfiles)
        | {mode = SOME (AnalyzeFiles dbparam), srcfiles, ...} =>
          let
            val sourceFile =
                case srcfiles
                of nil => raise Error ["a root .smi file must be specified in analyze mode"]
                 | [s] => s
                 | _::_::_ => raise Error ["cannot specify multiple .smi \
                                           \files in analyze mode"]
            val _ = case Filename.suffix sourceFile of
                             SOME "smi" => ()
                           | _ => raise
                               Error ["root .smi file must be specified in analyze mode"]
            val refdbName = 
                case OS.Process.getEnv "SMLSHARP_SMLREFDB" of
                  SOME name => name
                | NONE => "smlsharp"
            val defaultDbparam = "dbname=" ^ refdbName
            val dbparam = case dbparam of NONE => defaultDbparam
                                        | SOME s => s
(*
            val _ = UserLevelPrimitive.initFind
                        {findId = NameEvalEnvPrims.findId,
                         findTstr = NameEvalEnvPrims.findTstr}
*)
          in
            AnalyzeFiles.analyzeFiles options dbparam (Loc.USERPATH, sourceFile)
          end
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
              outputFilename = SOME dstfile}
             srcfile;
           ())
        | {mode = SOME (Compile m), outputFilename = NONE, srcfiles, emitLLVM,
           ...} =>
          app (fn srcfile =>
                  (compileSMLFile
                     options
                     {outputFileType = filetype (m, emitLLVM),
                      outputFilename = NONE}
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
                | NONE => Filename.fromString (Config.A_OUT ())
          in
            link options {sourceFiles = srcfiles, outputFile = outputFile};
            ()
          end
      end

  fun main (progname, args) =
      let
        val _ = SignalHandler.init ()
        val r = RET (command (progname, args); SignalHandler.stop ())
                handle e => (SignalHandler.stop (); printExn progname e; ERR e)
        val _ = TempFile.cleanup ()
      in
        case r of
          ERR (SignalHandler.Signal _) => OS.Process.failure
        | _ =>
          (if !Control.doProfile
           then (print "Time Profile:\n"; print (Counter.dump ())) else ();
           case r of RET _ => OS.Process.success | ERR _ => OS.Process.failure)
      end

end
