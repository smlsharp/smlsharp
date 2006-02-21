(**
 * Copyright (c) 2006, Tohoku University.
 *
 * identifier of type, term, label and etc.
 * <p>
 * ID is classified to two types.
 * <ul>
 *   <li>static ID</li>
 *   <li>dynamic ID</li>
 * </ul>
 * </p>
 * <p>
 *  Static ID is expected to be allocated only at the initialization of the
 * system. It must be static and unique while the system runs.
 * For example, static ID is allocated for builtin entities, such as
 * bool tyCon and int tyCon.
 * </p>
 * <p>
 *  Dynamic ID is expected to be allocated for dynamically generated entities.
 * To avoid ID space starvation, you can reset ID space by calling
 * the <code>init</code> function.
 * The uniqueness of dynamic ID is not ensured beyond the <code>init</code>.
 * Dynamic ID is allocated for user defined entities.
 * </p>
 * @author YAMATODANI Kiyoshi
 * @version $Id: ID.sig,v 1.7 2006/02/18 04:59:24 ohori Exp $
 *)
signature ID =
sig

  (***************************************************************************)

  eqtype id

  (***************************************************************************)

  structure Map : ORD_MAP
  sharing type id = Map.Key.ord_key

  structure Set : ORD_SET
  sharing type id = Set.Key.ord_key

  (***************************************************************************)

  (**
   * initializes the seed of dynamic ID allocation.
   *)
  val init : unit -> unit

  val format_id : id -> SMLFormat.FormatExpression.expression list

  val toString : id -> string

  val fromInt : int -> id
  val toInt : id -> int

  (**
   * compare two IDs.
   * If id1 < id2, it means that id1 has been allocated before id2.
   *)
  val compare : id * id -> order

  (**
   * allocate a new static unique ID.
   *)
  val reserve : unit -> id

  (**
   * allocate a new dynamic unique ID.
   *)
  val generate : unit -> id

  (**
   * get the dynamic ID which will be returned on the next invocation of
   * the <code>generate</code> function.
   *)
  val peek : unit -> id

  (***************************************************************************)

end;
