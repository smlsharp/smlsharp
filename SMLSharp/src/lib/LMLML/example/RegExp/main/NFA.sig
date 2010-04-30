(* fsm.sml
 *
 * COPYRIGHT (c) 1998 Bell Labs, Lucent Technologies.
 * 
 * Non-deterministic and deterministic finite-state machines.
 *)


signature NFA = 
    sig

	exception SyntaxNotHandled

	structure IntSet : ORD_SET where type Key.ord_key = int

	type nfa

	val build : RegExpSyntax.syntax * int -> nfa
	val buildPattern : RegExpSyntax.syntax list -> nfa
	val start : nfa -> IntSet.set
	val move : nfa -> int * MBChar.char -> IntSet.set
	val chars : nfa -> int -> MBChar.char list
	val accepting : nfa -> int -> int option

	val print : nfa -> unit
    end

