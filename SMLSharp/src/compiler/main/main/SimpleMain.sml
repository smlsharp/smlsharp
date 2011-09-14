(**
 * simple main entry for separate compilation
 *
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure Main : sig

  val main : string * string list -> OS.Process.status

end =
struct

  fun catSome l =
      List.mapPartial (fn x => x) l

  fun printErr s =
      TextIO.output (TextIO.stdErr, s)

  fun printVersion () =
      print ("SML# version " ^ SMLSharpConfiguration.Version
             ^ " (" ^ SMLSharpConfiguration.ReleaseDate ^ ") for "
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

  fun userErrorToString' e =
      let
        val _ = print "userErrorToString\n";
        val s = userErrorToString e
        val _ = print "userErrorToString done\n";
      in
        s
      end
      
  fun printExn e =
      case e of
        UserError.UserErrors errs =>
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

  exception Exit of OS.Process.status
  exception Error of string list

  datatype makeDependMode = DEPEND_COMPILE | DEPEND_LINK

  datatype compilerMode =
      COMPILE_AND_LINK
    | MAKE_DEPEND of {mode: makeDependMode, dstfile: Filename.filename option}

  datatype sourceProcessMode =
      COMPILE of {options: Top.toplevelOptions, source: Filename.filename}
    | LINK of Filename.filename

  datatype commandLineArgs =
      OutputFile of string
    | IncludePath of string
    | LibraryPath of string
    | Library of string
    | StopAt of Top.stopAt
    | SourceFile of string
    | SystemBaseDir of string
    | LinkerFlags of string list
    | AssemblerFlags of string list
    | Target of string
    | MakeDepend of makeDependMode
    | Help
    | ControlSwitch of string
    | NoStdPath
    | Verbose

  fun splitComma x =
      String.fields (fn c => c = #",") x

  val optionDesc =
      let
        open GetOpt
      in
        [
          SHORT (#"o", REQUIRED OutputFile),
          SHORT (#"c", NOARG (StopAt Top.Object)),
          SHORT (#"S", NOARG (StopAt Top.Assembly)),
          SHORT (#"I", REQUIRED IncludePath),
          SHORT (#"L", REQUIRED LibraryPath),
          SHORT (#"l", REQUIRED Library),
          SHORT (#"v", NOARG Verbose),
          SHORT (#"B", REQUIRED SystemBaseDir),
          SHORT (#"M", NOARG (MakeDepend DEPEND_COMPILE)),
          SLONG ("Ml", NOARG (MakeDepend DEPEND_LINK)),
          SLONG ("Wl", REQUIRED (fn x => LinkerFlags (splitComma x))),
          SLONG ("Wa", REQUIRED (fn x => AssemblerFlags (splitComma x))),
          SLONG ("fsyntax-only", NOARG (StopAt Top.SyntaxCheck)),
          SLONG ("ftypecheck-only", NOARG (StopAt Top.ErrorCheck)),
          SLONG ("target", REQUIRED Target),
          SLONG ("nostdpath", NOARG NoStdPath),
          DLONG ("help", NOARG Help),
          SHORT (#"d", REQUIRED ControlSwitch)
        ]
      end

  fun usageMessage progname =
      "Usage: " ^ progname ^ " [options] file ...\n\
      \Options:\n\
      \  --help             print this message\n\
      \  -v                 verbose mode\n\
      \  -o <file>          place the output to <file>\n\
      \  -c                 compile only; do not assemble and link\n\
      \  -S                 compile and assemble; do not link\n\
      \  -M                 make dependency for compile\n\
      \  -Ml                make dependency for link\n\
      \  -fsyntax-only      check for syntax errors, and exit\n\
      \  -ftypecheck-only   check for type errors, and exit\n\
      \  -I <dir>           add <dir> to file search path\n\
      \  -L <dir>           add <dir> to library path of the linker\n\
      \  -l <libname>       link with <libname> to create an executable file\n\
      \  -Wl,<args>         pass comma-separated <args> to the linker\n\
      \  -Wa,<args>         pass comma-separated <args> to the assembler\n\
      \  -target=<target>   set target platform to <target>\n\
      \  -nostdpath         no standard file search path is used\n\
      \  -d <key>=<value>   set extra option for compiler developers.\n"

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

  local
    fun replaceSuffix suffix filename =
        case Filename.suffix filename of
          SOME "smi" => Filename.addSuffix (filename, suffix)
        | _ => Filename.replaceSuffix suffix filename
  in

  fun toAsmTarget filename = replaceSuffix BinUtils.ASMEXT filename
  fun toObjTarget filename = replaceSuffix BinUtils.OBJEXT filename

  end (* local *)

  fun toObjFile ({sourceName, ...}:AbsynInterface.interfaceName) =
      Filename.replaceSuffix BinUtils.OBJEXT (Filename.fromString sourceName)

  fun interpretArgs (progname, args) =
      let
        val systemBaseDir =
            ref (Filename.fromString SMLSharpConfiguration.LibDirectory)
        val noStdPath = ref false
        val loadPath = ref nil
        val LDFLAGS = ref nil
        val CFLAGS = ref nil
        val LIBS = ref nil
        val stopAt = ref Top.NoStop
        val outputFilename = ref NONE
        val linkOutputFilename = ref (Filename.fromString "a.out")
        val sources = ref nil
        val verbose = ref false
        val makeDepend = ref NONE
        val mode = ref COMPILE_AND_LINK

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
            | StopAt stop =>
              stopAt := stop
            | SourceFile filename =>
              sources := !sources @ [Filename.fromString filename]
            | SystemBaseDir filename =>
              systemBaseDir := Filename.fromString filename
            | LinkerFlags flags =>
              LDFLAGS := !LDFLAGS @ flags
            | AssemblerFlags flags =>
              CFLAGS := !CFLAGS @ flags
            | Target target =>
              (* Control.targetPlatform := target *) ()
            | Help =>
              (
                print (usageMessage progname);
                raise Exit OS.Process.success
              )
            | ControlSwitch pair =>
              setExtraOption pair
            | NoStdPath =>
              noStdPath := true
            | Verbose =>
              verbose := true
            | MakeDepend mode =>
              makeDepend := SOME mode

        val _ = app processArg args
        val _ = if !noStdPath then ()
                else loadPath := !loadPath @ [!systemBaseDir]
        val _ = case !makeDepend of
                  SOME depmode =>
                  (stopAt := Top.SyntaxCheck;
                   mode := MAKE_DEPEND {mode = depmode,
                                        dstfile = !outputFilename})
                | NONE => ()
        val _ = Control.printCommand := !verbose

        fun Compile (dstfile, srcfile) =
            COMPILE {options = {stopAt = !stopAt,
                                dstfile = dstfile,
                                baseName = SOME srcfile,
                                loadPath = !loadPath,
                                asmFlags = !CFLAGS},
                     source = srcfile}

        val sources =
            case (!stopAt, !outputFilename, !sources) of
              (_, _, nil) =>
              if !verbose
              then (printVersion (); raise Exit OS.Process.success)
              else raise Error ["no input files"]
            | (Top.SyntaxCheck, dstfile, sources) =>
              (
                case (!makeDepend, dstfile) of
                  (NONE, SOME _) =>
                  raise Error ["cannot specify -o with -fsyntax-only"]
                | _ => map (fn src => Compile (NONE, src)) sources
              )
            | (Top.ErrorCheck, SOME _, _) =>
              raise Error ["cannot specify -o with -ftypecheck-only"]
            | (Top.ErrorCheck, NONE, sources) =>
              map (fn src => Compile (NONE, src)) sources
            | (Top.Assembly, NONE, sources) =>
              map (fn src => Compile (SOME (toAsmTarget src), src)) sources
            | (Top.Assembly, SOME filename, _::_::_) =>
              raise Error ["cannot specify -o with -S with multiple files"]
            | (Top.Assembly, SOME filename, [source]) =>
              [Compile (SOME filename, source)]
            | (Top.Object, NONE, sources) =>
              map (fn src => Compile (SOME (toObjTarget src), src)) sources
            | (Top.Object, SOME filename, _::_::_) =>
              raise Error ["cannot specify -c with -S with multiple files"]
            | (Top.Object, SOME filename, [source]) =>
              [Compile (SOME filename, source)]
            | (Top.NoStop, outputFilename, sources) =>
              let
                val sources =
                    map (fn filename =>
                            if (case Filename.suffix filename of
                                  SOME "sml" => true
                                | SOME "smi" => true
                                | _ => false)
                            then Compile (NONE, filename)
                            else LINK filename)
                        sources
                val _ =
                    case List.filter (fn COMPILE _ => true | _ => false)
                                     sources of
                      nil => ()
                    | [_] => ()
                    | _::_::_ =>
                      raise Error ["cannot specify multiple .sml/.smi files\
                                   \ in link mode"]
                val _ =
                    case outputFilename of
                      SOME filename => linkOutputFilename := filename
                    | NONE => ();
              in
                sources
              end
      in
        {
          mode = !mode,
          sources = sources,
          linkOptions = {systemBaseDir = !systemBaseDir,
                         LDFLAGS = !LDFLAGS,
                         LIBS = !LIBS,
                         linkOutputFilename = !linkOutputFilename}
        }
      end

  fun compileFile options (io, sourceName) =
      let
        val input =
            Parser.setup {mode = Parser.File,
                          read = fn (_,n) => TextIO.inputN (io, n),
                          sourceName = sourceName,
                          initialLineno = 1}
        val result = Top.compile options input
      in
        case result of
          Top.STOPPED (interfaces as {requires, provide, ...}) =>
          {code = NONE, main = nil, objs = nil, depends = interfaces}
        | Top.RETURN (Top.FILE code, interfaces as {requires, provide, ...}) =>
          {code = SOME code,
           main = requires @ catSome [provide],
           objs = requires,
           depends = interfaces}
      end

  fun compileSource options filename =
      case Filename.suffix filename of
        SOME "smi" =>
        let
          val options = {baseName = #baseName options,
                         loadPath = #loadPath options}
          val interfaces as {requires, provide, ...} =
              Top.loadInterface options filename
        in
          {code = NONE,
           main = requires @ catSome [provide],
           objs = requires @ catSome [provide],
           depends = interfaces}
        end
      | _ =>
        let
          val io = Filename.TextIO.openIn filename
          val result = compileFile options (io, Filename.toString filename)
              handle e => (TextIO.closeIn io; raise e)
        in
          TextIO.closeIn io;
          result
        end

  fun compileMain (options:Top.toplevelOptions) interfaces =
      case interfaces of
        nil => NONE
      | interfaces =>
        let
          val mainCode = GenerateMain.generate interfaces
          val io = TextIO.openString mainCode
          val options = {stopAt = #stopAt options,
                         dstfile = #dstfile options,
                         baseName = NONE,
                         loadPath = nil,
                         asmFlags = #asmFlags options}
        in
          #code (compileFile options (io, "(main)"))
        end

  fun checkExist filenames =
      case List.filter (fn f => not (CoreUtils.testExist f)) filenames of
        nil => ()
      | files =>
        raise Error (map (fn f => "required object file is not found: "
                                  ^ Filename.toString f) files)

  fun compile {options, source} =
      let
        val {code=code1, main, objs, ...} = compileSource options source
        val code2 = compileMain options main
        val provides = catSome [code1, code2]
        val objfiles = case provides of
                         nil => nil
                       | _::_ => map toObjFile objs
        val _ = checkExist objfiles
      in
        provides @ objfiles
      end

  fun link {systemBaseDir, LDFLAGS, LIBS, linkOutputFilename} objfiles =
      let
        val libsmlsharp = Filename.fromString "libsmlsharp.a"
        val libsmlsharp = Filename.concatPath (systemBaseDir, libsmlsharp)
        val smlsharpEntry = Filename.fromString "smlsharp_entry.o"
        val smlsharpEntry = Filename.concatPath (systemBaseDir, smlsharpEntry)
      in
        BinUtils.link {flags = LDFLAGS,
                       libs = LIBS,
                       objects = smlsharpEntry :: objfiles @ [libsmlsharp],
                       dst = linkOutputFilename}
      end

  local
    fun listDepends mode source
                    ({requires, provide, depends}:Top.interfaceNames) =
        case mode of
          DEPEND_COMPILE =>
          {target = Filename.toString (toObjTarget source),
           depend = Filename.toString source :: depends}
        | DEPEND_LINK =>
          let
            val main =
                case provide of
                  NONE => nil
                | SOME {sourceName, ...} =>
                  [toObjTarget (Filename.fromString sourceName)]
            val modules = map toObjFile (requires @ catSome [provide])
          in
            {target = Filename.toString (Filename.removeSuffix source),
             depend = map Filename.toString (main @ modules)}
          end

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

  fun makeDepend {mode, dstfile} sources =
      let
        val output =
            List.mapPartial
              (fn LINK _ => NONE
                | COMPILE {options, source} =>
                  let
                    val {depends,...} = compileSource options source
                    val {target, depend} = listDepends mode source depends
                  in
                    SOME (format 0 ((target ^ ":") :: depend))
                  end)
              sources
      in
        case dstfile of
          NONE => app print output
        | SOME dstfile =>
          CoreUtils.makeTextFile (dstfile, String.concat output)
      end

  end (* local *)

  fun main (progname, args) =
      let
        val args = parseArgs args

        val _ = Control.printBinds := false
        val _ = Control.switchTrace := true
        val _ = Control.tracePrelude := true
        val _ = Control.targetPlatform := SMLSharpConfiguration.NativeTarget

        val {mode, sources, linkOptions} = interpretArgs (progname, args)

        val _ = Top.initBuiltin ()

        val _ = case mode of
                  MAKE_DEPEND options =>
                  (makeDepend options sources; raise Exit OS.Process.success)
                | COMPILE_AND_LINK => ()

        val objfiles =
            map (fn COMPILE arg => compile arg | LINK file => [file]) sources

        val _ =
            case List.concat objfiles of
              nil => ()
            | objfiles => link linkOptions objfiles
      in
        TempFile.cleanup ();
        OS.Process.success
      end
      handle e =>
        (
          TempFile.cleanup ();
          case e of
            Exit status => status
          | Error msgs =>
            (
             app (fn x => printErr (progname ^ ": " ^ x ^ "\n")) msgs;
             OS.Process.failure
            )
          | e => 
            (printExn e;
             OS.Process.failure)
        )

end
