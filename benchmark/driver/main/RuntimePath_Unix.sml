structure RuntimePath =
struct

  val name = "Unix"

  (* relative path from test/bin. *)
  val runtimePath = Configuration.RuntimePath 
end
