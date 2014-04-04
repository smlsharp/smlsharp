structure FreeTypeVarID = GenIDFun(Empty)
structure BoundTypeVarID = GenIDFun(Empty)
structure ClusterID = GenIDFun(Empty)
structure ConID = GenIDFun(Empty)
structure ExnID = GenIDFun(Empty)
structure InterfaceID  = GenIDFun(Empty)
structure OPrimID = GenIDFun(Empty)
structure PrimID = GenIDFun(Empty)
structure TvarID = GenIDFun(Empty)
structure TypID = GenIDFun(Empty)
structure VarID = GenIDFun(Empty)
structure SlotID = GenIDFun(Empty)
structure StructureID = GenIDFun(Empty)
structure FunctorID = GenIDFun(Empty)
structure FunctionAnnotationID = GenIDFun(Empty)
structure AnnotationLabelID = GenIDFun(Empty)
structure RevealID = GenIDFun(Empty)
structure VarName = 
struct
local
  val state = ref 0
  fun gen () = !state before state := !state + 1
in
  fun generate () =
      let
        val id = gen ()
      in
        "$" ^ (Int.toString id)
      end
end
end

