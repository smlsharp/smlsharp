fun usage () =
    TextIO.print
    "mlb2use [-d baseDir] [-p pathMapFile] [-e] [-v] MLBfile \n\
    \  -d baseDir      converts paths to relative to baseDir.\n\
    \  -p pathMapFile  uses a path-map file.\n\
    \  -e              excludes absolute paths from output.\n\
    \  -v              runs in verbose mode.\n";

val baseDirOptRef = ref (NONE : string option);
val pathMapFileOptRef = ref (NONE : string option);
val excludeAbsPathRef = ref false;
val verboseRef = ref false;
fun exit code = (OS.Process.exit code; raise Fail "bug");
fun loop ("-d" :: baseDir :: args) = (baseDirOptRef := SOME baseDir; loop args)
  | loop ("-e" :: args) = (excludeAbsPathRef := true; loop args)
  | loop ("-p" :: pathMapFile :: args) =
    (pathMapFileOptRef := SOME pathMapFile; loop args)
  | loop ("-v" :: args) = (verboseRef := true; loop args)
  | loop ("-h" :: args) = (usage(); exit OS.Process.success)
  | loop ("--help" :: args) = (usage(); exit OS.Process.success)
  | loop [MLBFile] = MLBFile
  | loop _ = (usage(); exit OS.Process.failure);
val rootMLBFile = loop (CommandLine.arguments ());

val files =
    MLB2Use.convert
        {
          baseDirOpt = !baseDirOptRef,
          excludeAbsPath = !excludeAbsPathRef,
          pathMapFileOpt = !pathMapFileOptRef,
          rootMLBFile = rootMLBFile,
          verbose = !verboseRef
        };
val _ = List.app (fn file => print ("use \"" ^ file ^ "\";\n")) files;

