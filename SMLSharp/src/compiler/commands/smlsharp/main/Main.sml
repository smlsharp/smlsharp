(**
 * run the interactive session with runtime
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.79 2008/11/19 20:04:38 ohori Exp $
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
  structure PR = PathResolver

  (***************************************************************************)

  datatype runMode =
           CompileAndExecuteMode
         | CompileOnlyMode
         | MakeCompiledLibraryMode

  datatype prelude = Source of string | Compiled of string | NoPrelude
                   | Unspecified

  (**
   * command line options user can specify.
   *)                                                  
  datatype parameterOption =
           CompileOnly
         | Native
         | CompiledPrelude of string
         | Control of string * C.switch * string
         | Expression of string
         | Help
         | HelpEx
         | LibraryDirectory of string
         | MakeCompiledLibrary
         | NoBasis
         | NoPreludeOpt
         | NoWarning
         | NoPrintBinds
         | ObjectFile of string
         | OutputFile of string
         | PreludeFile of string
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
  val DefaultPreludeFile = Unspecified
(*
      Source (if !useBasis then BasisFileName else minimumPreludeFileName)
*)

  val DefaultObjectFileName = "a.sme"
  val InstallLibDirectory = Configuration.LibDirectory
  val LibPathEnvVarName = "SMLSHARP_LIB_PATH"
  val ProductName = "SML#"
  val Version = Configuration.Version
  fun VersionInfoMessage () =
      let
        val {cpu, manufacturer, ossys, ...} = Control.targetInfo ()
      in
        ProductName ^ " " ^ Version
        ^ " (" ^ Configuration.ReleaseDate
        ^ " " ^ cpu ^ "-" ^ manufacturer ^ "-" ^ ossys ^ ")"
      end

  (********************)

  val CT.CounterSetInternal MainCounterSet =
      #addSet CT.root ("Main", CT.ORDER_OF_ADDITION)
  val restoreStaticEnvTimeCounter =
      #addElapsedTime MainCounterSet "restore static ENV"
  val restoreDynamicEnvTimeCounter =
      #addElapsedTime MainCounterSet "restore dynamic ENV"
  val initializationCounter =
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
      List.app
          (fn (name, switch) =>
              app print [name, " = [", C.switchToString switch, "]\n"])
          (C.listSwitches ())

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
          long = ["native"],
          desc = G.NoArg Native,
          help = "generate native code."
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
          long = ["noprelude"],
          desc = G.NoArg NoPreludeOpt,
          help = "compile without prelude."
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
  val optionDescsExtra = map getOptOfControlOption (C.listSwitches ())
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
        (Word8VectorSlice.foldli
             (fn (m,i,z) => (fn (index, byte, len) =>
                 if NL = byte then raise Found index else len) (m + 2, i, z))
             (BV.length vector)
             (*vector, 2, NONE*) (*Word8VectorSlice.vector*) (Word8VectorSlice.slice (vector, 2, NONE)))
        handle Found index => (index + 1)
      else 0
  end
(*
(BV.foldli
             (fn (index, byte, len) =>
                 if NL = byte then raise Found index else len)
             (BV.length vector)
             (vector, 2, NONE))
*)


  fun getEnv "PWD" = SOME(OS.FileSys.getDir ())
    | getEnv "SMLSHARP_OS" = SOME(Platform.OSName)
    | getEnv "SMLSHARP_ARCH" = SOME(Platform.ArchName)
    | getEnv name = OS.Process.getEnv name

  fun getSourceOfStdIn interactionMode () =
      {
        interactionMode = interactionMode,
        initialSourceChannel = STDINChannel,
        initialSourceName = "stdIn",
        getBaseDirectory = OS.FileSys.getDir
      } : Top.source

  fun getSourceOfInlineExpression expression () = 
      {
        interactionMode = Top.NonInteractive {stopOnError = true},
        initialSourceChannel =
        TextIOChannel.openIn {inStream = TextIO.openString expression},
        initialSourceName = "argument",
        getBaseDirectory = OS.FileSys.getDir
      } : Top.source

  fun getSourceOfFile getVariable loadPathList sourceFileName =
      let
        val absoluteFilePath = 
            PR.resolve
                getVariable loadPathList "." sourceFileName
            handle PR.InvalidPath message =>
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
              initialSourceChannel = sourceChannel,
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
          | processOpt Native = C.targetPlatform := Configuration.NativeTarget
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
          | processOpt NoPreludeOpt =
            (#preludeFileName parameters) := NoPrelude
          | processOpt (ObjectFile fileName) =
            (#objectFileNames parameters) :=
            (!(#objectFileNames parameters)) @ [fileName]
          | processOpt (OutputFile fileName) =
            (#outputFileName parameters) := fileName
          | processOpt (PreludeFile fileName) =
            (#preludeFileName parameters) := Source fileName
          | processOpt Quiet =
            (
              #printWarning parameters := false;
              #printBinds parameters := false
            )
          | processOpt ShowVersion =
            (print (VersionInfoMessage () ^ "\n"); raise Quit)
          | processOpt ShowControl =
            (printControlOptions (); raise Quit)
          | processOpt StdIn =
            (#sources parameters)
            := !(#sources parameters)
               @ [getSourceOfStdIn (Top.NonInteractive {stopOnError = true})]

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

  (**
   * pickles static/dynamic status of the compiler.
   * Pickled status will be unpickled by 'resume' function.
   * @params output context executable
   * @param output pickled status is written into this stream.
   * @param context static status of the compiler.
   * @param executable a stream into which executables have been emitted.
   *)
  fun createLibrary outputChannel context executableChannel =
      let
        val _ = trace "saving static environment..."
        val writer =
            {
              putByte = fn byte => #send outputChannel byte,
              getPos = #getPos outputChannel,
              seek = #seek outputChannel
            }
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

  fun unpickleContext (channel:ChannelTypes.InputChannel) =
      let
        val reader =
            {
              getByte = 
              fn () =>
                 case #receive channel () of
                   SOME byte => byte
                 | NONE => raise Fail "unexpected EOF of library",
              getPos =
              if !C.doPreludeLazyUnpickling then #getPos channel else NONE,
              seek =
              if !C.doPreludeLazyUnpickling then #seek channel else NONE
            }
        val _ = trace "restoring static environment..."
        val _ = #start restoreStaticEnvTimeCounter ()
        val contextAndStamps =
            Top.unpickle (Pickle.makeInstream reader)
            handle exn =>
                   raise Fail ("malformed compiled code:" ^ exnMessage exn)
        val _ = #stop restoreStaticEnvTimeCounter ()
        val _ = trace "done\n"
      in
        contextAndStamps
      end

  (**
   * resume the compiler from a static/dynamic status pickled by
   * 'createLibrary'.
   * @params parameter prelude
   * @param parameter parameter to create context.
   * @param prelude a stream from which pickled status is read.
   *)
  fun resume (parameter : Top.sysParam) (preludeSource : Top.source) =
      let
        val channel = #initialSourceChannel preludeSource
        val contextAndStamps = unpickleContext channel

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
          contextAndStamps
      end

  fun newVMresume (parameter : Top.sysParam) (preludeSource : Top.source) =
      let
        val channel = #initialSourceChannel preludeSource

        (* FIXME: inefficient *)
        val buf = ChannelUtility.getAll channel
        val buf = Word8Array.tabulate (Word8Vector.length buf,
                                       fn i => Word8Vector.sub (buf, i))

        val {objectFile, extraSections} = ELFReader.read buf

        val pickledContext = 
            case SEnv.find (extraSections, ".sml#.context") of
              SOME x => Word8ArraySlice.vector x
            | NONE => raise Fail "no compiler context exists"

        val channel = ByteVectorChannel.openIn {buffer = pickledContext}
        val contextAndStamps = unpickleContext channel

        val session = #session parameter

        val _ = trace "restoring dynamic environment..."
        val _ = #start restoreDynamicEnvTimeCounter ()
        val _ = #execute session (SessionTypes.OBJECTFILE objectFile)
        val _ = #stop restoreDynamicEnvTimeCounter ()
        val _ = trace "done\n"
      in
        contextAndStamps
      end

  (**
   * starts the compiler in fresh status, and executes the prelude.
   * @params parameter prelude
   * @param parameter parameter to create context.
   * @param prelude a stream from which source code of prelude is read.
   *)
  fun start (parameter : Top.sysParam) (preludeSource : Top.source) =
      let
          val (context, stamps) = Top.initializeContextAndStamps ()
          val preludeSource =
              {
               interactionMode = Top.Prelude,
               initialSourceChannel = #initialSourceChannel preludeSource,
               initialSourceName = #initialSourceName preludeSource,
               getBaseDirectory = #getBaseDirectory preludeSource
              }
          val (success, updateContextAndStamps) = 
              Top.run context stamps parameter preludeSource
      in
          if success
          then updateContextAndStamps
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
        fun cleanUp _ = ()
      in
        (session, cleanUp)
      end

  fun getBatchSession (parameters : parameters) =
      let
        (* generated executables are bufferred into this bufferOptRef. *)
        val orderRef = ref ByteListChannel.NORMAL (* this value is ignored. *)
        val bufferRef = ref []
        val outputChannel =
            ByteListChannel.openOut {order = orderRef, buffer = bufferRef}

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

              (* inserts header *)
              val _ = #print outputFileChannel (!C.headerOfExecutable)
              val _ =
                  case !orderRef
                   of ByteListChannel.NORMAL =>
                      List.app (#sendVector outputFileChannel) (!bufferRef)
                    | ByteListChannel.REVERSED =>
                      List.foldr
                          (fn (b, ()) => #sendVector outputFileChannel b)
                          ()
                          (!bufferRef)
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
                  val libraryBuffer = ref NONE
                  val libraryChannel =
                      ByteArrayChannel.openOut {buffer = libraryBuffer}
                  val executableChannel =
                      ByteArrayChannel.openIn {buffer = valOf(!bufferOptRef)}
                  val () =
                      createLibrary libraryChannel context executableChannel
                  val () = #close libraryChannel ()

                  val outputFileName = !(#outputFileName parameters)
                  val fileChannel =
                      FileChannel.openOut {fileName = outputFileName}
                  val () = #sendArray fileChannel (valOf(!libraryBuffer))
                  val () = #close fileChannel ()
                in
                  ()
                end
              | NONE => ()
            end
      in
        (session, cleanUp)
      end

  fun getNewVMInteractiveSession (parameters : parameters) =
      let
        val sessionParameter = 
            {
              terminalInputChannel = STDINChannel,
              terminalOutputChannel = STDOUTChannel,
              terminalErrorChannel = STDERRChannel,
              arguments = !(#extraArgs parameters)
            }
        val session = YAInteractiveSessionFactory.openSession sessionParameter
        fun cleanUp _ = ()
      in
        (session, cleanUp)
      end

  fun getNewVMBatchSession (parameters : parameters) =
      let
        val objfileRef = ref NONE
        val session =
            YAStandAloneSession.openSession {objectFile = objfileRef}

        fun cleanUp NONE = ()
          | cleanUp (SOME _) =
            case !objfileRef of
              NONE => ()
            | SOME objfile =>
              let
                val outputFileName = !(#outputFileName parameters)
                val outputFileChannel =
                    FileChannel.openOut {fileName = outputFileName}
              in
                finally ()
                  (fn _ => ELFWriterLE.write (#sendArray outputFileChannel,
                                              objfile, nil))
                  (fn _ => #close outputFileChannel ())
              end
      in
        (session, cleanUp)
      end

  fun getNewVMBatchSessionNoLink (parameters : parameters) =
      let
        val objectFileListRef = ref nil
        val sessionParameter =
            {
              baseName = !(#outputFileName parameters),
              objectFileList = objectFileListRef
            }

        val session =
            YAStandAloneSessionNoLink.openSession sessionParameter

        fun cleanUp NONE = ()
          | cleanUp (SOME _) =
            app
              (fn {fileName, objectFile} =>
                  let
                    val outputFileChannel =
                        FileChannel.openOut {fileName = fileName}
                  in
                    finally ()
                      (fn _ => ELFWriterLE.write (#sendArray outputFileChannel,
                                                  objectFile, nil))
                      (fn _ => #close outputFileChannel ())
                  end)
              (!objectFileListRef)
      in
        (session, cleanUp)
      end

  fun getNewVMMakeCompiledLibrarySession (parameters : parameters) =
      let
        val objfileRef = ref NONE
        val session =
            YAStandAloneSession.openSession {objectFile = objfileRef}

        fun cleanUp NONE = ()
          | cleanUp (SOME context) =
            case !objfileRef of
              NONE => ()
            | SOME objfile =>
              let
                val pickleBuffer = ref NONE
                val pickleChannel =
                    ByteArrayChannel.openOut {buffer = pickleBuffer}

                val _ = trace "saving static environment..."
                val writer =
                    {
                      putByte = fn byte => #send pickleChannel byte,
                      getPos = #getPos pickleChannel,
                      seek = #seek pickleChannel
                    }

                val _ = Top.pickle context (Pickle.makeOutstream writer)
                val _ = trace "done\n"

                val _ = #close pickleChannel ()
                val contextSection =
                    {
                      sectionName = ".sml#.context",
                      content = valOf (!pickleBuffer)
                    }

                val _ = trace "saving dynamic environment..."
                val outputFileName = !(#outputFileName parameters)
                val outputFileChannel =
                    FileChannel.openOut {fileName = outputFileName}
              in
                finally ()
                  (fn _ => ELFWriterLE.write (#sendArray outputFileChannel,
                                              objfile, [contextSection]))
                  (fn _ => #close outputFileChannel ())
              end
      in
        (session, cleanUp)
      end

  fun getNativeBatchSession mode (parameters : parameters) =
      let
        val preludeLibraryFileName =
            case !(#preludeFileName parameters) of
                Compiled filename =>
                let
                  val {base, ext} = OS.Path.splitBaseExt filename
                in
                  SOME (OS.Path.joinBaseExt {base=base, ext=SOME "o"})
                end
              | _ => NONE

        val compileMode =
            case mode of
              CompileAndExecuteMode => NativeStandAloneSession.Executable
            | CompileOnlyMode => NativeStandAloneSession.ObjectFile
            | MakeCompiledLibraryMode =>
              (* TODO: make a static library *)
              NativeStandAloneSession.ObjectFile

        val session =
            NativeStandAloneSession.openSession
                {outputFileName = !(#outputFileName parameters),
                 compileMode = compileMode,
                 preludeLibraryFileName = preludeLibraryFileName}

        fun cleanUp NONE = ()
          | cleanUp (SOME context) =
            case mode of
              MakeCompiledLibraryMode =>
              let
                val basename = !(#outputFileName parameters)
                val {base, ext} = OS.Path.splitBaseExt basename
                val filename = OS.Path.joinBaseExt {base=base, ext=SOME "smc"}

                val pickleChannel = FileChannel.openOut {fileName = filename}
                val writer = {putByte = fn byte => #send pickleChannel byte,
                              getPos = #getPos pickleChannel,
                              seek = #seek pickleChannel}
              in
                trace "saving static environment...";
                finally ()
                  (fn _ => Top.pickle context (Pickle.makeOutstream writer))
                  (fn _ => #close pickleChannel ());
                  trace "done\n"
              end
            | _ => ()
      in
        (session, cleanUp)
      end

  fun nativeResume (parameter : Top.sysParam) (preludeSource : Top.source) =
      unpickleContext (#initialSourceChannel preludeSource)

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

      val _ =
          #preludeFileName parameters :=
          (case (#cpu (Control.targetInfo ()), !(#preludeFileName parameters))
            of ("", Unspecified) => Compiled CompiledPreludeFileName
             | ("newvm", Unspecified) =>
               Compiled (OS.Path.joinDirFile {dir=Configuration.LibDirectory,
                                              file="yaprelude.smo"})
             | (_, Unspecified) =>
               Compiled (OS.Path.joinDirFile {dir=Configuration.LibDirectory,
                                              file="ntprelude.smc"})
             | (_, x) => x)

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
        case (#cpu (Control.targetInfo ()), !(#mode parameters)) of
          ("", CompileAndExecuteMode) => getInteractiveSession parameters
        | ("", CompileOnlyMode) => getBatchSession parameters
        | ("", MakeCompiledLibraryMode) =>
          getMakeCompiledLibrarySession parameters
        | ("newvm", CompileAndExecuteMode) =>
          getNewVMInteractiveSession parameters
        | ("newvm", CompileOnlyMode) =>
          if !Control.withoutLink
          then getNewVMBatchSessionNoLink parameters
          else getNewVMBatchSession parameters
        | ("newvm", MakeCompiledLibraryMode) =>
          getNewVMMakeCompiledLibrarySession parameters
        | (_, mode) => getNativeBatchSession mode parameters
              
      val currentSwitchTrace = !C.switchTrace
      val currentPrintBinds = !C.printBinds

    in
      if !C.printBinds
      then (print (VersionInfoMessage ()); print "\n")
      else ();

      #start initializationCounter ();

      C.switchTrace := !tracePrelude;
      C.printBinds := !printPrelude;
      let
        (* obtains TopLevel context. *)
          
        fun getSource fileName =
          getSourceOfFile getEnv (!(#libPaths parameters)) fileName

        val topParameter = 
          {
           session = session,
           standardOutput = STDOUTChannel,
           standardError = STDERRChannel,
           loadPathList = !(#libPaths parameters),
           getVariable = getEnv
           }
          
        val contextAndStamps = 
            let
              val loader =
                  case (!loadPrelude, !(#preludeFileName parameters)) of
                    (true, Source preludeFileName) =>
                    SOME (preludeFileName, start)
                  | (true, Compiled preludeFileName) =>
                    (
                      case #cpu (Control.targetInfo ()) of
                        "" => SOME (preludeFileName, resume)
                      | "newvm" => SOME (preludeFileName, newVMresume)
                      | _ => SOME (preludeFileName, nativeResume)
                    )
                  | _ => NONE
              in
                case loader of
                  SOME (fileName, contextCreator) =>
                  finally
                    (getSource fileName ())
                    (contextCreator topParameter)
                    (fn source => #close (#initialSourceChannel source) ())
                | NONE => Top.initializeContextAndStamps ()
            end

(* to be implemented for useObj:
        val _ = 
          if List.all
            (fn fileName => Top.runObject context (getSource fileName ()))
            (!(#objectFileNames parameters))
            then ()
          else raise Fail "loading object file fails.";
*)

        val _ = C.switchTrace := currentSwitchTrace
        val _ = C.printBinds := currentPrintBinds

        val _ = #stop initializationCounter ()

        val _ = if !C.doProfile
                  then (print "\n"; print (Counter.dump ()))
                else ()

        val (successList, contextAndStamps) =
          foldl (fn (getSource, (successList, (context, stamps))) => 
                 let
                   val (success, contextAndStamps) =
                     Top.run context stamps topParameter (getSource ())
                 in
                   (successList @ [success],
                    contextAndStamps)
                 end)
          (nil, contextAndStamps)
          (!(#sources parameters))

        val _ = 
          if List.all (fn x => x) successList
            (* stop if any compilation fails. *)
            then ()
          else raise Fail "Compilation fails.";
      in
        #close session ();
        cleanUp (SOME contextAndStamps);
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
