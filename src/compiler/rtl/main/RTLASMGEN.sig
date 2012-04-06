signature RTLASMGEN =
sig

  structure Target : sig
    type program
  end

  val generate : Target.program -> (string -> unit) -> unit

  val generateTerminator : RTLBackendContext.context
                           -> ((string -> unit) -> unit) option

end
