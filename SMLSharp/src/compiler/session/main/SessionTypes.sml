(**
 * This module declares a type of operations which communicate with an instance
 * of the runtime.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SessionTypes.sml,v 1.10 2007/12/19 04:45:37 katsu Exp $
 *)
structure SessionTypes =
struct

  type asmOutput = (string -> unit) -> unit

  (**
   * result of compilation for each compilation unit.
   *)
  datatype compileResult =
      CODEBLOCK of Word8Vector.vector      (* for Yamatodani's runtime *)
    | OBJECTFILE of ObjectFile.objectFile  (* for Ueno's runtime *)
    | ASMFILE of asmOutput                 (* for native code *)

  (***************************************************************************)

  (**
   * operations which communicate with an instance of the runtime.
   *)
  type Session =
       {
         (** executes a code block. *)
         execute : compileResult -> unit,

         (** close the session. *)
         close : unit -> unit
       }

  (***************************************************************************)

  (** recoverable error *)
  exception Failure of exn

  (** unrecoverable error *)
  exception Fatal of exn

  (** user requests to 'exit' process. *)
  exception Exit of BasicTypes.SInt32

  (***************************************************************************)

end
