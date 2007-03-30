(**
 * This module declares a type of operations which communicate with an instance
 * of the runtime.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SessionTypes.sml,v 1.7 2007/02/28 07:34:08 kiyoshiy Exp $
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

  exception Error of exn
  exception Exit of BasicTypes.SInt32

  (***************************************************************************)

end
