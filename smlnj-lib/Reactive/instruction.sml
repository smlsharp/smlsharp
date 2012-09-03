(* instruction.sml
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *
 * An AST representation of reactive scripts.
 *)

structure Instruction =
  struct

    datatype 'a config
      = posConfig of 'a
      | negConfig of 'a
      | orConfig of ('a config * 'a config)
      | andConfig of ('a config * 'a config)

    type signal = Atom.atom

    datatype 'a instr
      = || of ('a instr * 'a instr)
      | & of ('a instr * 'a instr)
      | nothing
      | stop
      | suspend
      | action of 'a -> unit
      | exec of 'a -> {stop : unit -> unit, done : unit -> bool}
      | ifThenElse of (('a -> bool) * 'a instr * 'a instr)
      | repeat of (int * 'a instr)
      | loop of 'a instr
      | close of 'a instr
      | signal of (signal * 'a instr)
      | rebind of (signal * signal * 'a instr)
      | when of (signal config * 'a instr * 'a instr)
      | trapWith of (signal config * 'a instr * 'a instr)
      | emit of signal
      | await of signal config

  end;
