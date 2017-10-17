(**
 * compiler test driver
 *
 * @copyright (c) 2017, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure Compiler =
struct

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

  val systemBaseDir = Filename.fromString "./src"
  val dataDir = Filename.fromString "./tests/data"

  fun dataFile name =
      Filename.concatPath (dataDir, Filename.fromString name)

  fun checkDir dir =
      if CoreUtils.testDir dir
      then ()
      else raise Init (Filename.toString dir ^ " is not a directory.")

  fun init () =
      (
        checkDir systemBaseDir;
        checkDir dataDir;
        Main.loadConfig {systemBaseDir = SOME systemBaseDir}
      )

  fun force (ref (SOME x), _) = x
    | force (r, f) = let val x = f () in r := SOME x; x end

  val r = ref NONE
  fun builtinContext () =
      force (r, fn () => Main.loadBuiltin {systemBaseDir = systemBaseDir})

  val r = ref NONE
  fun preludeContext () =
      force (r, fn () => #2 (Main.loadPrelude
                               {systemBaseDir = systemBaseDir,
                                topContext = builtinContext,
                                require = nil,
                                topOptions = {loadPath = nil,
                                              stdPath = [systemBaseDir]}}))

  fun options (r : UserError.errorInfo list ref) =
      {llvmOptions =
         Main.makeLLVMOptions
           {systemBaseDir = SOME systemBaseDir,
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
          stdPath = [systemBaseDir],
          loadPath = nil,
          stopAt = Top.NoStop,
          loadMode = Top.COMPILE_AND_LINK,
          outputWarnings = fn l => r := !r @ l} : Top.options,
       linkOptions =
         {LDFLAGS = nil : string list,
          LIBS = nil : string list,
          noStdLib = false,
          useCXX = false,
          linkAll = false},
       topContext = builtinContext,
       fileMap = NONE}

  fun interactiveOptions
        {llvmOptions,
         topOptions = {stdPath, loadPath, baseFilename, outputWarnings, ...},
         linkOptions = {LDFLAGS, LIBS, ...},
         ...} =
      {llvmOptions = llvmOptions,
       baseFilename = baseFilename,
       stdPath = stdPath,
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
        val session = Interactive.start (interactiveOptions (options errors))
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

  fun stringInput mode src =
      let
        val buf = ref src
      in
        Parser.setup
          {mode = mode,
           read = fn _ => !buf before buf := "",
           sourceName = "(eval)",
           initialLineno = 1}
      end

  fun fileInput mode srcfile =
      let
        val srcfile = dataFile srcfile
        val io = Filename.TextIO.openIn srcfile
        val input = Parser.setup
                      {mode = mode,
                       read = fn (_,n) => TextIO.inputN (io, n),
                       sourceName = Filename.toString srcfile,
                       initialLineno = 1}
      in
        (io, input)
      end

  fun eval' src =
      evalInput (stringInput Parser.File src)

  fun eval src =
      ignore (checkCompileError (eval' src))

  fun evalFile' srcfile =
      let
        val (io, input) = fileInput Parser.File srcfile
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
        ReifiedTerm.printTopEnvOutput := printer;
        ({errors = #errors (evalInput input), prints = !buf}
         handle e => (reset (); raise e))
        before reset ()
      end

  fun interactive' src =
      interactiveInput (stringInput Parser.Batch src)

  fun interactive src =
      {prints = #prints (checkCompileError (interactive' src))}

  fun interactiveFile' srcfile =
      let
        val (io, input) = fileInput Parser.Batch srcfile
      in
        (interactiveInput input handle e => (TextIO.closeIn io; raise e))
        before TextIO.closeIn io
      end

  fun interactiveFile srcfile =
      {prints = #prints (checkCompileError (interactiveFile' srcfile))}

  fun compileFile srcfile =
      let
        val srcfile = dataFile srcfile
        val objfile = TempFile.create ("." ^ SMLSharp_Config.OBJEXT ())
        val errors = ref nil
        val interfaceNameOpt =
            #interfaceNameOpt
              (Main.compileSMLFile
                 (options errors)
                 {outputFileType = LLVMUtils.ObjectFile,
                  outputFilename = objfile}
                 srcfile)
            handle UserError.UserErrors l => (errors := !errors @ l; NONE)
        val smifile =
            case interfaceNameOpt of
              SOME {source = (_, file), ...} => SOME file
            | NONE => NONE
      in
        {objfiles = [{smifile = smifile, objfile = objfile}], errors = !errors}
      end

  fun compile' srcfiles =
      let
        val results = map compileFile srcfiles
      in
        {objfiles = List.concat (map #objfiles results),
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
          (options errors)
          {sourceFiles = [objfile], outputFile = dstfile}
        handle UserError.UserErrors l => errors := !errors @ l;
        {exefile = dstfile, errors = !errors}
      end
    | link' "" _ = raise Fail "link'"
    | link' srcfile objfiles =
      let
        val fileMap =
            FilenameMap.fromList
              (List.mapPartial
                 (fn {smifile = SOME smi, objfile} => SOME (smi, objfile)
                   | {smifile = NONE, ...} => NONE)
                 objfiles)
        val srcfile = dataFile srcfile
        val fileMap = SOME (fn () => fileMap)
        val dstfile = TempFile.create ".exe"
        val errors = ref nil
      in
        Main.link
          (options errors # {fileMap = fileMap})
          {sourceFiles = [srcfile],
           outputFile = dstfile}
        handle UserError.UserErrors l => errors := !errors @ l;
        {exefile = dstfile, errors = !errors}
      end

  fun link srcfile objfiles =
      #exefile (checkCompileError (link' srcfile objfiles))

(*
  fun execute exefile =
      CoreUtils.system {quiet = true, command = Filename.toString exefile}
*)

  val sml_test_exec = _import "sml_test_exec" : (string, int array) -> int

  exception Failure of int
  exception CoreDumped
  exception Signaled of int

  fun execute exefile =
      let
        val a = Array.array (2, 0)
        val r = sml_test_exec (Filename.toString exefile, a)
        val m = Array.sub (a, 0)
        val n = Array.sub (a, 1)
      in
        if r < 0 then raise SMLSharp_Runtime.OS_SysErr () else
        case m of
          0 => if n = 0 then () else raise Failure n
        | 1 => raise Signaled n
        | 2 => raise CoreDumped
        | _ => raise Fail ("unknown status : " ^ Int.fmt StringCvt.HEX n)
      end

end
