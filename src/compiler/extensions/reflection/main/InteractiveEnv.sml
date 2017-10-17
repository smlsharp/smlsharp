structure InteractiveEnv =
struct
local
  val currentEnv = ref NONE : NameEvalEnv.topEnv option ref
in
  type staticEnv = ReifiedTerm.topEnv
  exception CurrentEnvironmentNotAvailable
  fun setCurrentEnv env = currentEnv:= SOME env
(*
  fun getCurrentEnv () = 
      case !currentEnv of
        NONE => raise CurrentEnvironmentNotAvailable
      | SOME env => ReifyTopEnv.topEnvToReifiedTopEnv env
*)
  fun printStaticEnv env =
      ReifiedTerm.printTopEnv env
  fun printStructures env =
      ReifiedTerm.printStructureTopEnv env
end
end
