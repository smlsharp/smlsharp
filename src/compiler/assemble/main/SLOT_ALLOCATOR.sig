(**
 * Copyright (c) 2006, Tohoku University.
 *
 * This module allocates frame slots for local variables.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SLOT_ALLOCATOR.sig,v 1.5 2006/02/18 04:59:16 ohori Exp $
 *)
signature SLOT_ALLOCATOR =
sig

  (***************************************************************************)

  val SLOTS_OF_POINTER_VAR : BasicTypes.UInt32
  val SLOTS_OF_ATOM_VAR : BasicTypes.UInt32
  val SLOTS_OF_DOUBLE_VAR : BasicTypes.UInt32
  val SLOTS_OF_RECORD_VAR : BasicTypes.UInt32

  (**
   * allocates a frame slot to each of local variables in a function.
   *)
  val allocate
      : SymbolicInstructions.funInfo * SymbolicInstructions.instruction list
        -> SymbolicInstructions.instruction list
           * AllocationInfo.frameAllocationInfo

  (***************************************************************************)

end
