(**
 *
 * identifier of type, term, label and etc.
 * <p>
 * ID is classified to two types.
 * <ul>
 *   <li>resrved ID</li>
 *   <li>dynamic ID</li>
 * </ul>
 * </p>
 * <p>
 * Reserved ID is expected to be allocated only at the initialization of the
 * system. It must be static and unique while the system runs.
 * For example, a reserved ID is allocated for builtin entities, such as
 * bool tyCon and int tyCon.
 * </p>
 * <p>
 * Dynamic ID is expected to be allocated for dynamically generated entities.
 * To avoid ID space starvation, you can reset ID space by calling
 * the <code>init</code> function.
 * The uniqueness of dynamic ID is not ensured beyond the <code>init</code>.
 * Dynamic ID is allocated for user defined entities.
 * </p>
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: ID.sig,v 1.16 2008/11/19 20:04:38 ohori Exp $
 *)
signature ID =
sig
  (***************************************************************************)
  eqtype id
  (***************************************************************************)
  structure Map
    : sig
        include ORD_MAP
        val fromList : (Key.ord_key * 'item) list -> 'item map
        val pu_map
          : (Key.ord_key Pickle.pu * 'value Pickle.pu) -> 'value map Pickle.pu
      end
  sharing type id = Map.Key.ord_key

  structure Set
    : sig
        include ORD_SET
        val pu_set : (Key.ord_key Pickle.pu) -> set Pickle.pu
      end 
  sharing type id = Set.Key.ord_key
  (***************************************************************************)

  val initialID : id
  val initialReservedID : id
  val format_id : id -> SMLFormat.FormatExpression.expression list
  val toString : id -> string
  val pu_ID : id Pickle.pu

  (**
   * compare two IDs.
   * If id1 < id2, it means that id1 has been allocated before id2.
   *)
  val compare : id * id -> order

  (**
   * equality test
   *)
  val eq : id * id -> bool

  (**
   * allocate the next dynamic ID.
   *)
  val nextID : id -> id

  (**
   * allocate the nth next dynamic ID with respect to the given id.
   *)
  val nextNthID : id -> int -> id

  (**
   * allocate the next reserved ID.
   *)
  val nextReservedID : id -> id

  (**
   * allocate the nth next reserved ID with respect to the given id. 
   *)
  val nextNthReservedID : id -> int -> id

  (***************************************************************************)
  val toInt : id -> int
  val fromInt : int -> id
end
