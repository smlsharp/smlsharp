structure RuntimeProxyFactory =
struct

  val name = "General"

(*
  val runtimePath = "../../../../../obj/c/bin/smlsharprun.exe"
*)
(*
  val runtimePath = "..\\..\\..\\..\\..\\obj\\c\\bin\\smlsharprun.exe"
*)
  val runtimePath = Configuration.RuntimePath 

  val port = 12345;

  fun createInstance () =
      NetworkRuntimeProxy.initialize
          {
            runtimePath = runtimePath,
            port = 12345
          }

end
