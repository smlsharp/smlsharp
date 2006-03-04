(**
 * This module declares a type of operations which communicate with an instance
 * of the runtime.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SessionTypes.sml,v 1.5 2006/02/28 16:11:05 kiyoshiy Exp $
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
         execute : Word8Array.array -> unit,

         (** close the session. *)
         close : unit -> unit
       }

  (***************************************************************************)

  exception Error of exn

  (***************************************************************************)

end
