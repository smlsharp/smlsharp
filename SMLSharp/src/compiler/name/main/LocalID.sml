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
  val pu_ID = Pickle.int 
  fun toInt id =  id
  structure IDOrd =
  struct 
    type ord_key = id
    val compare = compare
  end
  structure Map = BinaryMapMaker(IDOrd);
  structure Set = BinarySetMaker(IDOrd);
  fun reset () = state := 0
end
end :> LOCAL_ID

structure FreeTypeVarID = MakeLocalID()
structure VarName =
struct
local
  structure VarNameID = MakeLocalID()
in
  type id = VarNameID.id
  fun reset () = VarNameID.reset()
  fun generate () =
      let
        val id = VarNameID.generate ()
      in
        "$" ^ (VarNameID.toString id)
      end
end
end

(* ids of the ID calculus *)
structure VarID = MakeLocalID() (* variables *)
structure TypID = MakeLocalID() (* variables *)
structure ExnID = MakeLocalID() (* variables *)
structure ConID = MakeLocalID() (* variables *)
structure StrID = MakeLocalID() (* variables *)


