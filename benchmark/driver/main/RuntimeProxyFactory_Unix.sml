structure RuntimeProxyFactory =
struct

  val name = "Unix"

  val runtimePath = RuntimePath.runtimePath

  fun createInstance () =
      UnixProcessRuntimeProxy.initialize
          {runtimePath = runtimePath, arguments = []}

end
