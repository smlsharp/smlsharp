(* priority-sig.sml
 *
 * COPYRIGHT (c) 2002 Bell Labs, Lucent Technologies
 *
 * Argument signature for functors that implement priority queues.
 *)

signature PRIORITY =
  sig
    type priority
    val compare : (priority * priority) -> order
    type item
    val priority : item -> priority
  end;

