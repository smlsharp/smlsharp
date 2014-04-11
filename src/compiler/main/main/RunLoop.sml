(**
 * interactive program execution
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure RunLoop : sig

  type options =
       {systemBaseDir : Filename.filename,
        stdPath : Filename.filename list,
        loadPath : Filename.filename list,
        LDFLAGS : string list,
        LIBS : string list,
        llvmOptions : LLVM.compile_options,
        errorOutput : TextIO.outstream}

  val interactive : options -> Top.toplevelContext -> unit
end =
struct

  type options =
       {systemBaseDir : Filename.filename,
        stdPath : Filename.filename list,
        loadPath : Filename.filename list,
        LDFLAGS : string list,
        LIBS : string list,
        llvmOptions : LLVM.compile_options,
        errorOutput : TextIO.outstream}

  fun userErrorToString e =
      Bug.prettyPrint (UserError.format_errorInfo e)

  val sml_register_stackmap =
      _import "sml_register_stackmap"
      : (unit ptr, unit ptr) -> ()

  datatype result =
      SUCCESS of Top.newContext
    | FAILED

  exception UncaughtException of exn
  exception CompileError
  exception DLError of string

  val loadedFiles = ref nil : Filename.filename list ref

  fun run ({stdPath, loadPath, LDFLAGS, LIBS, errorOutput, llvmOptions,
            ...}:options)
          context input =
      let
        fun puts s = TextIO.output (errorOutput, s ^ "\n")
        val options = {stopAt = Top.NoStop,
                       baseFilename = NONE,
                       stdPath = stdPath,
                       loadPath = loadPath}
        val ({interfaceNameOpt, ...}, result) =
             Top.compile options context input
             handle e =>
             (
               case e of
                 UserError.UserErrors errs =>
                 app (fn e => puts (userErrorToString e)) errs
               | UserError.UserErrorsWithoutLoc errs =>
                 app (fn (k,e) => puts (userErrorToString (Loc.noloc,k,e))) errs
               | Bug.Bug s => puts ("Compiler bug:" ^ s)
               | exn => raise exn;
               raise CompileError
            )
        val (newContext, module) =
            case result of
              Top.RETURN (newContext, module) => (newContext, module)
            | Top.STOPPED => raise Bug.Bug "run"
      in
        let
          val objfile = TempFile.create ("." ^ SMLSharp_Config.OBJEXT ())
          val asmfile = TempFile.create ("." ^ SMLSharp_Config.ASMEXT ())
          val _ = #start Counter.llvmOutputTimeCounter()
          val _ = LLVM.compile llvmOptions (module, LLVM.AssemblyFile,
                                            Filename.toString asmfile)
          val _ = LLVM.compile llvmOptions (module, LLVM.ObjectFile,
                                            Filename.toString objfile)
          val _ = #stop Counter.llvmOutputTimeCounter()
          val _ = LLVM.LLVMDisposeModule module
          val sofile = TempFile.create (SMLSharp_Config.DLLEXT ())
          val ldflags =
              case SMLSharp_Config.HOST_OS_TYPE () of
                SMLSharp_Config.Unix => nil
              | SMLSharp_Config.Cygwin =>
                ["-Wl,-out-implib,"
                 ^ Filename.toString (Filename.replaceSuffix "lib" sofile)]
              | SMLSharp_Config.Mingw =>
                ["-Wl,--out-implib="
                 ^ Filename.toString (Filename.replaceSuffix "lib" sofile)]
          val libfiles =
              case SMLSharp_Config.HOST_OS_TYPE () of
                SMLSharp_Config.Unix => nil
              | SMLSharp_Config.Cygwin =>
                map (fn x => Filename.toString (Filename.replaceSuffix "lib" x))
                    (!loadedFiles)
              | SMLSharp_Config.Mingw =>
                map (fn x => Filename.toString (Filename.replaceSuffix "lib" x))
                    (!loadedFiles)
          val _ = BinUtils.link
                    {flags = SMLSharp_Config.RUNLOOP_DLDFLAGS () :: LDFLAGS
                             @ ldflags,
                     libs = libfiles @ LIBS,
                     objects = [objfile],
                     dst = sofile,
                     useCXX = false,
                     quiet = not (!Control.printCommand)}
          val so = DynamicLink.dlopen' (Filename.toString sofile,
                                        DynamicLink.GLOBAL,
                                        DynamicLink.NOW)
                   handle OS.SysErr (msg, _) => raise DLError msg
          val {mainSymbol, stackMapSymbol, codeBeginSymbol, ...} =
              GenerateMain.moduleName (interfaceNameOpt, #version context)
          val smap = DynamicLink.dlsym' (so, stackMapSymbol)
                     handle OS.SysErr (msg, _) => raise DLError msg
          val base = DynamicLink.dlsym' (so, codeBeginSymbol)
                     handle OS.SysErr (msg, _) => raise DLError msg
          val _ = sml_register_stackmap (smap, base)
          val ptr = DynamicLink.dlsym (so, mainSymbol)
                    handle OS.SysErr (msg, _) => raise DLError msg
          (*
           * Note that "ptr" points to an ML toplevel code. This toplevel code
           * should be called by the calling convention for ML toplevels of
           * ML object files.  __attribute__((fastcc,no_callback)) is an ad
           * hoc way of yielding this convention code; no_callback avoids
           * calling sml_control_suspend.  If we change how to compile
           * attributes in the future, we should revisit here and update the
           * __attribute__ annotation.
           *)
          val mainFn =
              ptr : _import __attribute__((fastcc,no_callback)) () -> ()
        in
          loadedFiles := sofile :: !loadedFiles;
          mainFn () handle e => raise UncaughtException e;
          SUCCESS newContext
        end
        handle e =>
          (
            case e of
              UserError.UserErrors errs =>
              app (fn e => puts (userErrorToString e)) errs
            | UserError.UserErrorsWithoutLoc errs =>
              app (fn (k,e) => puts (userErrorToString (Loc.noloc,k,e))) errs
            | DLError s =>
              puts ("failed dynamic linking. Perhaps incorrect name in _import declaration: " ^ s)
            | UncaughtException exn =>
              puts ("uncaught exception " ^ exnMessage exn)
            | CoreUtils.Failed {command, message} =>
              (puts ("command failed: " ^ command); puts message)
            | _ => raise e;
            FAILED
          )
      end
      handle CompileError => FAILED

  fun initInteractive () =
      let
        val lineCount = ref 1
        val eof = ref false
        fun read (isFirst, _:int) =
            let
              val prompt = if isFirst then "# " else "> "
              val _ = TextIO.output (TextIO.stdOut, prompt)
              val _ = TextIO.flushOut TextIO.stdOut
              val line = TextIO.inputLine TextIO.stdIn
              val _ = lineCount := !lineCount + 1
            in
              case line of NONE => (eof := true; "") | SOME s => s
            end
      in
        {lineCount = lineCount, eof = eof, read = read}
      end

  fun interactiveInput {lineCount, eof : bool ref, read} =
      Parser.setup {sourceName = "(interactive)",
                    read = read,
                    mode = Parser.Interactive,
                    initialLineno = !lineCount}

  fun interactive options context =
      let
        val _ = Control.interactiveMode := true
        val _ =
            case SMLSharp_Config.HOST_OS_TYPE () of
              SMLSharp_Config.Unix => ()
            | SMLSharp_Config.Cygwin =>
              loadedFiles
                := [Filename.concatPath
                      (#systemBaseDir options,
                       Filename.fromString "compiler/smlsharp.lib")]
            | SMLSharp_Config.Mingw =>
              loadedFiles
                := [Filename.concatPath
                      (#systemBaseDir options,
                       Filename.fromString "compiler/smlsharp.lib")]
        val state = initInteractive ()
        fun loop context input =
            if !(#eof state) then ()
            else
              (Counter.reset();
               NameEvalEnv.intExnConList();
               case run options context input of
                 SUCCESS newContext =>
                 let
                   val context = Top.extendContext (context, newContext)
                   val context = Top.incVersion context
                 in
                   if !Control.doProfile
                   then (print "Time Profile:\n"; print (Counter.dump ()))
                   else ();
                   loop context input
                 end
               | FAILED =>
                 loop (Top.incVersion context) (interactiveInput state)
              )
      in
        loop context (interactiveInput state)
      end

end
