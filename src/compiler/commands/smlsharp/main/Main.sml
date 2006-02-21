(**
 * Copyright (c) 2006, Tohoku University.
 *
 * run the interactive session with runtime
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.20 2006/02/21 02:23:41 katsuu Exp $
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

  structure C = Control
  structure G = GetOpt
  structure PU = PathUtility

  (***************************************************************************)

  datatype runMode = CompileAndExecuteMode | CompileOnlyMode | MakeLibraryMode

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
         | LibraryDirectory of string
         | MakeLibrary
         | NoBasis
         | NoWarning
         | NoPrintBinds
         | OutputFile of string
         | PreludeFile of string
         | Quiet
         | StdIn
         | UseBasis
         | Version

  (**
   * command line options are stored in this record.
   *)
  type parameters =
       {
         sources : (unit -> Top.source) list ref,
         mode : runMode ref,
         libPaths : string list ref,
         outputFileName : string ref,
         preludeFileName : prelude ref,
         printBinds : bool ref,
         printWarning : bool ref
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
  val tracePrelude = ref false
  val useBasis = ref false
  val compileOnly = ref false

  val _ = C.printBinds := true
  val _ = C.switchTrace := false

  (* use the standard preludes. *)
  val minimumPreludeFileName = Configuration.MinimumPreludeFileName
  val BasisFileName = Configuration.BasisFileName
  val CompiledBasisFileName = Configuration.CompiledBasisFileName
  val DefaultPreludeFile =
      Compiled CompiledBasisFileName
(*
      Source (if !useBasis then BasisFileName else minimumPreludeFileName)
*)

  (* ToDo : the file name of runtime should be specified in Configuration. *)
  val RuntimeFileName = Configuration.RuntimeFileName
  val DefaultObjectFileName = "a.sme"
  val InstallLibDirectory = Configuration.LibDirectory
  val LibPathEnvVarName = "SMLSHARP_LIB_PATH"
  val version = Configuration.Version

  (********************)
  (* functions to manipulate control option *)

  fun getOptOfControlOption (name, switch) =
      let
        val argument =
            case switch of C.IntSwitch _ => "NUM" | C.BoolSwitch _ => "yes/no"
      in
        {
          short = "",
          long = ["x" ^ name],
          desc = G.ReqArg (fn value => Control(name, switch, value), argument),
          help = "control option."
        }
      end

  (********************)

  val optionDescs =
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
          short = "I",
          long = ["lib"],
          desc = G.ReqArg (LibraryDirectory, "DIR"),
          help = "Prepend DIR to the load path list."
        },
        {
          short = "",
          long = ["library"],
          desc = G.NoArg MakeLibrary,
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
          help = "Suppress printing binding information."
        },
        {
          short = "o",
          long = ["output"],
          desc = G.ReqArg (OutputFile, "FILE"),
          help = "Place the output into FILE."
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
(*
        {
          short = "",
          long = ["usebasis"],
          desc = G.NoArg UseBasis,
          help = "shorthand of --prelude=" ^ BasisFileName
        },
*)
        {
          short = "v",
          long = ["version"],
          desc = G.NoArg Version,
          help = "Print version number and exit."
        }
      ]
      @ (map getOptOfControlOption (SEnv.listItemsi C.switchTable))
  val usageHeader = "Usage : smlsharp [OPTION ...] [files...]"
  val usage = G.usageInfo {header = usageHeader, options = optionDescs}

  val STDINChannel = TextIOChannel.openIn {inStream = TextIO.stdIn}
  val STDOUTChannel = TextIOChannel.openOut {outStream = TextIO.stdOut}
  val STDERRChannel = TextIOChannel.openOut {outStream = TextIO.stdErr}

  (** an utility. ensure finalizer is executed *)
  fun finally arg userFunction finalizer =
      ((userFunction arg) before (finalizer arg))
      handle e => (finalizer arg; raise e)

  fun writeMagicNumberHeader outputChannel =
      #print
          (CharacterStreamWrapper.wrapOut outputChannel)
          ("#!/usr/bin/env " ^ RuntimeFileName ^ "\n")

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
        val sourceDir = #dir(PU.splitDirFile absoluteFilePath)
        fun getSource () =
            {
              interactionMode = Top.NonInteractive {stopOnError = true},
              initialSource = FileChannel.openIn {fileName = absoluteFilePath},
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
        val (options, sourceNames) =
            G.getOpt
                {
                  argOrder = G.Permute,
                  options = optionDescs,
                  errFn = fn message => raise Fail (message ^ usage)
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
          | processOpt (LibraryDirectory directory) =
            (* prepend to the list *)
            (#libPaths parameters) := directory :: !(#libPaths parameters)
          | processOpt MakeLibrary = #mode parameters := MakeLibraryMode
          | processOpt NoBasis = 
            (#preludeFileName parameters) := Source minimumPreludeFileName
          | processOpt NoWarning = (#printWarning parameters) := false
          | processOpt NoPrintBinds = (#printBinds parameters) := false
          | processOpt (OutputFile fileName) =
            (#outputFileName parameters) := fileName
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
          | processOpt UseBasis =
            (#preludeFileName parameters) := Source BasisFileName
          | processOpt Version = (print (version ^ "\n"); raise Quit)

        val _ = app processOpt options

        (* "-" is special argument specifying STDIN. *)
        fun getSourceOfName "-" =
            getSourceOfStdIn (Top.NonInteractive {stopOnError = true})
          | getSourceOfName fileName =
            getSourceOfFile
                OS.Process.getEnv (!(#libPaths parameters)) fileName

        val sources = map getSourceOfName sourceNames
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

        #sources parameters := !(#sources parameters) @ sources;

        case !(#sources parameters) of
          [] => (* interactive mode *)
          #sources parameters := [getSourceOfStdIn Top.Interactive]
        | _ => (* filter mode *) #printBinds parameters := false
      end

  (********************)

  fun createLibrary outputChannel context executableChannel =
      let
        fun writer byte = #send outputChannel byte
        (* pickled static environment is at the head of library file. *)
        val _ = Top.pickle context (Pickle.makeOutstream writer)
        (* copy executables into the library file. *)
        val _ = ChannelUtility.copy (executableChannel, outputChannel)
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
        val _ = print "restoring static environment..."
        val context = Top.unpickle parameter (Pickle.makeInstream reader)
        val _ = print "done\n"

        val session = #session parameter
        fun execute () =
            case StandAloneSession.loadExecutable channel of
              SOME executable => (#execute session executable; execute ())
            | NONE => ()
        val _ = print "restoring dynamic environment..."
        val _ = execute ()
        val _ = print "done\n"
      in
        context
      end

  fun start (parameter : Top.contextParameter) (preludeSource : Top.source) =
      let
        val context = Top.initialize parameter
      in
        if Top.run context preludeSource
        then context
        else raise Fail "prelude cannot compile."
      end

  (********************)

  fun getInteractiveSession (parameters : parameters) =
      let
        val proxy = RuntimeProxyFactory.createInstance ()
        val sessionParameter = 
            {
              terminalInputChannel = STDINChannel,
              terminalOutputChannel = STDOUTChannel,
              terminalErrorChannel = STDERRChannel,
              runtimeProxy = proxy
            }
        val session = InteractiveSession.openSession sessionParameter
        fun cleanUp _ = #release proxy ()
      in
        (session, cleanUp)
      end

  fun getBatchSession (parameters : parameters) =
      let
        val outputFileName = !(#outputFileName parameters)
        val outputChannel = FileChannel.openOut {fileName = outputFileName}
        val _ = writeMagicNumberHeader outputChannel
        val _ = FileSysUtil.setFileModeExecutable outputFileName
        val session =
            StandAloneSession.openSession {outputChannel = outputChannel}
        fun cleanUp _ = #close outputChannel ()
      in
        (session, cleanUp)
      end

  fun getMakeLibrarySession (parameters : parameters) =
      let
        (* generated executables are bufferred into this bufferOptRef. *)
        val bufferOptRef = ref (NONE : Word8Array.array option)
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
        val libPaths =
            case OS.Process.getEnv LibPathEnvVarName of
              NONE => []
            | SOME libPath =>
              String.tokens (fn ch => ch = FileSysUtil.PathSeprator) libPath

        val _ = C.setControlOptions "IML_" OS.Process.getEnv

        (* default parameter *)                
        val parameters =
            {
              sources = ref [],
              mode =
              ref
                  (if !compileOnly
                   then CompileOnlyMode
                   else CompileAndExecuteMode),
              libPaths = ref (libPaths @ [InstallLibDirectory, "."]),
              outputFileName = ref DefaultObjectFileName,
              preludeFileName = ref DefaultPreludeFile,
              printBinds = C.printBinds,
              printWarning = C.printWarning
            } : parameters

        (* update parameter to user specified *)                
        val _ = parseArguments parameters arguments

        val (session, cleanUp) =
            case !(#mode parameters) of
              CompileAndExecuteMode => getInteractiveSession parameters
            | CompileOnlyMode => getBatchSession parameters
            | MakeLibraryMode => getMakeLibrarySession parameters

        val topParameter = 
            {
              session = session,
              standardOutput = STDOUTChannel,
              standardError = STDERRChannel,
              loadPathList = !(#libPaths parameters),
              getVariable = OS.Process.getEnv
            }

        fun getPreludeSource preludeFileName =
            getSourceOfFile
                OS.Process.getEnv
                (!(#libPaths parameters))
                preludeFileName

        val currentSwitchTrace = !C.switchTrace
        val currentPrintBinds = !C.printBinds

      in
        C.switchTrace := !tracePrelude;
        C.printBinds := !printPrelude;
        let
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
                      (getPreludeSource fileName ())
                      (contextCreator topParameter)
                      (fn source => #close (#initialSource source) ())
                end
              else Top.initialize topParameter
        in
          C.switchTrace := currentSwitchTrace;
          C.printBinds := currentPrintBinds;

          List.all (* stop if any compilation fails. *)
              (fn getSource => Top.run context (getSource ()))
              (!(#sources parameters));

          #close session ();
          cleanUp (SOME context);
          OS.Process.success
        end
          handle exn =>
                 (#close session (); cleanUp NONE; raise exn)
      end
        handle Quit => OS.Process.success
             | exn =>
               let
                 val exn = 
                     case exn of
                       SessionTypes.Error exn => exn
                     | _ => exn
               in
                 print ("Error:" ^ (exnMessage exn) ^ "\n");
                 app
                     (fn line => print (line ^ "\n"))
                     (SMLofNJ.exnHistory exn);
                 OS.Process.failure
               end

  (***************************************************************************)

end;
