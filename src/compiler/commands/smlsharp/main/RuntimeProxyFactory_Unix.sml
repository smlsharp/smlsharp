(**
 * Copyright (c) 2006, Tohoku University.
 *)
structure RuntimeProxyFactory =
struct

  val name = "Unix"

  val runtimePath = Configuration.RuntimePath

  fun createInstance () =
      UnixProcessRuntimeProxy.initialize {runtimePath = runtimePath}

end
