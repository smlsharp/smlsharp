(**
 * Copyright (c) 2006, Tohoku University.
 *
 * This module declares a type of operations which communicate with an instance
 * of the runtime.
 *
 * @author YAMATODANI Kiyoshi
 * @version $Id: SessionTypes.sml,v 1.4 2006/02/18 04:59:28 ohori Exp $
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
