functor MakeGlobalID (val initialID : int) =
struct

  type id = int

  val format_id = SMLFormat.BasicFormatters.format_int

  fun toString elementID = Int.toString elementID

  val compare = Int.compare
      
  fun eq (id1, id2) = 
      case compare (id1, id2) of
          EQUAL => true
        | _ => false

  val pu_ID = Pickle.int 

  structure IDOrd =
  struct 
    type ord_key = id
    val compare = compare
  end
  structure Map = BinaryMapMaker(IDOrd);
  structure Set = BinarySetMaker(IDOrd);

  fun toInt id = id
  fun fromInt id = id

  local
    val state = ref (SOME initialID)
  in
      fun init stamp = state := SOME stamp
      fun generate () = 
        case !state of
          NONE => raise Control.Bug "counter uninitialized"
        | SOME id => id before state := SOME (id + 1)
      fun advance count =
        case !state of
          NONE => raise Control.Bug "counter uninitialized"
        | SOME id => state := SOME (id + count)
      fun peekNth n =
        case !state of
          NONE => raise Control.Bug "counter uninitialized"
        | SOME id => id + n
      fun reset () =
        case !state of
          NONE => raise Control.Bug "counter uninitialized"
        | SOME id => id  before state := NONE
    end
end 

structure OPrimID :> GLOBAL_ID = MakeGlobalID(val initialID = 0)
structure TyConID :> GLOBAL_ID = MakeGlobalID(val initialID = 0)
structure BoundTypeVarID : GLOBAL_ID = MakeGlobalID(val initialID =  0)
structure ExnTagID :> GLOBAL_ID =
  MakeGlobalID(val initialID = Constants.TAG_exn_MAX)
structure ExternalVarID :> GLOBAL_ID = MakeGlobalID(val initialID = 0)
structure ClusterID :> GLOBAL_ID = MakeGlobalID(val initialID = 0)
