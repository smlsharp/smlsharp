signature RTLASMGEN =
sig

  structure Target : sig
    type program
    type nextDummy
  end

  val generate : {code: Target.program, nextDummy: Target.nextDummy}
                 -> {code: SessionTypes.asmOutput,
                     nextDummy: SessionTypes.asmOutput option}

end
