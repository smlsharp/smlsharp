structure RuntimeProxyFactory =
struct

  val name = "General"

  val runtimePath = Configuration.RuntimePath 

  val port = 12345

  fun createInstance runtimePath arguments =
      NetworkRuntimeProxy.initialize
          {
            runtimePath = runtimePath,
            arguments = arguments,
            port = port
          }

end
