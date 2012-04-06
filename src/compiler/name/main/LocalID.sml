structure FreeTypeVarID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure BoundTypeVarID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure ClusterID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure ConID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure ExnID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure InterfaceID  = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure OPrimID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure PrimID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure TvarID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure TypID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure VarID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure StructureID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure FunctorID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure FunctionAnnotationID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure AnnotationLabelID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure RevealID = 
struct
local
  val state = ref 0
in
  type id = int
  structure Map = IEnv
  structure Set = ISet
  fun compare x = Int.compare x
  fun eq (id1:id, id2:id) =  id1 = id2
  fun generate () = !state before state := !state + 1
  fun format_id x = SMLFormat.BasicFormatters.format_int x
  fun toString elementID = Int.toString elementID
  fun toInt id =  id
end
end :> LOCAL_ID

structure VarName = struct
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

