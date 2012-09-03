functor MakeLocalID () =
struct
local
  val state = ref 0
in
  type id = int
  val format_id = SMLFormat.BasicFormatters.format_int
  fun toString elementID = Int.toString elementID
  val compare = Int.compare
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () =  !state before state := !state + 1
  fun toInt id =  id
  structure IDOrd =
  struct 
    type ord_key = id
    val compare = compare
  end
  structure Map = BinaryMapFn(IDOrd);
  structure Set = BinarySetFn(IDOrd);
end
end 

structure FreeTypeVarID :> LOCAL_ID = MakeLocalID()
structure BoundTypeVarID :> LOCAL_ID = MakeLocalID()
structure ClusterID :> LOCAL_ID = MakeLocalID()
structure ConID :> LOCAL_ID = MakeLocalID()
structure ExnID :> LOCAL_ID = MakeLocalID()
structure ExExnID :> LOCAL_ID = MakeLocalID()
structure InterfaceID :> LOCAL_ID  = MakeLocalID()
structure OPrimID :> LOCAL_ID = MakeLocalID()
structure PrimID :> LOCAL_ID = MakeLocalID()
structure TvarID :> LOCAL_ID = MakeLocalID()
structure TypID :> LOCAL_ID = MakeLocalID()
structure VarID :> LOCAL_ID = MakeLocalID()
structure FunctionAnnotationID :> LOCAL_ID = MakeLocalID()
structure AnnotationLabelID :> LOCAL_ID = MakeLocalID()
structure RevealID :> LOCAL_ID = MakeLocalID()
structure VarName = struct
local
  structure VarNameID = MakeLocalID()
in
  type id = VarNameID.id
  fun generate () =
      let
        val id = VarNameID.generate ()
      in
        "$" ^ (VarNameID.toString id)
      end
end
end

