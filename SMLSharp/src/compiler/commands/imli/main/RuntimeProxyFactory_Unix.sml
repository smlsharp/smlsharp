(**
 * Copyright (c) 2006, Tohoku University.
 *)
structure RuntimeProxyFactory =
struct

  val name = "Unix"

  val runtimePath = 
      Configuration.DevelopmentRoot ^ "/obj/c/bin/imlrun.exe"

  fun createInstance () =
      UnixProcessRuntimeProxy.initialize {runtimePath = runtimePath}

end
