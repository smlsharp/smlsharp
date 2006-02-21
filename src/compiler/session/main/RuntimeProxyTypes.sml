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