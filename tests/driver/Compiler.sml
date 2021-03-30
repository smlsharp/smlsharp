(**
 * compiler test driver
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author UENO Katsuhiro
 *)

structure Compiler =
struct

  structure I = InterfaceName

  exception Init of string
  exception CompileError of string * UserError.errorInfo list
  exception Failure of int
  exception CoreDumped
  exception Signaled of int
  exception UncaughtException of string * exn

  type srcfile = string
  type objfiles = {smifile : Filename.filename option,
                   objfile : Filename.filename} list
  type exefile = Filename.filename
  type error = UserError.errorInfo
  type compile_result =
      {objfiles : objfiles,
       errors : error list,
       dependency : InterfaceName.file_dependency option}

  val systemBaseDir = Filename.fromString "src"
  val dataDir = Filename.fromString "tests/data"
  val loadPath = [(Loc.STDPATH, systemBaseDir)]

  fun dataFile name =
      Filename.concatPath (dataDir, Filename.fromString name)

  fun checkDir dir =
      if CoreUtils.testDir dir
      then ()
      else raise Init (Filename.toString dir ^ " is not a directory.")

  fun toObjFile filename =
      Filename.replaceSuffix (Config.OBJEXT ()) filename

  fun init () =
      (
        checkDir systemBaseDir;
        checkDir dataDir;
        Main.loadConfig {systemBaseDir = systemBaseDir}
      )

  fun force (ref (SOME x), _) = x
    | force (r, f) = let val x = f () in r := SOME x; x end

  val r = ref NONE
  fun builtinContext () =
      force (r, fn () => Main.loadBuiltin {systemBaseDir = systemBaseDir})

  val r = ref NONE
  fun preludeContext () =
      force (r, fn () => #2 (Main.loadPrelude
                               {linkOptions = {systemBaseDir = systemBaseDir},
                                topContext = builtinContext,
                                require = nil,
                                topOptions = {loadPath = loadPath}}))

  fun options (loadMode, r : UserError.errorInfo list ref) =
      {llvmOptions =
         Main.makeLLVMOptions
           {systemBaseExecDir = systemBaseDir,
            triple = NONE,
            arch = "",
            cpu = "",
            features = "",
            optLevel = LLVMUtils.O0,
            relocModel = NONE,
            LLCFLAGS = nil,
            OPTFLAGS = nil} : LLVMUtils.compile_options,
       topOptions =
         {baseFilename = NONE,
          loadPath = loadPath,
          stopAt = Top.NoStop,
          loadMode = loadMode,
          outputWarnings = fn l => r := !r @ l,
          defaultInterface = fn x => x} : Top.options,
       linkOptions =
         {systemBaseDir = systemBaseDir,
          LDFLAGS = nil,
          LIBS = nil,
          noStdLib = false,
          useCXX = false,
          linkAll = false},
       topContext = builtinContext,
       fileMap = NONE}

  fun interactiveOptions
        {llvmOptions,
         topOptions = {loadPath, baseFilename, outputWarnings, ...},
         linkOptions = {LDFLAGS, LIBS, ...},
         ...} =
      {llvmOptions = llvmOptions,
       baseFilename = baseFilename,
       loadPath = loadPath,
       LDFLAGS = LDFLAGS,
       LIBS = LIBS,
       outputWarnings = outputWarnings} : Interactive.options

  fun userErrorToString x =
      SMLFormat.prettyPrint nil (UserError.format_errorInfo x)

  fun raiseCompileError nil = raise Fail "some error expected"
    | raiseCompileError errors =
      raise CompileError (String.concatWith "\n" (map userErrorToString errors),
                          errors)

  fun checkCompileError (x as {errors = nil, ...}) = x
    | checkCompileError {errors, ...} = raiseCompileError errors

  fun evalInput input =
      let
        val errors = ref nil
        val topOptions = options (I.COMPILE_AND_LINK, errors)
        val session = Interactive.start (interactiveOptions topOptions)
        datatype 'a try = R of 'a | E of exn
        fun loop context =
            if Parser.isEOF input then () else
            case R (Interactive.run session context input) handle e => E e of
              R newContext =>
              loop (Top.extendContext (context, newContext))
            | E (Interactive.UncaughtException e) =>
              (errors := !errors @ [(Loc.noloc, UserError.Error,
                                     UncaughtException (exnMessage e, e))];
               loop context)
            | E e => raise e
      in
        loop (preludeContext ())
        handle UserError.UserErrors l => errors := !errors @ l;
        {errors = !errors}
      end

  fun stringInput source src =
      let
        val buf = ref src
      in
        Parser.setup
          {source = source,
           read = fn _ => !buf before buf := "",
           initialLineno = 1}
      end

  fun fileInput source srcfile =
      let
        val io = Filename.TextIO.openIn srcfile
        val input = Parser.setup
                      {source = source,
                       read = fn (_,n) => TextIO.inputN (io, n),
                       initialLineno = 1}
      in
        (io, input)
      end

  fun eval' src =
      evalInput (stringInput (Loc.FILE (Loc.USERPATH, Filename.empty)) src)

  fun eval src =
      ignore (checkCompileError (eval' src))

  fun evalFile' srcfile =
      let
        val srcfile = dataFile srcfile
        val (io, input) = fileInput (Loc.FILE (Loc.USERPATH, srcfile)) srcfile
      in
        (evalInput input handle e => (TextIO.closeIn io; raise e))
        before TextIO.closeIn io
      end

  fun evalFile srcfile =
      ignore (checkCompileError (evalFile' srcfile))

  fun interactiveInput input =
      let
        val orig_interactiveMode = !Control.interactiveMode
        val orig_skipPrinter = !Control.skipPrinter
        val orig_printer = !ReifiedTerm.printTopEnvOutput
        fun reset () =
            (Control.interactiveMode := orig_interactiveMode;
             Control.skipPrinter := orig_skipPrinter;
             ReifiedTerm.printTopEnvOutput := orig_printer)
        val buf = ref nil
        fun printer s = buf := !buf @ [s]
      in
        Control.interactiveMode := true;
        Control.skipPrinter := false;
        ReifiedTerm.printTopEnvOutput := SOME printer;
        ({errors = #errors (evalInput input), prints = !buf}
         handle e => (reset (); raise e))
        before reset ()
      end

  fun interactive' src =
      interactiveInput (stringInput Loc.INTERACTIVE src)

  fun interactive src =
      {prints = #prints (checkCompileError (interactive' src))}

  fun interactiveFile' srcfile =
      let
        val srcfile = dataFile srcfile
        val (io, input) = fileInput Loc.INTERACTIVE srcfile
      in
        (interactiveInput input handle e => (TextIO.closeIn io; raise e))
        before TextIO.closeIn io
      end

  fun interactiveFile srcfile =
      {prints = #prints (checkCompileError (interactiveFile' srcfile))}

  fun compileFile srcfile =
      let
        val srcfile = dataFile srcfile
        val objfile = TempFile.create ("." ^ Config.OBJEXT ())
        val errors = ref nil
        val dependency =
            SOME (Main.compileSMLFile
                    (options (InterfaceName.COMPILE, errors))
                    {outputFileType = LLVMUtils.ObjectFile,
                     outputFilename = SOME objfile}
                    srcfile)
            handle UserError.UserErrors l => (errors := !errors @ l; NONE)
        val smifile =
            case dependency of
              NONE => NONE
            | SOME {root = {edges, ...}, ...} =>
              case edges of
                (I.PROVIDE, 
                 I.FILE {source = (_, file),
                         fileType = I.INTERFACE _, ...},
                loc) :: _ =>
                SOME file
              | _ => NONE
      in
        {objfiles = [{smifile = smifile, objfile = objfile}],
         dependency = dependency,
         errors = !errors} : compile_result
      end

  fun compile' srcfiles =
      let
        val results = map compileFile srcfiles
      in
        {objfiles = List.concat (map #objfiles results),
         dependency = map #dependency results,
         errors = List.concat (map #errors results)}
      end

  fun compile srcfiles =
      List.concat
        (map (fn x => #objfiles (checkCompileError (compileFile x))) srcfiles)

  fun link' "" [{smifile = NONE, objfile}] =
      let
        val dstfile = TempFile.create ".exe"
        val errors = ref nil
      in
        Main.link
          (options (I.LINK, errors))
          {sourceFiles = [objfile], outputFile = dstfile};
        {exefile = dstfile, errors = !errors, dependency = NONE}
        handle UserError.UserErrors l =>
               {exefile = dstfile, errors = !errors @ l, dependency = NONE}
      end
    | link' "" _ = raise Fail "link'"
    | link' srcfile objfiles =
      let
        val fileMap =
            UserFileMap.fromList
              (List.mapPartial
                 (fn {smifile = SOME smi, objfile} =>
                     SOME (toObjFile smi, objfile)
                   | {smifile = NONE, ...} => NONE)
                 objfiles)
        val srcfile = dataFile srcfile
        val fileMap = SOME (fn () => fileMap)
        val dstfile = TempFile.create ".exe"
        val errors = ref nil
        val (errors2, dependency) =
            (nil,
             case Main.link
                    (options (I.LINK, errors) # {fileMap = fileMap})
                    {sourceFiles = [srcfile],
                     outputFile = dstfile} of
               [dep] => SOME dep
             | _ => raise Fail "link: non-single dep for single smi file")
            handle UserError.UserErrors l => (l, NONE)
      in
        {exefile = dstfile, errors = !errors @ errors2, dependency = dependency}
      end

  fun link srcfile objfiles =
      #exefile (checkCompileError (link' srcfile objfiles))

(*
  fun execute exefile =
      CoreUtils.system {quiet = true, command = Filename.toString exefile}
*)

  val sml_test_exec =
      _import "sml_test_exec"
      : (string, string, int array) -> int

  exception Failure of int * string
  exception CoreDumped of string
  exception Signaled of int * string

  fun execute exefile =
      let
        val file = Filename.toString (TempFile.create ".out")
        val a = Array.array (2, 0)
        val r = sml_test_exec (Filename.toString exefile, file, a)
        val f = TextIO.openIn file
        val out = TextIO.inputAll f
        val _ = TextIO.closeIn f
        val m = Array.sub (a, 0)
        val n = Array.sub (a, 1)
      in
        if r < 0 then raise SMLSharp_Runtime.OS_SysErr () else
        case m of
          0 => if n = 0 then ()
               else raise Failure (n, "status=" ^ Int.toString n ^ "\n" ^ out)
        | 1 => raise Signaled (n, "signal=" ^ Int.toString n ^ "\n" ^ out)
        | 2 => raise CoreDumped out
        | _ => raise Fail ("unknown status : " ^ Int.fmt StringCvt.HEX n)
      end

end
