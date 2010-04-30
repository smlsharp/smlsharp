structure RuntimeProxyFactory =
struct

  val name = "General"

  val runtimePath = Configuration.RuntimePath 

  val port = 12345;

  fun createInstance () =
      NetworkRuntimeProxy.initialize
          {
            runtimePath = runtimePath,
            arguments = [],
            port = 12345
          }

end
