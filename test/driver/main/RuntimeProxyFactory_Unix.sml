structure RuntimeProxyFactory =
struct

  val name = "Unix"

  (* relative path from test/bin. *)
  val runtimePath = Configuration.RuntimePath 

  fun createInstance () =
      UnixProcessRuntimeProxy.initialize {runtimePath = runtimePath}

end
