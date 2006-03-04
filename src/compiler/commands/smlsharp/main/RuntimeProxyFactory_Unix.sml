(**
 * Copyright (c) 2006, Tohoku University.
 *)
structure RuntimeProxyFactory =
struct

  val name = "Unix"

  val runtimePath = Configuration.RuntimePath

  fun createInstance runtimePath arguments =
      UnixProcessRuntimeProxy.initialize
          {runtimePath = runtimePath, arguments = arguments}

end
