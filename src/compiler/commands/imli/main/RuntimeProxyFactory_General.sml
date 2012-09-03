structure RuntimeProxyFactory =
struct

  val name = "General"

(*
  val runtimePath = "../../../../../obj/c/bin/imlrun.exe"
*)
(*
  val runtimePath = "..\\..\\..\\..\\..\\obj\\c\\bin\\imlrun.exe"
*)
  val runtimePath = 
      Configuration.DevelopmentRoot ^ "/obj/c/bin/imlrun.exe"

  val port = 12345;

  fun createInstance () =
      NetworkRuntimeProxy.initialize
          {
            runtimePath = runtimePath,
            port = 12345
          }

end
