val commandLineName = CommandLine.name ()
val commandArgs = CommandLine.arguments ()
val status = Main.main (commandLineName, commandArgs)
val () = OS.Process.exit status
