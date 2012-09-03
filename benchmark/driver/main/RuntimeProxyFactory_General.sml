structure RuntimeProxyFactory =
struct

  val name = "General"

  val runtimePath = RuntimePath.runtimePath

  val port = 12345;

  fun createInstance () =
      NetworkRuntimeProxy.initialize
          {
            runtimePath = runtimePath,
            arguments = [],
            port = port
          }

end
