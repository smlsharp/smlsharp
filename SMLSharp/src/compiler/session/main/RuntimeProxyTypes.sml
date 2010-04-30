(**
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: RuntimeProxyTypes.sml,v 1.2 2007/02/24 09:22:23 kiyoshiy Exp $
 *)
structure RuntimeProxyTypes =
struct

  (***************************************************************************)

  (**
   * a proxy of a IML runtime instance.
   *)
  type Proxy =
       {
         (** a channel to receive messages from the runtime. *)
         inputChannel : ChannelTypes.InputChannel,

         (** a channel to send messages to the runtime. *)
         outputChannel : ChannelTypes.OutputChannel,

         (** send an interruption message to the runtime. *)
         sendInterrupt : unit -> unit,

         (** release the runtime. *)
         release : unit -> unit
       }

  (***************************************************************************)

  exception Error of string

  (***************************************************************************)

end;