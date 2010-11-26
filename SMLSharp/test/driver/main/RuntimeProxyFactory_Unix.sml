structure RuntimeProxyFactory =
struct

  val name = "Unix"

  (* relative path from test/bin. *)
  val runtimePath = SMLSharpConfiguration.RuntimePath 

  fun createInstance () =
      UnixProcessRuntimeProxy.initialize
          {runtimePath = runtimePath, arguments = []}

end
