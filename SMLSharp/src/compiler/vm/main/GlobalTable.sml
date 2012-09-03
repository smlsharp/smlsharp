(**
 * @copyright (c) 2006, Tohoku University.
 *)
local

  open RuntimeTypes
  open BasicTypes
  structure E = Executable
  structure ES = ExecutableSerializer
  structure I = Instructions
  structure RM = RawMemory
  structure P = Primitives
  structure H = Heap
  structure C = Counter
  structure RC = RuntimeCounters
  structure RE = RuntimeErrors
  structure SU = SignalUtility

in
(**
 * runtime table of global binding.
 * @author YAMATODANI Kiyoshi
 * @version $Id: GlobalTable.sml,v 1.5 2006/02/28 16:11:12 kiyoshiy Exp $
 *)
structure GlobalTable 
  : sig

      (***********************************************************************)

      (** a global table *)
      type table

      (***********************************************************************)

      (** initialize the table. *)
      val initialize : (cellValue RM.pointer * UInt32) -> table

      (** get the value of a global. *)
      val get : table -> UInt32 -> cellValue

      (** register a value of a global. *)
      val set : table -> (UInt32 * cellValue) -> unit

      (** tell pointer values to root tracer. *)
      val traceTable : table -> H.rootTracer -> unit

      (***********************************************************************)

    end =
struct

  (***************************************************************************)

  type table = {memory : cellValue RM.pointer, size : UInt32}

  (***************************************************************************)

  fun initialize (memory, count) = {memory = memory, size = count}

  fun get {memory, size} index = RM.load(RM.advance(memory, index))

  fun set {memory, size} (index, value) =
      (
        if size <= index
        then raise RE.InvalidCode "global table index excess"
        else ();
        RM.store(RM.advance (memory, index), value)
      )

  fun traceTable {memory, size} traceRoot =
      (* assume this function is invoked on only the table for boxed values
       *)
      (
        RM.map
        (memory, RM.advance(memory, size))
        (fn pointer => RM.store (pointer, traceRoot (RM.load pointer)));
        ()
      )

  (***************************************************************************)

end (* structure *)

end (* local *)
