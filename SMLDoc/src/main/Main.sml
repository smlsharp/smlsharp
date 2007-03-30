(**
 * entry point.
 * @author YAMATODANI Kiyoshi
 * @version $Id: Main.sml,v 1.14 2007/03/05 03:31:23 kiyoshiy Exp $
 *)
structure Main =
struct

  (***************************************************************************)

  structure G = GetOpt
  structure U = Utility
  structure PU = PathUtility
  structure DGP = DocumentGenerationParameter

  (***************************************************************************)

  exception InvalidParameter of string

  (***************************************************************************)

  datatype parameterOption =
           ArgFile of string
         | Author
         | Contributor
         | Copyright
         | Bottom of string
         | BuiltinType of string
         | BuiltinStructure of string
         | CharSet of string
         | Directory of string
         | DocTitle of string
         | Footer of string
         | Header of string
         | Help
         | HelpFile of string
         | HideBySig
         | Link of string
         | LinkOffline of string
         | LinkSource
         | ListSubModule
         | NoHelp
         | NoIndex
         | NoNavBar
         | NoWarning
         | Overview of string
         | Recursive
         | ShowSummary
         | SplitIndex
         | StdIn
         | Use
         | Verbose
         | Version
         | WindowTitle of string
                          
  (***************************************************************************)

  local
    (* substitute environment variable with ${NAME} in option argument. *)
    fun ReqArg(con, name) = G.ReqArg(con o U.replaceEnv, name)
    fun NoArg con = G.NoArg con
    fun OptArg(con, name) = G.OptArg(con o (Option.map U.replaceEnv), name)
  in
  val usageHeader = "Usage : smldoc [OPTION ...] [files...]"
  val optionDescs =
      [
        {
          short = "a",
          long = ["argfile"],
          desc = ReqArg(ArgFile, "ARGFILE"),
          help = "Files that contain SMLDoc options, source filenames and \
                 \other names of argfiles in any order."
        },
        {
          short = "",
          long = ["author"],
          desc = NoArg Author,
          help = "Include @author paragraphs"
        },
        {
          short = "",
          long = ["builtintype"],
          desc = ReqArg(BuiltinType, "TYPE"),
          help = "Interpret TYPE as a builtin type."
        },
        {
          short = "",
          long = ["builtinstructure"],
          desc = ReqArg(BuiltinStructure, "STRUCTURE"),
          help = "Interpret STRUCTURE as a builtin type."
        },
        {
          short = "",
          long = ["bottom"],
          desc = ReqArg(Bottom, "HTML"),
          help = "Include bottom text for each page"
        },
        {
          short = "c",
          long = ["charset"],
          desc = ReqArg(CharSet, "CHARSET"),
          help = "Charset for cross-platform viewing of generated \
                 \documentation."
        },
        {
          short = "",
          long = ["contributor"],
          desc = NoArg Contributor,
          help = "Include @contributor paragraphs"
        },
        {
          short = "",
          long = ["copyright"],
          desc = NoArg Copyright,
          help = "Include @copyright paragraphs"
        },
        {
          short = "d",
          long = ["directory"],
          desc = ReqArg(Directory, "DESTDIR"),
          help = "Destination directory for output files"
        },
        {
          short = "",
          long = ["footer"],
          desc = ReqArg(Footer, "HTML"),
          help = "Include footer text for each page"
        },
        {
          short = "",
          long = ["header"],
          desc = ReqArg(Header, "HTML"),
          help = "Include header text for each page"
        },
        {
          short = "h",
          long = ["help"],
          desc = NoArg(Help),
          help = "Display command line options"
        },
        {
          short = "",
          long = ["helpfile"],
          desc = ReqArg(HelpFile, "HELPFILE"),
          help = "Include file that help link links to"
        },
        {
          short = "",
          long = ["hidebysig"],
          desc = NoArg(HideBySig),
          help = "Hide elements not specified in signature."
        },
        {
          short = "",
          long = ["link"],
          desc = ReqArg(Link, "URL"),
          help =
          "Create links to javadoc output at URL(only local path supported)"
        },
        {
          short = "",
          long = ["linkoffline"],
          desc = ReqArg(LinkOffline, "URL@LINKFILE"),
          help =
          "Link to docs at URL using module list at LINKFILE"
        },
        {
          short = "",
          long = ["linksource"],
          desc = NoArg(LinkSource),
          help = "Generate source in HTML"
        },
        {
          short = "",
          long = ["listsubmodule"],
          desc = NoArg(ListSubModule),
          help = "Include submodules in module list"
        },
        {
          short = "",
          long = ["nohelp"],
          desc = NoArg(NoHelp),
          help = "Do not generate help link"
        },
        {
          short = "",
          long = ["nonavbar"],
          desc = NoArg(NoNavBar),
          help = "Do not generate navigation bar"
        },
        {
          short = "",
          long = ["noindex"],
          desc = NoArg(NoIndex),
          help = "Do not generate index"
        },
        {
          short = "",
          long = ["nowarn"],
          desc = NoArg NoWarning,
          help = "Suppress warning message."
        },
        {
          short = "",
          long = ["overview"],
          desc = ReqArg(Overview, "FILE"),
          help = "Read overview documentation from HTML file"
        },
        {
          short = "r",
          long = ["recursive"],
          desc = NoArg(Recursive),
          help = "process CM file recursively"
        },
        {
          short = "s",
          long = ["stdin"],
          desc = NoArg StdIn,
          help = "read filenames from STDIN"
        },
        {
          short = "",
          long = ["showsummary"],
          desc = NoArg ShowSummary,
          help = "show elements summary instead declaration"
        },
        {
          short = "",
          long = ["splitindex"],
          desc = NoArg SplitIndex,
          help = "Split index into one file per letter"
        },
(*
        {
          short = "",
          long = ["use"],
          desc = NoArg(Use),
          help = "Create class and package usage pages"
        },
*)
        {
          short = "t",
          long = ["doctitle"],
          desc = ReqArg(DocTitle, "TITLE"),
          help = "Include title for the package index(first) page"
        },
        {
          short = "v",
          long = ["verbose"],
          desc = NoArg Verbose,
          help = "Output messages about what SMLDoc is doing"
        },
        {
          short = "",
          long = ["version"],
          desc = NoArg Version,
          help = "Include @version paragraphs"
        },
        {
          short = "w",
          long = ["windowtitle"],
          desc = ReqArg(WindowTitle, "TITLE"),
          help = "Browser window title for the documenation"
        }
      ]
  end

  fun parseCommandLine location arguments =
      let
        val (options, sourceFiles, errors) =
            G.getOpt GetOpt.Permute optionDescs arguments
        val _ =
            if not(null errors)
            then
              raise
              InvalidParameter
              (concat
               [location, ":", concat errors,
                G.usageInfo usageHeader optionDescs])
            else ()
