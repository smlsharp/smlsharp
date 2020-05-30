structure Main' =
struct
  val args = ["-B", "../../src", "-c", "-o", "/dev/null", "../../src/compiler/compilePhases/matchcompilation/main/MatchCompiler.sml"] 
  fun doit () = ignore (Main.main ("smlsharp", args))
  fun testit out =
      if Main.main ("smlsharp", args) = OS.Process.success
      then () else TextIO.output (out, "error\n")
end
