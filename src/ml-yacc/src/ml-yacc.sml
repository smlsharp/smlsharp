val status = ExportParseGen.parseGen (CommandLine.name (), CommandLine.arguments ());
val () = OS.Process.exit status