(*
        val _ =
            print ("SourceFile: " ^ U.interleaveString ", " sourceFiles ^ "\n")
*)
        val sourceFiles =
            map
                (fn path => PU.makeAbsolute {dir = location, path = path})
                sourceFiles
        val (argFileOptions, otherOptions) =
            List.partition (fn ArgFile _ => true | _ => false) options
        (* convert filepaths in argument of option into its absolute path. *)
        val argFiles =
            map
                (fn ArgFile name =>
                    PU.makeAbsolute {dir = location, path = name})
                argFileOptions
        val otherOptions =
            map
            (fn Overview fileName =>
                Overview(PU.makeAbsolute {dir = location, path = fileName})
              | Directory destination =>
                Directory(PU.makeAbsolute {dir = location, path = destination})
              | other => other)
            otherOptions
(*
        val _ =
            print ("SourceFile: " ^ U.interleaveString ", " sourceFiles ^ "\n")
        val _ =
            print ("ArgFile: " ^ U.interleaveString ", " argFiles ^ "\n")
*)
        val (optionsList', sourceFilesList') =
            ListPair.unzip(map parseArgFile argFiles)
      in
        (
          otherOptions @ List.concat optionsList',
          sourceFiles @ List.concat sourceFilesList'
        )
      end

  and parseArgFile filePath =
      let
        val filePath = PU.makeAbsolute {dir = ".", path = filePath}
        val directory =
            if
              OS.FileSys.isDir filePath
              handle OS.SysErr _ =>
                     raise InvalidParameter (filePath ^ " does not exist.")
            then raise InvalidParameter (filePath ^ " is a directory.")
            else #dir(PU.splitDirFile filePath)
