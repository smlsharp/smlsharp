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
  structure BV = BuiltinEnv
  exception Error of string list

  fun optionToList NONE = nil
    | optionToList (SOME x) = [x]

  fun printErr s =
      TextIO.output (TextIO.stdErr, s)

  fun printVersion () =
      print ("SML# version " ^ SMLSharp_Version.Version
             ^ " (" ^ SMLSharp_Version.ReleaseDate ^ ") for "
             ^ !Control.targetPlatform ^ "\n")

  local
    fun userErrorToString e =
        Control.prettyPrint (UserError.format_errorInfo e)
    fun locToString loc =
        Control.prettyPrint (Loc.format_loc loc)
    fun printExnHistory e =
        case rev (SMLofNJ.exnHistory e) of
          nil => ()
        | h::t => (printErr ("    raised at: " ^ h ^ "\n");
                   case t of
                     nil => ()
                   | h::t => (printErr ("   handled at: " ^ h ^ "\n");
                              app (fn s => printErr ("\t\t" ^ s ^ "\n")) t))
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
      | Control.Bug msg =>
        (printErr ("[BUG] " ^ msg ^ "\n"); printExnHistory e)
      | Control.BugWithLoc (msg, loc) =>
        (printErr ("[BUG] " ^ locToString loc ^ ": " ^ msg ^ "\n");
         printExnHistory e)
      | _ =>
        (printErr ("uncaught exception: " ^ exnName e ^ ": "
                   ^ exnMessage e ^ "\n");
         printExnHistory e)

  end (* local *)

  datatype compilerMode =
      CompileOnly
    | AssembleOnly
    | SyntaxOnly
    | TypeCheckOnly
    | MakeDependCompile of {noStdPath: bool}
    | MakeDependLink of {noStdPath: bool}
    | PrintMainID
    | SHA1Sum

  datatype commandLineArgs =
      OutputFile of string
    | IncludePath of string
    | LibraryPath of string
    | Library of string
    | Mode of compilerMode
    | SourceFile of string
    | SystemBaseDir of string
    | LinkerFlags of string list
    | AssemblerFlags of string list
    | Target of string
    | Help
    | ControlSwitch of string
    | NoStdPath
    | Verbose

  fun splitComma "" = nil
    | splitComma src =
      let
        fun loop (ss, r) =
            case Substring.getc ss of
              SOME (#"\\", ss) =>
              (case Substring.getc ss of
                 SOME (c, ss) => loop (ss, c::r)
               | NONE => loop (ss, #"\\"::r))
            | SOME (#",", ss) =>
              String.implode (rev r) :: loop (ss, nil)
            | SOME (c, ss) => loop (ss, c::r)
            | NONE => [String.implode (rev r)]
      in
        loop (Substring.full src, nil)
      end

  val optionDesc =
      let
        open GetOpt
      in
        [
          SHORT (#"o", REQUIRED OutputFile),
          SHORT (#"c", NOARG (Mode CompileOnly)),
          SHORT (#"S", NOARG (Mode AssembleOnly)),
          SHORT (#"I", REQUIRED IncludePath),
          SHORT (#"L", REQUIRED LibraryPath),
          SHORT (#"l", REQUIRED Library),
          SHORT (#"v", NOARG Verbose),
          SHORT (#"B", REQUIRED SystemBaseDir),
          SHORT (#"M", NOARG (Mode (MakeDependCompile {noStdPath=false}))),
          SLONG ("MM", NOARG (Mode (MakeDependCompile {noStdPath=true}))),
          SLONG ("Ml", NOARG (Mode (MakeDependLink {noStdPath=false}))),
          SLONG ("MMl", NOARG (Mode (MakeDependLink {noStdPath=true}))),
          SLONG ("Wl", REQUIRED (fn x => LinkerFlags (splitComma x))),
          SLONG ("Wa", REQUIRED (fn x => AssemblerFlags (splitComma x))),
          SLONG ("fsyntax-only", NOARG (Mode SyntaxOnly)),
          SLONG ("ftypecheck-only", NOARG (Mode TypeCheckOnly)),
          SLONG ("fprint-main-ids", NOARG (Mode PrintMainID)),
          DLONG ("sha1", NOARG (Mode SHA1Sum)),
          SLONG ("target", REQUIRED Target),
          SLONG ("nostdpath", NOARG NoStdPath),
          DLONG ("help", NOARG Help),
          SHORT (#"d", REQUIRED ControlSwitch)
        ]
      end

  fun modeToOption mode =
      case mode of
        CompileOnly => "-c"
      | AssembleOnly => "-S"
      | SyntaxOnly => "-fsyntax-only"
      | TypeCheckOnly => "-ftypecheck-only"
      | MakeDependCompile {noStdPath=false} => "-M"
      | MakeDependCompile {noStdPath=true} => "-MM"
      | MakeDependLink {noStdPath=false} => "-Ml"
      | MakeDependLink {noStdPath=true} => "-MMl"
      | PrintMainID => "-fprint-main-ids"
      | SHA1Sum => "--sha1"

  fun usageMessage progname =
    "Usage: " ^ progname ^ " [options] file ...\n\
    \Options:\n\
    \  --help             print this message\n\
    \  -v                 verbose mode\n\
    \  -o <file>          place the output to <file>\n\
    \  -c                 compile only; do not assemble and link\n\
    \  -S                 compile and assemble; do not link\n\
    \  -M                 make dependency for compile\n\
    \  -MM                make dependency for compile but ignore system files\n\
    \  -Ml                make dependency for link\n\
    \  -MMl               make dependency for link but ignore system files\n\
    \  -fsyntax-only      check for syntax errors, and exit\n\
    \  -ftypecheck-only   check for type errors, and exit\n\
    \  -fprint-main-ids   print main entry identifiers, and exit\n\
    \  -I <dir>           add <dir> to file search path\n\
    \  -L <dir>           add <dir> to library path of the linker\n\
    \  -l <libname>       link with <libname> to create an executable file\n\
    \  -Wl,<args>         pass comma-separated <args> to the linker\n\
    \  -Wa,<args>         pass comma-separated <args> to the assembler\n\
    \  -target=<target>   set target platform to <target>\n\
    \  -nostdpath         no standard file search path is used\n\
    \  -d <key>=<value>   set extra option for compiler developers.\n"

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

  type loadOptions =
       {stopAt: Top.stopAt,
        stdPath: Filename.filename list,
        loadPath: Filename.filename list}

  type linkOptions =
       {dryRun: bool,
        systemBaseDir: Filename.filename,
        LDFLAGS: string list,
        LIBS: string list,
        outputFilename: Filename.filename}

  type dependOptions =
       {noStdPath: bool,
        outputFilename: Filename.filename option}

  datatype mainExp =
      CompileSML of Top.toplevelOptions * Filename.filename
    | LoadSMI of loadOptions * Filename.filename
    | LinkFile of Filename.filename
    | GenerateMain of Top.toplevelOptions * mainExp
    | Link of linkOptions * mainExp list
    | GenerateDepend of dependOptions * mainExp list
    | PrintHash of mainExp
    | PrintSHA1 of Filename.filename
    | Sequence of mainExp list
    | PrintHelp of {progname: string}
    | PrintVersion
    | Interactive of RunLoop.options                   

  fun setExtraOption src =
      let
        val ss = Substring.full src
        val (key, value) = Substring.splitl (fn c => #"=" <> c) ss
        val key = Substring.string key
        val value = Substring.string (Substring.triml 1 value)
      in
        case List.find (fn (x,_) => key = x) (Control.listSwitches ()) of
          NONE =>
          raise Error ["unknown extra option `" ^ key ^ "'"]
        | SOME (_, switch) =>
          (
            Control.interpretControlOption (key, switch, value)
            handle Fail msg => raise Error [msg]
          )
      end

  local
    fun replaceSuffix suffix filename =
        case Filename.suffix filename of
          SOME "smi" => Filename.addSuffix (filename, suffix)
        | _ => Filename.replaceSuffix suffix filename
  in

  fun toAsmTarget filename = replaceSuffix (SMLSharp_Config.ASMEXT()) filename
  fun toObjTarget filename = replaceSuffix (SMLSharp_Config.OBJEXT()) filename
  fun toExeTarget filename = Filename.removeSuffix filename

  end (* local *)

  fun toObjFile ({sourceName, ...}:AbsynInterface.interfaceName) =
      Filename.replaceSuffix (SMLSharp_Config.OBJEXT())
                             (Filename.fromString sourceName)

  fun compileArgs (progname, args) =
      let
        val defaultSystemBaseDir =
            case ExecutablePath.getPath () of
              NONE => Filename.fromString SMLSharp_Version.DefaultSystemBaseDir
            | SOME path =>
              Filename.concatPath
                (Filename.dirname (Filename.fromString path),
                 Filename.fromString "../lib/smlsharp")

        val systemBaseDir = ref defaultSystemBaseDir
        val noStdPath = ref false
        val loadPath = ref nil
        val LDFLAGS = ref nil
        val CFLAGS = ref nil
        val LIBS = ref nil
        val outputFilename = ref NONE
        val sources = ref nil
        val verbose = ref false
        val help = ref false
        val mode = ref NONE
        val extraOptions = ref nil

        fun processArg arg =
            case arg of
              OutputFile filename =>
              outputFilename := SOME (Filename.fromString filename)
            | IncludePath path =>
              loadPath := !loadPath @ [Filename.fromString path]
            | LibraryPath path =>
              LDFLAGS := !LDFLAGS @ ["-L" ^ path]
            | Library lib =>
              LIBS := !LIBS @ ["-l" ^ lib]
            | SourceFile filename =>
              sources := !sources @ [Filename.fromString filename]
            | SystemBaseDir filename =>
              systemBaseDir := Filename.fromString filename
            | LinkerFlags flags =>
              LDFLAGS := !LDFLAGS @ flags
            | AssemblerFlags flags =>
              CFLAGS := !CFLAGS @ flags
            | Target target =>
              raise Error ["-target is not supported"]
            | ControlSwitch pair =>
              extraOptions := pair :: !extraOptions
            | NoStdPath =>
              noStdPath := true
            | Verbose =>
              verbose := true
            | Help =>
              help := true
            | Mode newMode =>
              case !mode of
                NONE => mode := SOME newMode
              | SOME oldMode =>
                if oldMode = newMode then ()
                else raise Error ["cannot specify " ^ modeToOption oldMode
                                  ^ " with " ^ modeToOption newMode]

        val _ = app processArg args

        (* load and set default settings *)
        val _ = SMLSharp_Config.loadConfig (!systemBaseDir)
                handle SMLSharp_Config.Load =>
                       if !help then ()
                       else raise Error ["failed to read config.mk. Specify"
                                         ^ " correct path by -B option."]
        val _ = Control.printBinds := false
        val _ = Control.switchTrace := true
        val _ = Control.tracePrelude := true
        val _ = Control.targetPlatform := SMLSharp_Config.NATIVE_TARGET ()
        val _ = Control.printCommand := !verbose
        val _ = app setExtraOption (rev (!extraOptions))

        val stdPath = if !noStdPath then nil else [!systemBaseDir]

        fun GenMain stopAt dstfile exp =
            GenerateMain ({stopAt = stopAt,
                           dstfile = dstfile,
                           baseName = NONE,
                           stdPath = nil,
                           loadPath = nil,
                           asmFlags = !CFLAGS},
                          exp)
        fun CompileSmi stopAt dstfile srcfile =
            GenMain stopAt dstfile
                    (LoadSMI ({stopAt = stopAt,
                               stdPath = stdPath,
                               loadPath = !loadPath},
                              srcfile))
        fun CompileSml stopAt dstfile srcfile =
            CompileSML ({stopAt = stopAt,
                         dstfile = dstfile,
                         baseName = SOME srcfile,
                         stdPath = stdPath,
                         loadPath = !loadPath,
                         asmFlags = !CFLAGS},
                        srcfile)
        fun Compile stopAt dstfile srcfile =
            case Filename.suffix srcfile of
              SOME "smi" => CompileSmi stopAt dstfile srcfile
            | _ => CompileSml stopAt dstfile srcfile
      in
        case (!help, !mode, !outputFilename, !sources) of
          (true, _, _, _) =>
          PrintHelp {progname=progname}
        | (false, _, _, nil) =>
          if !verbose
          then PrintVersion
          else if RunLoop.available ()
          then Sequence
                 [PrintVersion,
                  Interactive {asmFlags = !CFLAGS,
                               systemBaseDir = !systemBaseDir,
                               stdPath = stdPath,
                               loadPath = !loadPath,
                               LDFLAGS = !LDFLAGS,
                               LIBS = !LIBS,
                               errorOutput = TextIO.stdOut}]
          else raise Error ["no input files"]
        | (false, SOME (MakeDependCompile {noStdPath}), dstfile, sources) =>
          GenerateDepend
            ({noStdPath = noStdPath, outputFilename = dstfile},
             map (fn src =>
                     Compile Top.SyntaxCheck (SOME (toObjTarget src)) src)
                 sources)
        | (false, SOME (MakeDependLink {noStdPath}), dstfile, sources) =>
          GenerateDepend
            ({noStdPath = noStdPath, outputFilename = dstfile},
             map (fn src =>
                     Link
                       ({dryRun = true,
                         systemBaseDir = !systemBaseDir,
                         LDFLAGS = !LDFLAGS,
                         LIBS = !LIBS,
                         outputFilename = toExeTarget src},
                        [CompileSmi Top.SyntaxCheck
                                    (SOME (toObjTarget src)) src]))
                 sources)
        | (false, SOME SyntaxOnly, SOME _, _) =>
          raise Error ["cannot specify -o with -fsyntax-only"]
        | (false, SOME SyntaxOnly, NONE, sources) =>
          Sequence (map (Compile Top.SyntaxCheck NONE) sources)
        | (false, SOME TypeCheckOnly, SOME _, _) =>
          raise Error ["cannot specify -o with -ftypecheck-only"]
        | (false, SOME TypeCheckOnly, NONE, sources) =>
          Sequence (map (Compile Top.ErrorCheck NONE) sources)
        | (false, SOME AssembleOnly, NONE, sources) =>
          Sequence
            (map (fn src => Compile Top.Assembly (SOME (toAsmTarget src)) src)
                 sources)
        | (false, SOME AssembleOnly, SOME _, _::_::_) =>
          raise Error ["cannot specify -o with -S with multiple files"]
        | (false, SOME AssembleOnly, SOME filename, [source]) =>
          Compile Top.Assembly (SOME filename) source
        | (false, SOME CompileOnly, NONE, sources) =>
          Sequence
            (map (fn src => Compile Top.NoStop (SOME (toObjTarget src)) src)
                 sources)
        | (false, SOME CompileOnly, SOME _, _::_::_) =>
          raise Error ["cannot specify -o with -c with multiple files"]
        | (false, SOME CompileOnly, SOME filename, [source]) =>
          Compile Top.NoStop (SOME filename) source
        | (false, SOME PrintMainID, SOME _, _) =>
          raise Error ["cannot specify -o with -fprint-main-ids"]
        | (false, SOME PrintMainID, NONE, sources) =>
          Sequence 
            (map (fn src =>
                     PrintHash
                       (LoadSMI ({stopAt = Top.SyntaxCheck,
                                  stdPath = stdPath,
                                  loadPath = !loadPath}, src)))
                 sources)
        | (false, SOME SHA1Sum, SOME _, _) =>
          raise Error ["cannot specify -o with --sha1"]
        | (false, SOME SHA1Sum, NONE, sources) =>
          Sequence (map PrintSHA1 sources)
        | (false, NONE, outputFilename, sources) =>
          let
            val sources =
                map (fn filename =>
                        case Filename.suffix filename of
                          SOME "sml" =>
                          GenMain Top.NoStop NONE
                                  (CompileSml Top.NoStop NONE filename)
                        | SOME "smi" => CompileSmi Top.NoStop NONE filename
                        | _ => LinkFile filename)
                    sources
            val _ =
                case List.filter (fn LinkFile _ => false | _ => true) sources of
                  nil => ()
                | [_] => ()
                | _::_::_ =>
                  raise Error ["cannot specify multiple .sml/.smi files\
                               \ in link mode"]
            val outputFilename =
                case outputFilename of
                  SOME filename => filename
                | NONE => Filename.fromString "a.out"
            val options =
                {dryRun = false,
                 systemBaseDir = !systemBaseDir,
                 LDFLAGS = !LDFLAGS,
                 LIBS = !LIBS,
                 outputFilename = outputFilename}
          in
            Link (options, sources)
          end
      end

  fun parseBuiltin {name, body} =
      let
        val src = TextIO.openString body
        val input = InterfaceParser.setup
                      {read = fn n => TextIO.inputN (src, n),
                       sourceName = name}
        val absyn = InterfaceParser.parse input
      in
        case absyn of
          AbsynInterface.INTERFACE {requires=nil, topdecs} => topdecs
        | _ => raise Control.Bug "parseBuiltin"
      end

  val initBuiltin =
      let
        val absyns = map parseBuiltin BuiltinContextSources.sources
        val topdecs = List.concat absyns
        val interface =
            {decls=nil, interfaceName=NONE, requires=nil, topdecs=topdecs}
        val abunit =
            {interface=interface, topdecs=nil}
        val (fixEnv, plunit, warnings) =
            Elaborator.elaborateRequire abunit
        val (topEnv, builtinEnv, idcalc) =
            NameEval.evalBuiltin (#topdecs (#interface plunit))
        val version = NONE
      in
        BV.init builtinEnv;
        fn () => {topEnv=topEnv, version=version, fixEnv=fixEnv,
                  builtinDecls=idcalc}
                 : Top.toplevelContext
      end
  
  fun compileFile options (io, sourceName) =
      let
        val input =
            Parser.setup {mode = Parser.File,
                          read = fn (_,n) => TextIO.inputN (io, n),
                          sourceName = sourceName,
                          initialLineno = 1}
        val context = initBuiltin ()
        val (depends, result) = Top.compile options context input
      in
        case result of
          Top.RETURN (_, Top.FILE code) => (SOME code, depends)
        | Top.STOPPED => (#dstfile options, depends)
      end

  fun toLinkObjFile {code, interface:AbsynInterface.interfaceName option} =
      case (code, interface) of
        (SOME filename, NONE) =>
        SOME (AbsynInterface.LOCALPATH, filename)
      | (SOME filename, SOME {place, ...}) =>
        SOME (place, filename)
      | (NONE, NONE) => NONE
      | (NONE, SOME (interface as {place, ...})) =>
        SOME (place, toObjFile interface)

  fun checkFileExist filenames =
      case List.filter (fn f => not (CoreUtils.testExist f)) filenames of
        nil => ()
      | files =>
        raise Error (map (fn f => "required object file is not found: "
                                  ^ Filename.toString f) files)

  local
    fun filterDepends noStdPath depends =
        if noStdPath
        then List.filter
               (fn (AbsynInterface.LOCALPATH, _:string) => true
                 | (AbsynInterface.STDPATH, _) => false)
               depends
        else depends

    fun format w nil = "\n"
      | format w (h::t) =
        let
          val h = if w = 0 then h else " " ^ h
          val n = size h
        in
          if n + w > 78
          then " \\\n " ^ h ^ format (1 + n) t
          else h ^ format(w + n) t
        end
  in

  fun outputDepends {noStdPath, outputFilename} rules =
      let
        val output =
            map (fn (target, depends) =>
                    format 0 ((target ^ ":")
                              :: map #2 (filterDepends noStdPath depends)))
                rules
      in
        case outputFilename of
          NONE => app print output
        | SOME dstfile =>
          CoreUtils.makeTextFile (dstfile, String.concat output)
      end

  end (* local *)

  fun evalMain exp =
      case exp of
        PrintHelp {progname} =>
        (
         #start Counter.printHelpTimeCounter();
         print (usageMessage progname);
         #stop Counter.printHelpTimeCounter();
         {result={code=NONE, interface=NONE}, requires=nil, loaded=nil}
        )
      | PrintVersion =>
        (
          printVersion ();
          {result={code=NONE, interface=NONE}, requires=nil, loaded=nil}
        )
      | Interactive options =>
        let
          val context = initBuiltin ()
          val _ = #start Counter.loadInterfaceTimeCounter()
          val (_, result) =
              Top.loadInterface
                {stopAt = Top.NoStop,
                 stdPath = #stdPath options, 
                 loadPath = #loadPath options}
                context
                (Filename.concatPath
                   (#systemBaseDir options,
                    Filename.fromString "prelude.smi"))
          val _ = #stop Counter.loadInterfaceTimeCounter()
          val context =
              case result of
                SOME newContext =>
                let
                  val {fixEnv, topEnv, version, builtinDecls} =
                      Top.extendContext (context, newContext)
                  val version = IDCalc.incVersion version
                  val builtinDecls =
                      builtinDecls
                      @ NameEvalEnvUtils.externOverloadInstances topEnv
                in
                  {fixEnv = fixEnv, topEnv = topEnv,
                   version = version,
                   builtinDecls = builtinDecls} : Top.toplevelContext
                end
              | NONE => raise Control.Bug "evalMain: Interactive"
          val _ = ReifiedTermData.init (#topEnv context)
                  handle e => raise e
        in
          (
           RunLoop.interactive options context;
           {result={code=NONE, interface=NONE}, requires=nil, loaded=nil}
          )
        end
      | CompileSML (options, filename) =>
        let
          val io = Filename.TextIO.openIn filename
          val _ = #start Counter.compileFileTimeCounter()
          val (code, {requires, provide, depends}) =
              compileFile options (io, Filename.toString filename)
              handle e => (TextIO.closeIn io; raise e)
          val _ = #stop Counter.compileFileTimeCounter()
          val _ = TextIO.closeIn io
        in
          {result = {code = code, interface = provide},
           requires = map (fn x => {code = NONE, interface = SOME x}) requires,
           loaded = (AbsynInterface.LOCALPATH, Filename.toString filename)
                    :: depends}
        end
      | LoadSMI (options, filename) =>
        let
          val _ = #start Counter.loadSMITimeCounter()
          val context = initBuiltin ()
          val ({requires, provide, depends}, _) =
              Top.loadInterface options context filename
          val _ = #stop Counter.loadSMITimeCounter()
        in
          {result = {code = NONE, interface = provide},
           requires = map (fn x => {code = NONE, interface = SOME x}) requires,
           loaded = (AbsynInterface.LOCALPATH, Filename.toString filename)
                    :: depends}
        end
      | GenerateMain (options, exp) =>
        let
          val _ = #start Counter.generateMainTimeCounter()
          val results as {result, requires, loaded} = evalMain exp
          val requires = requires @ [result]
          val mainSymbols = List.mapPartial #interface requires
        in
          case mainSymbols of
            nil => results
          | _ =>
            let
              val mainCode = GenerateMain.generate mainSymbols
              val io = TextIO.openString mainCode
              val (code, _) = compileFile options (io, "(main)")
              val _ = #stop Counter.generateMainTimeCounter()
            in
              {result = {code = code, interface = NONE},
               requires = requires,
               loaded = loaded}
            end
        end
      | LinkFile filename =>
        {result = {code = SOME filename, interface = NONE},
         requires = nil, loaded = nil}
      | Link (options, exps) =>
        let
          val _ = #start Counter.linkTimeCounter()
          val {dryRun, systemBaseDir, LDFLAGS, LIBS, outputFilename} = options
          val results = map evalMain exps
          val objfiles =
              List.concat
                (map
                   (fn {result, requires, ...} =>
                       let
                         val result = toLinkObjFile result
                         val requires = List.mapPartial toLinkObjFile requires
                       in
                         if dryRun then ()
                         else checkFileExist (map #2 requires);
                         rev (optionToList result @ requires)
                       end)
                   results)
          val runtimeDir = Filename.fromString "runtime"
          val runtimeDir = Filename.concatPath (systemBaseDir, runtimeDir)
          val libsmlsharp = Filename.fromString "libsmlsharp.a"
          val libsmlsharp = Filename.concatPath (runtimeDir, libsmlsharp)
          val smlsharpEntry = Filename.fromString "smlsharp_entry.o"
          val smlsharpEntry = Filename.concatPath (runtimeDir, smlsharpEntry)
        in
          if dryRun then ()
          else BinUtils.link {flags = LDFLAGS,
                              libs = Filename.toString libsmlsharp :: LIBS,
                              objects = smlsharpEntry :: map #2 objfiles,
                              dst = outputFilename,
                              quiet = false};
          #stop Counter.linkTimeCounter();
          {result = {code = SOME outputFilename, interface = NONE},
           requires = nil,
           loaded = map (fn (x, y) => (x, Filename.toString y)) objfiles}
        end
      | GenerateDepend (options, exps) =>
        let
          val _ = #start Counter.generateDependTimeCounter()
          val results = map evalMain exps
          val rules =
              List.mapPartial
                (fn {result={code=SOME target,...}, loaded, ...} =>
                    SOME (Filename.toString target, loaded)
                  | _ => NONE)
                results
        in
          outputDepends options rules;
          #stop Counter.generateDependTimeCounter();
          {result={code=NONE, interface=NONE}, requires=nil, loaded=nil}
        end
      | PrintHash exp =>
        let
          val results as {result, requires, loaded} = evalMain exp
        in
          app (fn {code, interface} =>
                  case interface of
                    NONE => ()
                  | SOME {hash, sourceName, ...} =>
                    print (hash ^ " " ^ sourceName ^ "\n"))
              requires;
          results
        end
      | PrintSHA1 filename =>
        let
          val f = Filename.BinIO.openIn filename
          val src = BinIO.inputAll f handle e => (BinIO.closeIn f; raise e)
          val _ = BinIO.closeIn f
          val hash = SHA1.toBase32 (SHA1.digest src)
        in
          print (hash ^ " " ^ Filename.toString filename ^ "\n");
          {result={code=NONE, interface=NONE}, requires=nil, loaded=nil}
        end
      | Sequence nil =>
        {result={code=NONE, interface=NONE}, requires=nil, loaded=nil}
      | Sequence (exp::exps) =>
        (evalMain exp; evalMain (Sequence exps))

  fun main (progname, args) =
      let
        val _ = #start Counter.parseArgsTimeCounter()
        val args = parseArgs args
        val _ = #stop Counter.parseArgsTimeCounter()
        val _ = #start Counter.compileArgsTimeCounter()
        val mainExp = compileArgs (progname, args)
        val _ = #stop Counter.compileArgsTimeCounter()
        val _ = evalMain mainExp
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
