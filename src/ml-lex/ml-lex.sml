val status = ExportLexGen.lexGen (CommandLine.name (), CommandLine.arguments ())
val () = OS.Process.exit status