(*
        val _ = print ("Parse argfile: " ^ filePath ^ "\n")
*)
        val inStream = TextIO.openIn filePath
      in
        let
          val contents = TextIO.inputAll inStream
        in
          TextIO.closeIn inStream;
          parseCommandLine directory (U.tokenizeString Char.isSpace contents)
        end
          handle e => (TextIO.closeIn; raise e)
      end

  (**
   * filePath must be absolute path.
   *)
  fun expandFileName (DGP as DGP.Parameter{recursive, ...}) initialFilePath =
      let
        val readCMFileNames = ref []
        fun expand filePath = 
            if CMFileParser.isCMFileName filePath
            then
              if List.exists (fn name => name = filePath) (!readCMFileNames)
              then []
              else
                let
                  val items = CMFileParser.readCMFile DGP filePath
                  val _ = readCMFileNames := filePath :: (!readCMFileNames)
                in
                  if recursive
                  then List.concat (map expand items)
                  else List.filter (not o CMFileParser.isCMFileName) items
                end
            else [filePath]
      in
        expand initialFilePath
      end

  fun main(programName, commandLineArgs) =
      let
        val (options, sourceFiles) = parseCommandLine "." commandLineArgs

        fun findOption getTarget default =
            let
              fun find (option::options) =
                  (case getTarget option of SOME v => v | NONE => find options)
                | find [] = default
            in find options end
        fun findOptions getTarget =
            List.map
                Option.valOf
                (List.filter Option.isSome (List.map getTarget options))

        val links =
            List.concat
            (map
             (fn (Link URL) =>
                 [{
                    URL = URL,
                    linkFile =
                    URL ^ "/" ^ ExternalRefLinker.defaultModuleListFileName
                  }]
               | (LinkOffline URLAndLinkFile) =>
                 (case String.tokens (fn c => c = #"@") URLAndLinkFile of
                    [URL, linkFile] => [{URL = URL, linkFile = linkFile}]
                  | _ =>
                    raise
                      InvalidParameter
                          ("invalid argument of --linkoffline:" ^
                           URLAndLinkFile))
               | _ => [])
             options)
        (* Note : The following code is not efficient, but not problem, because
         * usually user does not specify so much options. *)
        val parameter =
            {
              author =
              findOption (fn Author => SOME true | _ => NONE) false,
              bottom =
              findOption (fn Bottom b => SOME(SOME b) | _ => NONE) NONE,
              builtinTypes =
              findOptions (fn BuiltinType t => SOME(t) | _ => NONE),
              builtinStructures =
              findOptions (fn BuiltinStructure t => SOME(t) | _ => NONE),
              charSet =
              findOption (fn CharSet c => SOME(SOME c) | _ => NONE) NONE,
              contributor =
              findOption (fn Contributor => SOME true | _ => NONE) false,
              copyright =
              findOption (fn Copyright => SOME true | _ => NONE) false,
              directory = 
              findOption (fn Directory d => SOME d | _ => NONE) ".",
              docTitle =
              findOption (fn DocTitle t => SOME(SOME t) | _ => NONE) NONE,
              footer =
              findOption (fn Footer f => SOME(SOME f) | _ => NONE) NONE,
              header =
              findOption (fn Header h => SOME(SOME h) | _ => NONE) NONE,
              help = findOption (fn NoHelp => SOME(false) | _ => NONE) true,
              helpfile =
              findOption (fn HelpFile f => SOME(SOME f) | _ => NONE) NONE,
              hideBySig =
              findOption (fn HideBySig => SOME(true) | _ => NONE) false,
              index = findOption (fn NoIndex => SOME(false) | _ => NONE) true,
              links = links,
              linkSource =
              findOption (fn LinkSource => SOME true | _ => NONE) false,
              listSubModule =
              findOption (fn ListSubModule => SOME true | _ => NONE) false,
              navbar =
              findOption (fn NoNavBar => SOME(false) | _ => NONE) true,
              printWarning =
              findOption (fn NoWarning => SOME(false) | _ => NONE) true,
              overview =
              findOption (fn Overview f => SOME(SOME f) | _ => NONE) NONE,
              recursive =
              findOption (fn Recursive => SOME(true) | _ => NONE) false,
              showSummary = 
              findOption (fn ShowSummary => SOME(true) | _ => NONE) false,
              splitIndex = 
              findOption (fn SplitIndex => SOME(true) | _ => NONE) false,
              uses = findOption (fn Use => SOME(true) | _ => NONE) false,
              verbose = findOption (fn Verbose => SOME true | _ => NONE) false,
              version =
              findOption (fn Version => SOME true | _ => NONE) false,
              windowTitle =
              case
                findOption (fn WindowTitle t => SOME(SOME t) | _ => NONE) NONE
               of
                SOME t => SOME t
              | NONE =>
                findOption (fn DocTitle t => SOME(SOME t) | _ => NONE) NONE
            }

        val DGP = DGP.Parameter parameter

        val sourceFiles =
            List.map
            (fn path =>
                PU.makeAbsolute {dir = OS.FileSys.getDir(), path = path})
            (if findOption (fn StdIn => SOME true | _ => NONE) false
             then
               (U.tokenizeString Char.isSpace (TextIO.inputAll TextIO.stdIn)) @
               sourceFiles
             else sourceFiles)
        val _ = DGP.onProgress
                    DGP
                    ("SourceFiles: " ^ U.interleaveString "," sourceFiles)

        val sourceFiles =
            List.concat(List.map (expandFileName DGP) sourceFiles)
        val _ = DGP.onProgress
                    DGP
                    ("SourceFiles: " ^ U.interleaveString "," sourceFiles)
      in
        if findOption (fn Help => SOME true | _ => NONE) false
        then print (G.usageInfo usageHeader optionDescs)
        else
          (
            if null sourceFiles
            then raise InvalidParameter "no source files specified."
            else ();
            OS.FileSys.isDir (#directory parameter)
            handle OS.SysErr _ =>
                   raise (InvalidParameter
                              ((#directory parameter) ^ " is not direcotry."));
            SMLDoc.makeDocument DGP sourceFiles
          );
        OS.Process.success
      end
        handle e =>
               let
                 val message =
                     case e of
                       InvalidParameter message => message
                     | e => General.exnMessage e
               in
                 print (message ^ "\n");
                 app
                 (fn history => print ("  " ^ history ^ "\n"))
                 (SMLofNJ.exnHistory e);
                 OS.Process.failure
               end

  (***************************************************************************)

end
