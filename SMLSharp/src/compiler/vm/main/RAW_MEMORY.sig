(**
 * abstraction of memory.
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: RAW_MEMORY.sig,v 1.8 2006/02/28 16:11:13 kiyoshiy Exp $
 *)
signature RAW_MEMORY =
sig

  (***************************************************************************)

  (** pointer to a location in the memory. *)
  type 'a pointer

  (***************************************************************************)

  (** creates and initialize a memory area. *)
  val initialize : ('a * BasicTypes.UInt32) -> 'a pointer

  (** seek a pointer to the specified offset from start of the memory. *)
  val seek : ('a pointer * int) -> 'a pointer

  (** advane a pointer by specified offset. *)
  val advance : ('a pointer * BasicTypes.UInt32) -> 'a pointer

  (** back a pointer by specified offset. *)
  val back : ('a pointer * BasicTypes.UInt32) -> 'a pointer

  (** get offset of the pointer from start of the memory. *)
  val offset : 'a pointer -> BasicTypes.UInt32

  (** get the value in the location pointed by a pointer. *)
  val load : 'a pointer -> 'a

  (** store a value into the location pointed by a pointer. *)
  val store : ('a pointer * 'a) -> unit

  (** get the number of cells between two pointers. *)
  val distance : ('a pointer * 'a pointer) -> BasicTypes.UInt32

  (** compare offsets of two pointer values. *)
  val < : ('a pointer * 'a pointer) -> bool

  (** compare offsets of two pointer values. *)
  val > : ('a pointer * 'a pointer) -> bool

  (** compare offsets of two pointer values. *)
  val <= : ('a pointer * 'a pointer) -> bool

  (** compare offsets of two pointer values. *)
  val >= : ('a pointer * 'a pointer) -> bool

  (** compare offsets of two pointer values. *)
  val == : ('a pointer * 'a pointer) -> bool

  (** compare offsets of two pointer values. *)
  val compare : ('a pointer * 'a pointer) -> General.order

  (** get textual representation of a pointer. *)
  val toString : 'a pointer -> string

  (** apply a function to each location between two locations pointed
   * by ponters.
   * @params (bp, ep) f
   * @param bp a pointer to the begin of the area
   * @param ep a pointer to the NEXT cell to the end of the area
   * @param f the applied function
   *)
  val map : ('a pointer * 'a pointer) -> ('a pointer -> 'b) -> 'b list

  (***************************************************************************)

end
