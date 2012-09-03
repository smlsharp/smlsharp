functor MakeGlobalID (val initialID : int val counterName: string) =
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
    val savedState = ref NONE : int option ref
    fun bug s = Control.Bug (counterName ^ ": " ^ s)
  in
      (* resume and terminate are prebileged operations that should only be
       * used by  the main program to dump and recover compiler environments.
       *)
      fun resume stamp = 
          case (!state,!savedState) of
            (NONE, SOME _) => savedState := SOME stamp
          | _ => raise bug "improper use of resume"
      fun terminate () =
          case (!state,!savedState) of
            (NONE,SOME id) => id  before state := NONE
          | _ => raise bug "counter not properly stopped"
      fun stop () =
          case (!state, !savedState) of
            (SOME id, NONE) => (savedState := SOME id; state := NONE)
          | _ => raise bug "counter already stopped" 
      fun start () = 
          case (!state, !savedState) of
            (NONE, SOME id) => (state := SOME id; savedState := NONE)
          | _ => raise bug "counter already started" 
      fun generate () = 
        case !state of
          NONE => raise bug "counter stopped"
        | SOME id => id before state := SOME (id + 1)
      fun advance count =
        case !state of
          NONE => raise bug "counter stopped"
        | SOME id => state := SOME (id + count)
      fun peekNth n =
        case !state of
          NONE => raise bug "counter stopped"
        | SOME id => id + n
  end
end 

structure OPrimID :> GLOBAL_ID =
  MakeGlobalID(val initialID = 0 val counterName = "OPrimID")
structure TyConID :> GLOBAL_ID =
  MakeGlobalID(val initialID = 0 val counterName = "TyConID")
structure BoundTypeVarID : GLOBAL_ID =
  MakeGlobalID(val initialID =  0 val counterName = "BoundTypeVarID")
structure ExnTagID :> GLOBAL_ID =
  MakeGlobalID(val initialID = Constants.TAG_exn_MAX
               val counterName = "ExnTagID"
              )
structure ExternalVarID :> GLOBAL_ID =
  MakeGlobalID(val initialID = 0 val counterName = "ExternalVarID")
structure ClusterID :> GLOBAL_ID =
  MakeGlobalID(val initialID = 0 val counterName = "ClusterID")

structure GlobalCounters =
struct
  fun stop () = 
      (
       OPrimID.stop();
       TyConID.stop();
       BoundTypeVarID.stop();
       ExnTagID.stop();
       ExternalVarID.stop();
       ClusterID.stop()
      )
end
