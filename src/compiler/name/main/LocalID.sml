(* 2015-09-26. Ad-hoc fix to seepd up compilation
*)

structure FreeTypeVarID = GenID
structure BoundTypeVarID = GenID
structure ClusterID = GenID
structure ConID = GenID
structure ExnID = GenID
structure InterfaceID  = GenID
structure OPrimID = GenID
structure PrimID = GenID
structure TvarID = GenID
structure TypID = GenID
structure VarID = GenID
structure SlotID = GenID
structure StructureID = GenID
structure FunctorID = GenID
structure FunctionAnnotationID = GenID
structure AnnotationLabelID = GenID
structure RevealID = GenID
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

