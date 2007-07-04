(**
 * run the interactive session with runtime
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.57 2007/06/01 09:40:59 kiyoshiy Exp $
 *)
structure Main :
          sig
            val loadPrelude : bool ref
            val printPrelude : bool ref
            val tracePrelude : bool ref
            val useBasis : bool ref
            val compileOnly : bool ref
            val main : string * string list -> OS.Process.status
          end =
struct

  (***************************************************************************)

  structure BV = Word8Vector
  structure BA = Word8Array
  structure C = Control
  structure CT = Counter
  structure G = GetOpt
  structure PU = PathUtility
  structure TE = TopLevelError

  (***************************************************************************)

  datatype runMode =
           CompileAndExecuteMode
         | CompileOnlyMode
         | MakeCompiledLibraryMode

  datatype prelude = Source of string | Compiled of string

  (**
   * command line options user can specify.
   *)                                                  
  datatype parameterOption =
           CompileOnly
         | CompiledPrelude of string
         | Control of string * C.switch * string
         | Expression of string
         | Help
         | HelpEx
         | LibraryDirectory of string
         | MakeCompiledLibrary
         | NoBasis
         | NoWarning
         | NoPrintBinds
         | ObjectFile of string
         | OutputFile of string
         | PreludeFile of string
         | Runtime of string
         | Quiet
         | ShowVersion
         | ShowControl
         | StdIn

  (**
   * command line options are stored in this record.
   *)
  type parameters =
       {
         extraArgs : string list ref,
         libPaths : string list ref,
         mode : runMode ref,
         outputFileName : string ref,
         objectFileNames : string list ref,
         preludeFileName : prelude ref,
         printBinds : bool ref,
         printWarning : bool ref,
         sources : (unit -> Top.source) list ref
       }

  (***************************************************************************)

  (** raised if the compiler should quit instantly because some command option,
   * such as "help" or "version", is specified. *)
  exception Quit

  (** raised if user specifies invalid command line option. *)
  exception InvalidOption of string

  (***************************************************************************)

  (* Do not edit these constants.
   * You can set these switch on prompt.
   * - Main.printPrelude := true;
   * - Main.tracePrelude := true;
   *)
  val loadPrelude = ref true
  val printPrelude = ref false
  val tracePrelude = C.tracePrelude
  val useBasis = ref false
  val compileOnly = ref false

  val _ = C.printBinds := true
  val _ = C.switchTrace := false

  (* use the standard preludes. *)
  val minimumPreludeFileName = Configuration.MinimumPreludeFileName
  val PreludeFileName = Configuration.PreludeFileName
  val CompiledPreludeFileName = Configuration.CompiledPreludeFileName
  val DefaultPreludeFile =
      Compiled CompiledPreludeFileName
