(**
 *)
functor makeID () =
struct

  type id = int

  val format_id = SMLFormat.BasicFormatters.format_int

  fun toString elementID =
      Int.toString elementID

  fun compare (leftElementID, rightElementID) =
      Int.compare (leftElementID, rightElementID)
      
  fun eq (id1, id2) = 
      case compare (id1, id2) of
          EQUAL => true
        | _ => false

  val initialID = 0

  val initialReservedID = ~1

  fun nextID currentID = 
      currentID + 1

  fun nextNthID currentID n  = 
      currentID + n

  fun nextReservedID currentReservedID = 
      currentReservedID - 1 

  fun nextNthReservedID currentReservedID n =
      currentReservedID - n
      
  val pu_ID = Pickle.int 

  (***************************************************************************)
  structure IDOrd =
  struct 
    type ord_key = id
    val compare = compare
  end

  structure Map = BinaryMapMaker(IDOrd);

  structure Set = BinarySetMaker(IDOrd);

  fun isEqual (id1, id2) =
      case IDOrd.compare (id1, id2) of
          EQUAL => true
        | _ => false

  fun toInt id = id
  fun fromInt id = id
  (***************************************************************************)

end :> ID

structure TyConID = makeID()
structure ExnTagID = makeID()
structure FreeTypeVarID = makeID()

structure ExternalVarID = makeID()
structure LocalVarID = makeID()
structure VarNameID = makeID()
structure ClusterID = makeID()


