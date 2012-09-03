(**
 * This module declares a type of operations which communicate with an instance
 * of the runtime.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SessionTypes.sml,v 1.8 2007/06/01 09:40:59 kiyoshiy Exp $
 *)
structure SessionTypes =
struct

  (***************************************************************************)

  (**
   * operations which communicate with an instance of the runtime.
   *)
  type Session =
       {
         (** executes a code block. *)
         execute : Word8Vector.vector -> unit,

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