(*
      Source (if !useBasis then BasisFileName else minimumPreludeFileName)
*)

  val DefaultObjectFileName = "a.sme"
  val InstallLibDirectory = Configuration.LibDirectory
  val LibPathEnvVarName = "SMLSHARP_LIB_PATH"
  val ProductName = "SML#"
  val Version = Configuration.Version
  val VersionInfoMessage = ProductName ^ " " ^ Version
                           ^ " (" ^ Configuration.ReleaseDate ^ ")"

  (********************)

  val CT.CounterSet MainCounterSet =
      #addSet CT.root ("Main", CT.ORDER_OF_ADDITION)
  val CT.ElapsedTimeCounter restoreStaticEnvTimeCounter =
      #addElapsedTime MainCounterSet "restore static ENV"
  val CT.ElapsedTimeCounter restoreDynamicEnvTimeCounter =
      #addElapsedTime MainCounterSet "restore dynamic ENV"
  val CT.ElapsedTimeCounter initializationCounter =
      #addElapsedTime MainCounterSet "initialization"

  (********************)
  (* functions to manipulate control option *)

  fun getOptOfControlOption (name, switch) =
      let
        val desc =
            case switch of
              C.IntSwitch _ =>
              G.ReqArg (fn value => Control(name, switch, value), "NUM")
            | C.BoolSwitch _ => 
              G.ReqArg (fn value => Control(name, switch, value), "yes/no")
            | C.StringSwitch _ =>
              (* TEXT option can be an empty string. *)
              G.OptArg
                  (fn valueOpt =>
                      Control
                          (name, switch, Option.getOpt(valueOpt, "")), "TEXT")
      in
        {
          short = "",
          long = ["x" ^ name],
          desc = desc,
          help = "control option."
        }
      end

  fun printControlOptions () =
      SEnv.appi
          (fn (name, switch) =>
              app print [name, " = [", C.switchToString switch, "]\n"])
          C.switchTable

  (********************)

  val optionDescsStandard =
      [
        {
          short = "c",
          long = [],
          desc = G.NoArg CompileOnly,
          help = "Compile but not execute."
        },
        {
          short = "",
          long = ["compiled-prelude"],
          desc = G.ReqArg (CompiledPrelude, "FILE"),
          help = "Preludes a compiled file."
        },
        {
          short = "e",
          long = ["expression"],
          desc = G.ReqArg (Expression, "EXPRESSION"),
          help = "Specify inline expression."
        },
        {
          short = "h",
          long = ["help"],
          desc = G.NoArg Help,
          help = "Display command line options"
        },
        {
          short = "X",
          long = [],
          desc = G.NoArg HelpEx,
          help = "Display non-standard options"
        },
        {
          short = "I",
          long = ["load-path"],
          desc = G.ReqArg (LibraryDirectory, "DIR"),
          help = "Prepend DIR to the load path list."
        },
        {
          short = "",
          long = ["make-compiled-prelude"],
          desc = G.NoArg MakeCompiledLibrary,
          help = "Generate a library file."
        },
        {
          short = "",
          long = ["nobasis"],
          desc = G.NoArg NoBasis,
          help = "shorthand of --prelude=" ^ minimumPreludeFileName
        },
        {
          short = "",
          long = ["nowarn"],
          desc = G.NoArg NoWarning,
          help = "Suppress warning message."
        },
        {
          short = "",
          long = ["no-printbind"],
          desc = G.NoArg NoPrintBinds,
          help = "Suppress printing generated binds."
        },
        {
          short = "o",
          long = ["output"],
          desc = G.ReqArg (OutputFile, "FILE"),
          help = "Place the output into FILE."
        },
        {
          short = "l",
          long = ["library"],
          desc = G.ReqArg (ObjectFile, "FILE"),
          help = "Load object code from FILE."
        },
        {
          short = "",
          long = ["prelude"],
          desc = G.ReqArg (PreludeFile, "FILE"),
          help = "Change prelude."
        },
        {
          short = "q",
          long = ["quiet"],
          desc = G.NoArg Quiet,
          help = "shorthand of --nowarn --no-printbind"
        },
        {
          short = "",
          long = ["stdin"],
          desc = G.NoArg StdIn,
          help = "Read source code from standard input."
        },
        {
          short = "v",
          long = ["version"],
          desc = G.NoArg ShowVersion,
          help = "Print version number and exit."
        },
        {
          short = "",
          long = ["showX"],
          desc = G.NoArg ShowControl,
          help = "Print values of non-standard options."
        }
      ]
  val optionDescsExtra =
      map getOptOfControlOption (SEnv.listItemsi C.switchTable)
  val optionDescs = optionDescsStandard @ optionDescsExtra
  val usageHeader = "Usage : smlsharp [OPTION ...] [file] [arguments ...]"
  val usage =
      G.usageInfo {header = usageHeader, options = optionDescsStandard} ^ "\n"
  val usageExtra =
      G.usageInfo {header = usageHeader, options = optionDescsExtra} ^ "\n"

  val STDINChannel = TextIOChannel.openIn {inStream = TextIO.stdIn}
  val STDOUTChannel = TextIOChannel.openOut {outStream = TextIO.stdOut}
  val STDERRChannel = TextIOChannel.openOut {outStream = TextIO.stdErr}

  (** an utility. ensure finalizer is executed *)
  fun finally arg userFunction finalizer =
      ((userFunction arg) before (finalizer arg))
      handle e => (finalizer arg; raise e)

  fun trace message = 
      if !C.switchTrace andalso !C.traceFileLoad
      then
        (TextIO.output (TextIO.stdErr, message); TextIO.flushOut TextIO.stdErr)
      else ()

  local
    val SHARP = Word8.fromInt(Char.ord #"#")
    val BANG = Word8.fromInt(Char.ord #"!")
    val NL = Word8.fromInt(Char.ord #"\n")
    exception Found of int
  in
  (** if vector begins with a shebang line, returns the index of next to the
   * end-of-line of shebang line. *)
  fun skipShebang vector =
      if
        2 < BV.length vector
        andalso SHARP = BV.sub (vector, 0)
        andalso BANG = BV.sub (vector, 1)
      then
        (BV.foldli
             (fn (index, byte, len) =>
                 if NL = byte then raise Found index else len)
             (BV.length vector)
             (vector, 2, NONE))
        handle Found index => (index + 1)
      else 0
  end

  fun getEnv "PWD" = SOME(OS.FileSys.getDir ())
    | getEnv "SMLSHARP_OS" = SOME(Platform.OSName)
    | getEnv "SMLSHARP_ARCH" = SOME(Platform.ArchName)
    | getEnv name = OS.Process.getEnv name

  fun getSourceOfStdIn interactionMode () =
      {
        interactionMode = interactionMode,
        initialSource = STDINChannel,
        initialSourceName = "stdIn",
        getBaseDirectory = OS.FileSys.getDir
      } : Top.source

  fun getSourceOfInlineExpression expression () = 
      {
        interactionMode = Top.NonInteractive {stopOnError = true},
        initialSource =
        TextIOChannel.openIn {inStream = TextIO.openString expression},
        initialSourceName = "argument",
        getBaseDirectory = OS.FileSys.getDir
      } : Top.source

  fun getSourceOfFile getVariable loadPathList sourceFileName =
      let
        val absoluteFilePath = 
            PathResolver.resolve
                getVariable loadPathList "." sourceFileName
            handle TE.InvalidPath message =>
                   raise InvalidOption message
        val _ = trace ("source: " ^ absoluteFilePath ^ "\n")
        val sourceDir = #dir(PU.splitDirFile absoluteFilePath)
        val fileChannel = FileChannel.openIn {fileName = absoluteFilePath}

        (* This buffering makes unpickling prelude fast slightly. *)
        val contents = ChannelUtility.getAll fileChannel
        val _ = #close fileChannel ()
        val start = if !C.skipShebang then skipShebang contents else 0
        val sourceChannel =
            ByteVectorChannel.openSliceIn
                {buffer = contents, start = start, lenOpt = NONE}
(*
        val sourceChannel = fileChannel
*)

        fun getSource () =
            {
              interactionMode = Top.NonInteractive {stopOnError = true},
              initialSource = sourceChannel,
              initialSourceName = sourceFileName,
              getBaseDirectory = fn () => sourceDir
            } : Top.source
      in
        getSource
      end

  (**
   * If any input source is specified, the compiler runs in filter mode.
   * Otherwise, it runs in interactive mode.
   * <dl>
   *   <dt>filter mode</dt>
   *   <dd>no prompt. no binding printed.</dd>
   *   <dt>interactive mode</dt>
   *   <dd>prompt. binding is printed.</dd>
   *   <dd></dd>
   * </dl>
   *)
  fun parseArguments (parameters : parameters) arguments =
      let
        val (options, otherArguments) =
            G.getOpt
                {
                  argOrder = G.Permute,
                  options = optionDescs,
                  errFn = fn message => raise InvalidOption message
                }
                arguments

        fun processOpt CompileOnly = #mode parameters := CompileOnlyMode
          | processOpt (CompiledPrelude fileName) =
            (#preludeFileName parameters) := Compiled fileName
          | processOpt (Control arg) =
            C.interpretControlOption arg
          | processOpt (Expression expression) =
            (#sources parameters)
            := (!(#sources parameters)
                @ [getSourceOfInlineExpression expression])
          | processOpt Help = (print usage; raise Quit)
          | processOpt HelpEx = (print usageExtra; raise Quit)
          | processOpt (LibraryDirectory directory) =
            (* prepend to the list. libPaths is reversed later. *)
            (#libPaths parameters) := directory :: !(#libPaths parameters)
          | processOpt MakeCompiledLibrary =
            #mode parameters := MakeCompiledLibraryMode
          | processOpt NoBasis = 
            (#preludeFileName parameters) := Source minimumPreludeFileName
          | processOpt NoWarning = (#printWarning parameters) := false
          | processOpt NoPrintBinds = (#printBinds parameters) := false
          | processOpt (OutputFile fileName) =
            (#outputFileName parameters) := fileName
          | processOpt (ObjectFile fileName) =
            (#objectFileNames parameters) :=
            (!(#objectFileNames parameters)) @ [fileName]
          | processOpt (PreludeFile fileName) =
            (#preludeFileName parameters) := Source fileName
          | processOpt Quiet =
            (
              #printWarning parameters := false;
              #printBinds parameters := false
            )
          | processOpt StdIn =
            (#sources parameters)
            := !(#sources parameters)
               @ [getSourceOfStdIn (Top.NonInteractive {stopOnError = true})]
          | processOpt ShowVersion =
            (print (VersionInfoMessage ^ "\n"); raise Quit)
          | processOpt ShowControl =
            (printControlOptions (); raise Quit)

        val _ = app processOpt options

        (* "-" is special argument specifying STDIN. *)
        fun getSourceOfName "-" =
            getSourceOfStdIn (Top.NonInteractive {stopOnError = true})
          | getSourceOfName fileName =
            (* Do not deref libPaths before all parameters are processed. *)
            fn () =>
               getSourceOfFile getEnv (!(#libPaths parameters)) fileName ()

      in
        (* Binding information is printed only if
         *   (1) the program is cmpiled and executed.
         *   (2) and, the program is read from STDIN.
         *   (3) and, neither --quiet nor --no-printbind option is specified.
         *)
        (* ToDo : write clean code to judge whether binding information should
         * be printed or not. *)

        case !(#mode parameters) of
          CompileAndExecuteMode => ()
        | _ => #printBinds parameters := false;

        case !(#sources parameters) of
          [] =>
          (case otherArguments of
             [] => (* interactive mode *)
             #sources parameters := [getSourceOfStdIn Top.Interactive]
           | fileName :: others => (* filter mode *) 
             (
               #printBinds parameters := false;
               #sources parameters := [getSourceOfName fileName];
               #extraArgs parameters := others
             ))
        | _ => (* filter mode *) 
          (
            #printBinds parameters := false;
            #extraArgs parameters := otherArguments
          )
      end

  (********************)

  fun createLibrary outputChannel context executableChannel =
      let
        val _ = trace "saving static environment..."
        fun writer byte = #send outputChannel byte
        (* pickled static environment is at the head of library file. *)
        val _ = Top.pickle context (Pickle.makeOutstream writer)
        val _ = trace "done\n"

        val _ = trace "saving dynamic environment..."
        (* copy executables into the library file. *)
        val _ = ChannelUtility.copy (executableChannel, outputChannel)
        val _ = trace "done\n"
      in
        ()
      end

  fun resume (parameter : Top.contextParameter) (preludeSource : Top.source) =
      let
        val channel = #initialSource preludeSource

        fun reader () =
            case #receive channel () of
              SOME byte => byte
            | NONE => raise Fail "unexpected EOF of library"
        val _ = trace "restoring static environment..."
        val _ = #start restoreStaticEnvTimeCounter ()
        val context =
            Top.unpickle parameter (Pickle.makeInstream reader)
            handle exn =>
                   raise Fail ("malformed compiled code:" ^ exnMessage exn)
        val _ = #stop restoreStaticEnvTimeCounter ()
        val _ = trace "done\n"

        val session = #session parameter
        fun execute () =
            case StandAloneSession.loadExecutable channel of
              SOME executable => (#execute session executable; execute ())
            | NONE => ()
        val _ = trace "restoring dynamic environment..."
        val _ = #start restoreDynamicEnvTimeCounter ()
        val _ = execute ()
        val _ = #stop restoreDynamicEnvTimeCounter ()
        val _ = trace "done\n"

      in
        context
      end

  fun start (parameter : Top.contextParameter) (preludeSource : Top.source) =
      let
        val context = Top.initialize parameter
        val preludeSource =
            {
              interactionMode = Top.Prelude,
              initialSource = #initialSource preludeSource,
              initialSourceName = #initialSourceName preludeSource,
              getBaseDirectory = #getBaseDirectory preludeSource
            }
      in
        if Top.run context preludeSource
        then context
        else raise Fail "prelude cannot compile."
      end

  (********************)

  fun getInteractiveSession (parameters : parameters) =
      let
        val sessionParameter = 
            {
              terminalInputChannel = STDINChannel,
              terminalOutputChannel = STDOUTChannel,
              terminalErrorChannel = STDERRChannel,
              arguments = !(#extraArgs parameters)
            }
        val session = InteractiveSessionFactory.openSession sessionParameter
      in
        (session, fn _ => ())
      end

  fun getBatchSession (parameters : parameters) =
      let
        (* generated executables are bufferred into this bufferOptRef. *)
        val bufferOptRef = ref (NONE : BA.array option)
        val outputChannel = ByteArrayChannel.openOut {buffer = bufferOptRef}

        val session =
            StandAloneSession.openSession {outputChannel = outputChannel}

        (*
         * cleanUp function is called after session finishes.
         * Its argument is a context option.
         * SOME indicates that session finishes successfully.
         * NONE indicates that session abors for any error.
         *)
        fun cleanUp (SOME _) = 
            let
              val _ = #close outputChannel ()
              val outputFileName = !(#outputFileName parameters)
              val outputFileChannel =
                  FileChannel.openOut {fileName = outputFileName}

              val _ = FileSysUtil.setFileModeExecutable outputFileName

              val _ = (* inserts header *)
                  #print
                      (CharacterStreamWrapper.wrapOut outputFileChannel)
                      (!C.headerOfExecutable)
              val _ = #sendArray outputFileChannel (valOf(!bufferOptRef))
              val _ = #close outputFileChannel ()
            in
              ()
            end
          | cleanUp NONE = ()
            
      in
        (session, cleanUp)
      end

  fun getMakeCompiledLibrarySession (parameters : parameters) =
      let
        (* generated executables are bufferred into this bufferOptRef. *)
        val bufferOptRef = ref (NONE : BA.array option)
        val outputChannel = ByteArrayChannel.openOut {buffer = bufferOptRef}

        val session =
            StandAloneSession.openSession {outputChannel = outputChannel}

        (* On closing, creates a library file from the context and the
         * executables. *)
        fun cleanUp contextOpt =
            let
              val () = #close outputChannel ()
            in
              case contextOpt of
                SOME context =>
                let
                  val outputFileName = !(#outputFileName parameters)
                  val libraryChannel =
                      FileChannel.openOut {fileName = outputFileName}
                  val executableChannel =
                      ByteArrayChannel.openIn {buffer = valOf(!bufferOptRef)}
                  val () =
                      createLibrary libraryChannel context executableChannel
                  val () = #close libraryChannel ()
                in
                  ()
                end
              | NONE => ()
            end
      in
        (session, cleanUp)
      end

  (********************)

  fun main (commandName, arguments) =
      let

        val _ = #reset MainCounterSet ()

        val libPaths =
            case OS.Process.getEnv LibPathEnvVarName of
              NONE => []
            | SOME libPath =>
              String.tokens (fn ch => ch = FileSysUtil.PathSeparator) libPath

        val _ = C.setControlOptions "IML_" OS.Process.getEnv

        (* default parameter *)
        val parameters =
            {
              extraArgs = ref [],
              libPaths = ref [],
              mode =
              ref
                  (if !compileOnly
                   then CompileOnlyMode
                   else CompileAndExecuteMode),
              outputFileName = ref DefaultObjectFileName,
              objectFileNames = ref [],
              preludeFileName = ref DefaultPreludeFile,
              printBinds = C.printBinds,
              printWarning = C.printWarning,
              sources = ref []
            } : parameters

        (* update parameter to user specified *)                
        val _ = parseArguments parameters arguments

        (* reverse directories specified by -I options here, because they are
         * examined from left to right. *)
        val _ = #libPaths parameters :=
                (rev (!(#libPaths parameters))
                 @ libPaths
                 @ [InstallLibDirectory, "."])
        val _ =
            app
                (fn libPath => trace ("libpath: " ^ libPath ^ "\n"))
                (!(#libPaths parameters))

        val (session, cleanUp) =
            case !(#mode parameters) of
              CompileAndExecuteMode => getInteractiveSession parameters
            | CompileOnlyMode => getBatchSession parameters
            | MakeCompiledLibraryMode =>
              getMakeCompiledLibrarySession parameters

        val topParameter = 
            {
              session = session,
              standardOutput = STDOUTChannel,
              standardError = STDERRChannel,
              loadPathList = !(#libPaths parameters),
              getVariable = getEnv
            }

        val currentSwitchTrace = !C.switchTrace
        val currentPrintBinds = !C.printBinds

      in
        if !C.printBinds
        then (print VersionInfoMessage; print "\n")
        else ();

        #start initializationCounter ();

        C.switchTrace := !tracePrelude;
        C.printBinds := !printPrelude;
        let
          fun getSource fileName =
              getSourceOfFile getEnv (!(#libPaths parameters)) fileName

          val context = 
              if !loadPrelude
              then
                let
                  val (fileName, contextCreator) =
                      case !(#preludeFileName parameters) of
                        Source preludeFileName => (preludeFileName, start)
                      | Compiled preludeFileName => (preludeFileName, resume)
                in
                  finally
                      (getSource fileName ())
                      (contextCreator topParameter)
                      (fn source => #close (#initialSource source) ())
                end
              else Top.initialize topParameter
        in
          if
            List.all
                (fn fileName => Top.runObject context (getSource fileName ()))
                (!(#objectFileNames parameters))
          then ()
          else raise Fail "loading object file fails.";

          #stop initializationCounter ();

          if !C.doProfile
          then (print "\n"; print (Counter.dump ()))
          else ();

          C.switchTrace := currentSwitchTrace;
          C.printBinds := currentPrintBinds;

          if
            List.all (* stop if any compilation fails. *)
              (fn getSource => Top.run context (getSource ()))
              (!(#sources parameters))
          then ()
          else raise Fail "Compilation fails.";

          #close session ();
          cleanUp (SOME context);
          OS.Process.success
        end
          handle exn =>
                 (#close session (); cleanUp NONE; raise exn)
      end
        handle Quit => OS.Process.success
             | SessionTypes.Exit exitCode =>
               (*
                * NOTE: The type of status code is platform-dependent.
                *       OS.Process.status is int on UNIX system,
                *       but is word on Windows.
                *)
               if 0 = exitCode
               then OS.Process.success
               else OS.Process.failure
             | exn =>
               let
                 val exn = 
                     case exn of
                       SessionTypes.Failure exn => exn
                     | SessionTypes.Fatal exn => exn
                     | _ => exn
                 val message =
                     case exn of
                       InvalidOption message => message
                     | Control.Bug message => "Bug:" ^ message
                     | Control.BugWithLoc (message, _) => 
                       "BugWithLoc:" ^ message 
                     | _ => exnMessage exn
               in
                 print ("Error:" ^ message ^ "\n");
                 app
                     (fn line => print (line ^ "\n"))
                     (SMLofNJ.exnHistory exn);
                 OS.Process.failure
               end

  (***************************************************************************)

end;
