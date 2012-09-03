(**
 * interactive program execution
 *
 * @copyright (c) 2011, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure RunLoop : sig

  type options =
       {asmFlags : string list,
        systemBaseDir : Filename.filename,
        stdPath : Filename.filename list,
        loadPath : Filename.filename list,
        LDFLAGS : string list,
        LIBS : string list,
        errorOutput : TextIO.outstream}

  datatype result = SUCCESS | FAILED

  val available : unit -> bool
  val run : options
            -> Top.toplevelContext
            -> Parser.input
            -> result * Top.newContext
  val interactive : options -> Top.toplevelContext -> unit
end =
struct

  type options =
       {asmFlags : string list,
        systemBaseDir : Filename.filename,
        stdPath : Filename.filename list,
        loadPath : Filename.filename list,
        LDFLAGS : string list,
        LIBS : string list,
        errorOutput : TextIO.outstream}

  datatype result = SUCCESS | FAILED

  fun available () = true

  val dlopen =
      _import "dlopen"
      : __attribute__((no_callback)) (string, int) -> unit ptr
  val dlsym =
      _import "dlsym"
      : __attribute__((no_callback)) (unit ptr, string) -> unit ptr
  val dlerror =
      _import "dlerror"
      : __attribute__((no_callback)) () -> char ptr
  val str_new =
      _import "sml_str_new"
      : __attribute__((no_callback,alloc)) char ptr -> string

  exception UncaughtException of exn
  exception DlopenFail of string

(*
  fun checkDLError (result : unit ptr) =
      if result = _NULL
      then raise Control.Bug ("dlopen: " ^ str_new (dlerror ()))
      else ()
*)
  fun checkDLError (result : unit ptr) =
      if result = _NULL
      then raise DlopenFail (str_new (dlerror ()))
      else ()

  fun userErrorToString e =
      Control.prettyPrint (UserError.format_errorInfo e)

  val loadedFiles = ref nil : Filename.filename list ref

  exception CompileError of Top.newContext

  fun incVersionContext ({fixEnv, topEnv, version,builtinDecls}:Top.toplevelContext) =
      {fixEnv=fixEnv,
       topEnv=topEnv,
       version=IDCalc.incVersion version,
       builtinDecls=builtinDecls
      }
  fun run ({asmFlags, stdPath, loadPath, LDFLAGS, LIBS, errorOutput,
            ...}:options) context input =
      let
        fun puts s = TextIO.output (errorOutput, s ^ "\n")
        val options = {stopAt = Top.NoStop,
                       dstfile = NONE,
                       baseName = NONE,
                       stdPath = stdPath,
                       loadPath = loadPath,
                       asmFlags = asmFlags}


        val (_, result) =
            Top.compile options context input
            handle e =>
            (
             case e of
               UserError.UserErrors errs =>
               app (fn e => puts (userErrorToString e)) errs
             | UserError.UserErrorsWithoutLoc errs =>
               app (fn (k,e) => puts (userErrorToString (Loc.noloc,k,e))) errs
             | Control.Bug s => puts ("Compiler bug:" ^ s)
             | exn => puts "Compilation failed."
            ;
            raise CompileError Top.emptyNewContext
            )
        val (newContext, code) =
            case result of
              Top.RETURN (newContext, Top.FILE code) => (newContext, code)
            | Top.STOPPED => raise Control.Bug "run"
      in
        let
          val sofile = TempFile.create "so"
          val ldflags =
              case SMLSharp_Version.HostOS of
                SMLSharp_Version.Unix => nil
              | SMLSharp_Version.Windows =>
                ["-Wl,--out-implib="
                 ^ Filename.toString (Filename.replaceSuffix "lib" sofile)]
          val libfiles =
              case SMLSharp_Version.HostOS of
                SMLSharp_Version.Unix => nil
              | SMLSharp_Version.Windows =>
                map (fn x => Filename.toString (Filename.replaceSuffix "lib" x))
                    (!loadedFiles)
          val _ = BinUtils.link
                    {flags = SMLSharp_Config.RUNLOOP_DLDFLAGS () :: LDFLAGS
                             @ ldflags,
                     libs = libfiles @ LIBS,
                     objects = [code],
                     dst = sofile,
                     quiet = not (!Control.printCommand)}
                    
          val RTLD_GLOBAL = SMLSharpRuntime.cconstInt "RTLD_GLOBAL"
          val RTLD_NOW = SMLSharpRuntime.cconstInt "RTLD_NOW"
          val lib = dlopen (Filename.toString sofile, RTLD_GLOBAL + RTLD_NOW)
          val _ = checkDLError lib
          val ptr = dlsym (lib, "SMLmain")
          val _ = checkDLError ptr
          val mainFn = ptr : _import () -> ()
        in
          loadedFiles := sofile :: !loadedFiles;
          mainFn () handle e => raise UncaughtException e;
          (SUCCESS, newContext)
        end
        handle e =>
          (
            case e of
              UserError.UserErrors errs =>
              app (fn e => puts (userErrorToString e)) errs
            | UserError.UserErrorsWithoutLoc errs =>
              app (fn (k,e) => puts (userErrorToString (Loc.noloc,k,e))) errs
            | DlopenFail s =>
              puts ("Dlopen fail. Perhaps incorrect name in _import declaration: " ^ s)
            | UncaughtException exn =>
              (case exn of 
                 SMLSharp_SQL_Prim.Type s =>
                 puts ("SQL typecheck error: " ^ s)
               | SMLSharp_SQL_Prim.Exec s =>
                 puts ("SQL execution error: " ^ s)
               | SMLSharp_SQL_Prim.Connect s =>
                 puts ("SQL connection error: " ^ s)
               | SMLSharp_SQL_Prim.Link s =>
                 puts ("SQL linking error: " ^ s)
               | SMLSharp_SQL_Prim.Format =>
                 puts ("Unsupported SQL values.")
               | SMLSharpRuntime.SysErr (s, syserrorOption) =>
                 puts ("OS primitive error: " ^ s)
               | IO.Io{name, function, cause} => 
                 let
                   val prefix = "IO primitive failed: " ^ function ^ " on " ^ name ^ "."
                   val suffix =
                       (case cause of
                          IO.BlockingNotSupported => " Blocking not supported."
                        | IO.NonblockingNotSupported => " Nonblocking not supported."
                        | IO.RandomAccessNotSupported => " Random access not supported."
                        | IO.ClosedStream =>" Closed stream."
                        | _ => ""
                       )
                 in
                   puts (prefix ^ suffix)
                 end
               | Fail s =>
                 puts ("Runtime system error: " ^ s)
               | e =>
                 puts ("uncaught exception: " ^ exnMessage e)
              )
            | CoreUtils.Failed {command, message} =>
              (puts ("command failed: " ^ command); puts message)
            | _ => raise e;
            (FAILED, newContext)
          )
      end
      handle CompileError context => (FAILED, context)

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
            case SMLSharp_Version.HostOS of
              SMLSharp_Version.Unix => ()
            | SMLSharp_Version.Windows =>
              loadedFiles
                := [Filename.concatPath
                      (#systemBaseDir options,
                       Filename.fromString "compiler/smlsharp.lib")]
        val state = initInteractive ()
        fun loop context input =
            if !(#eof state) then ()
            else
              case run options context input of
                (SUCCESS, newContext) =>
                let
                  val context = Top.extendContext (context, newContext)
                  val context = incVersionContext context
                in
                  loop context input
                end
              | (FAILED, newContext) =>
                loop (incVersionContext context) (interactiveInput state)
      in
        loop context (interactiveInput state)
      end

end
