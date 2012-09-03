(**
 * x86 RTL
 * @copyright (c) 2009, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: $
 *)

signature RTLEMIT = sig

  structure Target : sig
    type reg
    type instruction
  end

  type env =
      {
        regAlloc: Target.reg LocalVarID.Map.map,  (* var id -> reg *)
        slotIndex: int LocalVarID.Map.map,        (* slot id -> offset *)
        preFrameOrigin: int,
        postFrameOrigin: int,
        frameAllocSize: int
      }

  val emit : env ClusterID.Map.map -> RTL.program -> Target.instruction list
(*
  val emitData : RTL.symbolDef -> Target.instruction list
*)

  val formatOf : RTL.ty -> RTL.format

end
