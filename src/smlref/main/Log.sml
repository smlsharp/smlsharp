structure Log = 
struct
  val logFileName = OS.Path.concat(!Config.baseDir,"./SMLRef.log")
  val logFile = if !Config.doLogging
                then ref (SOME (TextIO.openAppend logFileName))
                else ref NONE
  fun startLogging () =
      case !logFile of
        NONE => logFile := (SOME (TextIO.openAppend logFileName))
      | SOME _ => ()
  fun stopLogging () = 
      case !logFile of
        NONE => ()
      | SOME file => (TextIO.closeOut file;
                      logFile := NONE)
  fun log s = 
      case !logFile of
        NONE => ()
      | SOME logFile => 
        TextIO.output (logFile,s)
end
