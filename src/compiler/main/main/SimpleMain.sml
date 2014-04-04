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

  structure I = AbsynInterface

  exception Error of string list

  val defaultSystemBaseDir =
      case ExecutablePath.getPath () of
        NONE => Filename.fromString SMLSharp_Version.DefaultSystemBaseDir
      | SOME path =>
        Filename.concatPath
          (Filename.dirname (Filename.fromString path),
           Filename.fromString "../lib/smlsharp")

  fun loadBuiltin systemBaseDir =
      Top.loadBuiltin
        (Filename.concatPath
           (systemBaseDir, Filename.fromString "builtin.smi"))

  fun printErr s =
      TextIO.output (TextIO.stdErr, s)

  fun printVersion () =
      print ("SML# " ^ SMLSharp_Version.Version
             ^ " (" ^ SMLSharp_Version.ReleaseDate ^ ") for "
             ^ SMLSharp_Config.TARGET_TRIPLE ()
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
    | OptLevel of LLVM.OptLevel * LLVM.SizeLevel
    | CodeModel of string
    | RelocModel of LLVM.RelocModel
    | TargetArch of string
    | TargetCPU of string
    | TargetAttrs of string list
    | Mode of compilerMode
    | SourceFile of string
    | SystemBaseDir of string
    | LinkerFlags of string list
    | Help
    | ControlSwitch of string option
    | NoStdPath
    | NoStdLib
    | Verbose
    | UseCXX
    | EmitLLVM
    | FileMap of string

  fun stringToCodeModel model =
      case model of
        "small" => LLVM.CodeModelSmall
      | "medium" => LLVM.CodeModelMedium
      | "large" => LLVM.CodeModelLarge
      | "kernel" => LLVM.CodeModelKernel
      | _ => raise Error ["code model `" ^ model ^ "' is not supported"]

  val optionDesc =
      let
        fun splitComma s = String.fields (fn c => #"," = c) s
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
          SLONG ("O0", NOARG (OptLevel (LLVM.OptNone, LLVM.SizeDefault))),
          SLONG ("O1", NOARG (OptLevel (LLVM.OptLess, LLVM.SizeDefault))),
          SLONG ("O", NOARG (OptLevel (LLVM.OptDefault, LLVM.SizeDefault))),
          SLONG ("O2", NOARG (OptLevel (LLVM.OptDefault, LLVM.SizeDefault))),
          SLONG ("O3", NOARG (OptLevel (LLVM.OptAggressive, LLVM.SizeDefault))),
          SLONG ("Os", NOARG (OptLevel (LLVM.OptDefault, LLVM.SizeSmall))),
          SLONG ("Oz", NOARG (OptLevel (LLVM.OptDefault, LLVM.SizeVerySmall))),
          SLONG ("mcmodel", REQUIRED CodeModel),
          SLONG ("march", REQUIRED TargetArch),
          SLONG ("mcpu", REQUIRED TargetCPU),
          SLONG ("mattr", REQUIRED (TargetAttrs o splitComma)),
          SLONG ("fpic", NOARG (RelocModel LLVM.RelocPIC)),
          SLONG ("fPIC", NOARG (RelocModel LLVM.RelocPIC)),
          SLONG ("fno-pic", NOARG (RelocModel LLVM.RelocStatic)),
          SLONG ("mdynamic-no-pic",
                 NOARG (RelocModel LLVM.RelocDynamicNoPIC)),
          SLONG ("MM", NOARG (Mode (MakeDependCompile {noStdPath=true}))),
          SLONG ("Ml", NOARG (Mode (MakeDependLink {noStdPath=false}))),
          SLONG ("MMl", NOARG (Mode (MakeDependLink {noStdPath=true}))),
          SLONG ("Wl", REQUIRED (fn x => LinkerFlags (splitComma x))),
          SLONG ("Xlinker", REQUIRED (fn x => LinkerFlags [x])),
          SLONG ("fsyntax-only", NOARG (Mode SyntaxOnly)),
          SLONG ("ftypecheck-only", NOARG (Mode TypeCheckOnly)),
          SLONG ("fprint-main-ids", NOARG (Mode PrintMainID)),
          SLONG ("emit-llvm", NOARG EmitLLVM),
          SLONG ("c++", NOARG (UseCXX)),
          SLONG ("filemap", REQUIRED FileMap),
          DLONG ("sha1", NOARG (Mode SHA1Sum)),
          SLONG ("nostdpath", NOARG NoStdPath),
          SLONG ("nostdlib", NOARG NoStdLib),
          DLONG ("help", NOARG Help),
          SHORT (#"d", OPTIONAL ControlSwitch)
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
    \  -c                 compile and assemble; do not link\n\
    \  -S                 compile only; do not assemble and link\n\
    \  -emit-llvm         emit LLVM code instead of native machine code\n\
    \  -O[0-3]            set optimization level to 0-3\n\
    \  -Os                optimize for code size\n\
    \  -Oz                optimize for code size aggressively\n\
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
    \  -fprint-main-ids   print main entry identifiers, and exit\n\
    \  -filemap=<file>    specify a map from interface files to object files\n\
    \  -I <dir>           add <dir> to file search path\n\
    \  -L <dir>           add <dir> to library path of the linker\n\
    \  -l <libname>       link with <libname> to create an executable file\n\
    \  -Wl,<args>         pass comma-separated <args> to the linker\n\
    \  -Xlinker <arg>     pass <arg> to the linker\n\
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

  datatype mainExp =
      Let of mainExp * mainExp
    | Var of int  (* de bruijn index *)
    | List of mainExp list
    | Sequence of mainExp list
    | Ignore of mainExp
    | CodeOf of mainExp
    | CompileSML of Top.options * Top.toplevelContext * Filename.filename
    | LoadSMI of {stdPath: Filename.filename list,
                  loadPath: Filename.filename list} * Filename.filename
    | GenerateMain of Top.toplevelContext * mainExp
    | RequiredObjects of FilenameMap.map option * mainExp
    | LinkFile of Filename.filename
    | LoadBitcode of Filename.filename
    | Link of LLVM.compile_options * link_options * mainExp list
    | LLVMCompile of LLVM.compile_options * LLVM.FileType * Filename.filename
                     * mainExp
    | PrinterOutput of Filename.filename option * mainExp
    | PrintDependCompile of depend_options * mainExp
    | PrintDependLink of depend_options * mainExp
    | PrintVersion
    | PrintHelp of {progname: string, forDevelopers: bool}
    | Interactive of RunLoop.options * Top.toplevelContext
    | PrintHashes of mainExp
    | PrintSHA1 of Filename.filename

  datatype mainResult =
      SUCCESS
    | LIST of mainResult list
    | SML of LoadFile.dependency * LLVM.LLVMModuleRef option
    | SMI of LoadFile.dependency
    | CODE of LLVM.LLVMModuleRef
    | LINKFILE of Filename.filename

  fun moduleOf (CODE module) = module
    | moduleOf _ = raise Bug.Bug "moduleOf"

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

  local
    fun replaceSuffix suffix filename =
        case Filename.suffix filename of
          SOME "smi" => Filename.addSuffix (filename, suffix)
        | _ => Filename.replaceSuffix suffix filename
  in

  fun toAsmTarget filename = replaceSuffix (SMLSharp_Config.ASMEXT ()) filename
  fun toObjTarget filename = replaceSuffix (SMLSharp_Config.OBJEXT ()) filename
  fun toLLTarget filename = replaceSuffix LLVM.ASMEXT filename
  fun toBCTarget filename = replaceSuffix LLVM.OBJEXT filename
  fun toExeTarget filename = Filename.removeSuffix filename

  end (* local *)

  fun defaultExeTarget () =
      case SMLSharp_Config.HOST_OS_TYPE () of
        SMLSharp_Config.Mingw => Filename.fromString "a.exe"
      | _ => Filename.fromString "a.out"

  local
    fun toObjFile smifile =
        Filename.replaceSuffix (SMLSharp_Config.OBJEXT ()) smifile
  in

  fun interfaceNameToObjFile fileMap interfaceName =
      case interfaceName of
        {hash, source = (I.STDPATH, path)} =>
        (I.STDPATH, toObjFile path)
      | {hash, source = (I.LOCALPATH, path)} =>
        case fileMap of
          NONE => (I.LOCALPATH, toObjFile path)
        | SOME fileMap =>
          case FilenameMap.find (fileMap, path) of
            SOME filename => (I.LOCALPATH, filename)
          | NONE => raise Error ["object file is not found in filemap: "
                                 ^ Filename.toString path]

  end (* local *)

  fun compileArgs (progname, args) =
      let
        val systemBaseDir = ref NONE
        val noStdPath = ref false
        val noStdLib = ref false
        val loadPath = ref nil
        val LDFLAGS = ref nil
        val LIBS = ref nil
        val optLevel = ref (LLVM.OptNone, LLVM.SizeDefault)
        val codeModel = ref LLVM.CodeModelDefault
        val relocModel = ref NONE
        val march = ref ""
        val mcpu = ref ""
        val mattrs = ref nil
        val outputFilename = ref NONE
        val sources = ref nil
        val verbose = ref false
        val help = ref NONE
        val mode = ref NONE
        val extraOptions = ref nil
        val fileMap = ref NONE
        val useCXX = ref false
        val emitLLVM = ref false

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
            | OptLevel level =>
              optLevel := level
            | CodeModel model =>
              codeModel := stringToCodeModel model
            | RelocModel mode =>
              relocModel := SOME mode
            | TargetArch arch =>
              march := arch
            | TargetCPU cpu =>
              mcpu := cpu
            | TargetAttrs attrs =>
              mattrs := attrs
            | UseCXX =>
              useCXX := true
            | EmitLLVM =>
              emitLLVM := true
            | NoStdPath =>
              noStdPath := true
            | NoStdLib =>
              noStdLib := true
            | SourceFile filename =>
              sources := !sources @ [Filename.fromString filename]
            | SystemBaseDir filename =>
              systemBaseDir := SOME (Filename.fromString filename)
            | LinkerFlags flags =>
              LDFLAGS := !LDFLAGS @ flags
            | FileMap filename =>
              fileMap := SOME (Filename.fromString filename)
            | ControlSwitch (SOME pair) =>
              extraOptions := pair :: !extraOptions
            | ControlSwitch NONE =>
              help := SOME true
            | Help =>
              help := SOME false
            | Verbose =>
              verbose := true
            | Mode newMode =>
              case !mode of
                NONE => mode := SOME newMode
              | SOME oldMode =>
                if oldMode = newMode then ()
                else raise Error ["cannot specify " ^ modeToOption oldMode
                                  ^ " with " ^ modeToOption newMode]

        val _ = app processArg args

        (* load and set default settings *)
        val _ =
            case !systemBaseDir of
              NONE => ()
            | SOME systemBaseDir =>
              SMLSharp_Config.loadConfig systemBaseDir
              handle SMLSharp_Config.Load =>
                     raise Error ["failed to read config.mk. Specify"
                                  ^ " correct path by -B option."]

        val systemBaseDir =
            case !systemBaseDir of
              NONE => defaultSystemBaseDir
            | SOME dir => dir

        val relocModel =
            case !relocModel of
              SOME mode => mode
            | NONE => if SMLSharp_Config.PIC_DEFAULT ()
                      then LLVM.RelocPIC
                      else LLVM.RelocDefault

        val initialContext = loadBuiltin systemBaseDir

        val _ = Control.printCommand := !verbose
        val _ = app setExtraOption (rev (SMLSharp_Config.EXTRA_OPTIONS ()))
        val _ = app setExtraOption (rev (!extraOptions))

        val stdPath = if !noStdPath then nil else [systemBaseDir]

        val fileMap =
            case !fileMap of
              NONE => NONE
            | SOME filename =>
              SOME (FilenameMap.load filename)
              handle FilenameMap.Load =>
                     raise Error [Filename.toString filename
                                  ^ ": failed to read filemap"]

        fun defaultAsmTarget srcfile =
            if !emitLLVM then toLLTarget srcfile else toAsmTarget srcfile
        fun defaultObjTarget srcfile =
            if !emitLLVM then toBCTarget srcfile else toObjTarget srcfile

        fun llvmCompileOptions () =
            {arch = !march,
             cpu = !mcpu,
             attrs = !mattrs,
             optLevel = #1 (!optLevel),
             sizeLevel = #2 (!optLevel),
             relocModel = relocModel,
             codeModel = !codeModel} : LLVM.compile_options

        fun WriteAsm dstfile exp =
            LLVMCompile
              (llvmCompileOptions (),
               if !emitLLVM then LLVM.IRFile else LLVM.AssemblyFile,
               dstfile, exp)
        fun WriteObj dstfile exp =
            LLVMCompile
              (llvmCompileOptions (),
               if !emitLLVM then LLVM.BitcodeFile else LLVM.ObjectFile,
               dstfile, exp)

        fun LoadSmi stopAt srcfile =
            LoadSMI ({stdPath = stdPath,
                      loadPath = !loadPath},
                     srcfile)
        fun CompileSml stopAt srcfile =
            CompileSML ({stopAt = stopAt,
                         baseFilename = SOME srcfile,
                         stdPath = stdPath,
                         loadPath = !loadPath},
                        initialContext,
                        srcfile)
        fun GenMain srcfile =
            GenerateMain (initialContext, srcfile)
        fun Compile stopAt srcfile =
            case Filename.suffix srcfile of
              SOME "smi" => GenMain (LoadSmi stopAt srcfile)
            | _ => CodeOf (CompileSml stopAt srcfile)
        fun Load stopAt srcfile =
            case Filename.suffix srcfile of
              SOME "smi" => LoadSmi stopAt srcfile
            | _ => CompileSml stopAt srcfile
      in
        case (!help, !mode, !outputFilename, !sources) of
          (SOME devhelp, _, _, _) =>
          PrintHelp {progname = progname, forDevelopers = devhelp}
        | (NONE, _, _, nil) =>
          if !verbose
          then PrintVersion
          else Sequence
                 [PrintVersion,
                  Interactive ({systemBaseDir = systemBaseDir,
                                stdPath = stdPath,
                                loadPath = !loadPath,
                                LDFLAGS = !LDFLAGS,
                                LIBS = !LIBS,
                                llvmOptions = llvmCompileOptions (),
                                errorOutput = TextIO.stdOut},
                               initialContext)]
        | (NONE, SOME (MakeDependCompile {noStdPath}), dstfile, sources) =>
          PrinterOutput
            (dstfile,
             Sequence
               (map (fn srcfile =>
                        PrintDependCompile
                          ({noStdPath = noStdPath,
                            source = Filename.toString srcfile,
                            target = Filename.toString
                                       (defaultObjTarget srcfile)},
                           Load Top.SyntaxCheck srcfile))
                    sources))
        | (NONE, SOME (MakeDependLink {noStdPath}), dstfile, sources) =>
          PrinterOutput
            (dstfile,
             Sequence
               (map (fn srcfile =>
                        PrintDependLink
                          ({noStdPath = noStdPath,
                            source = Filename.toString srcfile,
                            target = Filename.toString (toExeTarget srcfile)},
                           Load Top.SyntaxCheck srcfile))
                    sources))
        | (NONE, SOME SyntaxOnly, SOME _, _) =>
          raise Error ["cannot specify -o with -fsyntax-only"]
        | (NONE, SOME SyntaxOnly, NONE, sources) =>
          Sequence (map (fn x => Ignore (Load Top.SyntaxCheck x)) sources)
        | (NONE, SOME TypeCheckOnly, SOME _, _) =>
          raise Error ["cannot specify -o with -ftypecheck-only"]
        | (NONE, SOME TypeCheckOnly, NONE, sources) =>
          Sequence (map (fn x => Ignore (Load Top.ErrorCheck x)) sources)
        | (NONE, SOME AssembleOnly, NONE, sources) =>
          Sequence
            (map (fn srcfile => WriteAsm (defaultAsmTarget srcfile)
                                         (Compile Top.NoStop srcfile))
                 sources)
        | (NONE, SOME AssembleOnly, SOME _, _::_::_) =>
          raise Error ["cannot specify -o with -S with multiple files"]
        | (NONE, SOME AssembleOnly, SOME filename, [source]) =>
          WriteAsm filename (Compile Top.NoStop source)
        | (NONE, SOME CompileOnly, NONE, sources) =>
          Sequence
            (map (fn srcfile => WriteObj (defaultObjTarget srcfile)
                                         (Compile Top.NoStop srcfile))
                 sources)
        | (NONE, SOME CompileOnly, SOME _, _::_::_) =>
          raise Error ["cannot specify -o with -c with multiple files"]
        | (NONE, SOME CompileOnly, SOME filename, [source]) =>
          WriteObj filename (Compile Top.NoStop source)
        | (NONE, SOME PrintMainID, outputFilename, sources) =>
          PrinterOutput
            (outputFilename,
             Sequence
               (map (fn srcfile => PrintHashes (Load Top.SyntaxCheck srcfile))
                    sources))
        | (NONE, SOME SHA1Sum, outputFilename, sources) =>
          PrinterOutput
            (outputFilename,
             Sequence (map PrintSHA1 sources))
        | (NONE, NONE, outputFilename, sources) =>
          let
            val exps =
                map (fn srcfile =>
                        case Filename.suffix srcfile of
                          SOME "sml" =>
                          Let (CompileSml Top.NoStop srcfile,
                               List [GenMain (Var 0),
                                     RequiredObjects (fileMap, Var 0)])
                        | SOME "smi" =>
                          Let (LoadSmi Top.NoStop srcfile,
                               List [GenMain (Var 0),
                                     RequiredObjects (fileMap, Var 0)])
                        | _ => LinkFile srcfile)
                    sources
            val _ =
                case List.filter (fn Let _ => true | _ => false) exps of
                  nil => ()
                | [_] => ()
                | _::_::_ => raise Error ["cannot specify multiple .sml/.smi \
                                          \files in link mode"]
            val dstfile =
                case outputFilename of
                  SOME filename => filename
                | NONE => defaultExeTarget ()
          in
            Link (llvmCompileOptions (),
                  {systemBaseDir = systemBaseDir,
                   noStdLib = !noStdLib,
                   useCXX = !useCXX,
                   LDFLAGS = !LDFLAGS,
                   LIBS = !LIBS,
                   dstfile = dstfile},
                  exps)
          end
      end

(*
  fun loadBuiltin () =
      Top.loadBuiltin
        (Filename.concatPath
           (!systemBaseDir, Filename.fromString "builtin.smi"))
*)

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
      (
        app (fn s => TextIO.output (out, s))
            (format 0 (target ^ ":" :: sources));
        TextIO.output (out, "\n")
      )

  end (* local *)

  fun filterLOCALPATH files =
      List.filter (fn (I.LOCALPATH, _) => true | (I.STDPATH, _) => false) files

  type env = {vars: mainResult list, printOut: TextIO.outstream}

  val emptyEnv = {vars = nil, printOut = TextIO.stdOut} : env

  fun evalMain (env:env) mainExp =
      case mainExp of
        Let (exp1, exp2) =>
        let
          val result1 = evalMain env exp1
          val env = env # {vars = result1 :: #vars env}
        in
          evalMain env exp2
        end
      | Var i =>
        (List.nth (#vars env, i)
         handle Subscript => raise Bug.Bug "evalMain: Var")
      | List exps =>
        LIST (map (evalMain env) exps)
      | Sequence nil => SUCCESS
      | Sequence (exp::exps) =>
        (
          case evalMain env exp of
            SUCCESS => evalMain env (Sequence exps)
          | _ => raise Bug.Bug "evalMain: Sequence"
        )
      | Ignore exp =>
        (
          evalMain env exp;
          SUCCESS
        )
      | PrinterOutput (NONE, exp) =>
        evalMain (env # {printOut = TextIO.stdOut}) exp
      | PrinterOutput (SOME filename, exp) =>
        let
          val out = Filename.TextIO.openOut filename
          val result = evalMain (env # {printOut = out}) exp
                       handle e => (TextIO.closeOut out; raise e)
          val _ = TextIO.closeOut out
        in
          result
        end
      | CompileSML (options, context, filename) =>
        let
          val io = Filename.TextIO.openIn filename
          val (depends, result) =
              Top.compile options context
                          (Parser.setup
                             {mode = Parser.File,
                              read = fn (_,n) => TextIO.inputN (io, n),
                              sourceName = Filename.toString filename,
                              initialLineno = 1})
              handle e => (TextIO.closeIn io; raise e)
          val _ = TextIO.closeIn io
          val code =
              case result of
                Top.RETURN (_, module) => SOME module
              | Top.STOPPED => NONE
        in
          SML (depends, code)
        end
      | CodeOf exp =>
        (
          case evalMain env exp of
            SML (_, SOME module) => CODE module
          | CODE module => CODE module
          | _ => raise Bug.Bug "evalMain: ModuleOf"
        )
      | LoadSMI (options, filename) =>
        let
          val dependency = LoadFile.generateDependency options filename
        in
          SMI dependency
        end
      | GenerateMain (context, exp) =>
        let
          val {interfaceNameOpt, link, ...} =
              case evalMain env exp of
                SMI depends => depends
              | SML (depends, _) => depends
              | _ => raise Bug.Bug "evalMain: GenerateMain"
          val module = 
              Top.generateMain context (rev (interfaceNameOpt :: map SOME link))
        in
          CODE module
        end
      | RequiredObjects (fileMap, exp) =>
        let
          val (requires, modules) =
              case evalMain env exp of
                SMI {interfaceNameOpt, link, ...} =>
                (case interfaceNameOpt of
                   NONE => (link, nil)
                 | SOME interfaceName => (interfaceName :: link, nil))
              | SML ({link, ...}, SOME module) => (link, [CODE module])
              | _ => raise Bug.Bug "evalMain: LinkObjects"
          val objfiles =
              map (interfaceNameToObjFile fileMap) requires
          val exps =
              map (fn (_, filename) =>
                      if Filename.suffix filename = SOME LLVM.OBJEXT
                      then LoadBitcode filename
                      else LinkFile filename)
                  objfiles
        in
          LIST (modules @ map (evalMain env) exps)
        end
      | LinkFile filename =>
        LINKFILE filename
      | LoadBitcode filename =>
        let
          val filename = Filename.toString filename
        in
          let
            val context = LLVM.LLVMGetGlobalContext ()
            val buf = LLVM.LLVMCreateMemoryBufferWithContentsOfFile filename
            val module =
                LLVM.LLVMParseBitcodeInContext (context, buf)
                handle e => (LLVM.LLVMDisposeMemoryBuffer buf; raise e)
          in
            LLVM.LLVMDisposeMemoryBuffer buf;
            CODE module
          end
          handle LLVM.LLVMError msg => raise Error [filename ^ ": " ^ msg]
        end
      | Link (compileOptions,
              {systemBaseDir, noStdLib, useCXX, LDFLAGS, LIBS, dstfile},
              exps) =>
        let
          datatype arg = E of mainExp | R of mainResult
          fun eval nil = nil
            | eval (E exp :: args) =
              eval (R (evalMain env exp) :: args)
            | eval (R (LIST results) :: args) =
              eval (map R results @ args)
            | eval (R (LINKFILE filename) :: args) =
              (if CoreUtils.testExist filename
               then ()
               else raise Error ["required object file is not found: "
                                 ^ Filename.toString filename];
               filename :: eval args)
(*
            | eval ((x as R (CODE _)) :: E exp :: args) =
              eval (x :: R (evalMain env exp) :: args)
            | eval ((x as R (CODE _)) :: R (LIST results) :: args) =
              eval (x :: map R results @ args)
            | eval (R (CODE m1) :: R (CODE m2) :: args) =
              (LLVM.LLVMLinkModules (m1, m2, LLVM.LLVMLinkerDestroySource);
               eval (R (CODE m1) :: args))
*)
            | eval (R (CODE m) :: args) =
              let
                val dstfile = TempFile.create ("." ^ SMLSharp_Config.OBJEXT ())
              in
                #start Counter.llvmOutputTimeCounter();
                LLVM.compile compileOptions (m, LLVM.ObjectFile,
                                             Filename.toString dstfile);
                #stop Counter.llvmOutputTimeCounter();
                dstfile :: eval args
              end
            | eval _ = raise Bug.Bug "evalMain: Link"
          val objfiles = eval (map E exps)
          val runtimeDir = Filename.fromString "runtime"
          val runtimeDir = Filename.concatPath (systemBaseDir, runtimeDir)
          val libsmlsharp = Filename.fromString "libsmlsharp.a"
          val libsmlsharp = Filename.concatPath (runtimeDir, libsmlsharp)
          val smlsharpEntry = Filename.fromString "smlsharp_entry.o"
          val smlsharpEntry = Filename.concatPath (runtimeDir, smlsharpEntry)
          val libs =
              if noStdLib then LIBS else Filename.toString libsmlsharp :: LIBS
          val objects =
              if noStdLib then objfiles else smlsharpEntry :: objfiles
        in
          BinUtils.link {flags = LDFLAGS,
                         libs = libs,
                         objects = objects,
                         dst = dstfile,
                         useCXX = useCXX,
                         quiet = false};
          SUCCESS
        end
      | LLVMCompile (options, fileType, dstfile, exp) =>
        let
          val m = moduleOf (evalMain env exp)
        in
          (#start Counter.llvmOutputTimeCounter();
           LLVM.compile options (m, fileType,
                                 Filename.toString dstfile);
           #stop Counter.llvmOutputTimeCounter();
           SUCCESS)
        end
      | PrintHelp {progname, forDevelopers} =>
        (
          #start Counter.printHelpTimeCounter();
          print (usageMessage progname);
          if forDevelopers then print (extraOptionUsageMessage ()) else ();
          #stop Counter.printHelpTimeCounter();
          SUCCESS
        )
      | PrintVersion =>
        (
          printVersion ();
          SUCCESS
        )
      | PrintSHA1 filename =>
        let
          val f = Filename.BinIO.openIn filename
          val src = BinIO.inputAll f handle e => (BinIO.closeIn f; raise e)
          val _ = BinIO.closeIn f
          val hash = SHA1.toBase32 (SHA1.digest src)
        in
          TextIO.output (#printOut env,
                         hash ^ " " ^ Filename.toString filename ^ "\n");
          SUCCESS
        end
      | PrintHashes exp =>
        let
          val {interfaceNameOpt, link, ...} =
              case evalMain env exp of
                SML (depends, _) => depends
              | SMI depends => depends
              | _ => raise Bug.Bug "evalMain: PrintHashes"
          val interfaceNames = 
              rev (case interfaceNameOpt of SOME interfaceName => interfaceName :: link
                                          | NONE => link)
        in
          app (fn {hash, source = (_, path)} =>
                  TextIO.output (#printOut env,
                                 hash ^ " " ^ Filename.toString path ^ "\n"))
              interfaceNames;
          SUCCESS
        end
      | PrintDependCompile ({noStdPath, target, source}, exp) =>
        let
          val depfiles =
              case evalMain env exp of
                SML ({interfaceNameOpt, compile, ...}, _) =>
                (case interfaceNameOpt of
                   SOME interfaceName => #source interfaceName :: compile
                 | NONE => compile)
              | SMI {compile, ...} => compile
              | _ => raise Bug.Bug "evalMain: PrintDependCompile"
          val depfiles =
              if noStdPath
              then filterLOCALPATH depfiles
              else depfiles
          val depfiles = map (fn (_,x) => Filename.toString x) depfiles
        in
          printMakeRule (#printOut env) (target, source::depfiles);
          SUCCESS
        end
      | PrintDependLink ({noStdPath, target, source}, exp) =>
        let
          val {interfaceNameOpt, link, ...} =
              case evalMain env exp of
                SML (depends, _) => depends
              | SMI depends => depends
              | _ => raise Bug.Bug "evalMain: PrintDependLink"
          val depfiles =
              map
                (fn {source= x, ...} => x)
                (case interfaceNameOpt of
                   NONE => link
                 | SOME interfaceName => interfaceName::link)
          val depfiles =
              if noStdPath
              then filterLOCALPATH depfiles
              else depfiles
          val depfiles =
              map (fn (_,x) =>
                      Filename.toString
                        (Filename.replaceSuffix (SMLSharp_Config.OBJEXT ()) x))
                  depfiles
        in
          printMakeRule (#printOut env) (target, depfiles);
          SUCCESS
        end
      | Interactive (options, context) =>
        let
          val newContext =
              Top.loadInteractiveEnv
                {stopAt = Top.NoStop,
                 stdPath = [#systemBaseDir options],
                 loadPath = nil}
                context
                (Filename.concatPath
                   (#systemBaseDir options, Filename.fromString "prelude.smi"))
          val context =
              let
                val context = Top.extendContext (context, newContext)
                val context = Top.incVersion context
              in
                context
              end
          val _ = ReifiedTermData.init (#topEnv context)
                  handle e => raise e
        in
          RunLoop.interactive options context;
          SUCCESS
        end

  fun main (progname, args) =
      let
        val args = parseArgs args
        val mainExp = compileArgs (progname, args)
        val result = evalMain emptyEnv mainExp
      in
        case result of
          SUCCESS => ()
        | _ => raise Bug.Bug "main: result is not SUCCESS";
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
