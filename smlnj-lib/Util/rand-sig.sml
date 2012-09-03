(* rand-sig.sml
 *
 * COPYRIGHT (c) 1993 by AT&T Bell Laboratories. See COPYRIGHT file for details.
 * COPYRIGHT (c) 1998 by AT&T Laboratories.
 *
 * Signature for a simple random number generator.
 *
 *)

signature RAND =
  sig

    type rand = Word31.word

    val randMin : rand
    val randMax : rand

    val random : rand -> rand
      (* Given seed, return value randMin <= v <= randMax
       * Iteratively using the value returned by random as the
       * next seed to random will produce a sequence of pseudo-random
       * numbers.
       *)

    val mkRandom : rand -> unit -> rand
      (* Given seed, return function generating a sequence of
       * random numbers randMin <= v <= randMax
       *)

    val norm : rand -> real
      (* Map values in the range [randMin,randMax] to (0.0,1.0) *)

    val range : (int * int) -> rand -> int 
      (* Map v, randMin <= v <= randMax, to integer range [i,j]
       * Exception -
       *   Fail if j < i
       *)

  end (* RAND *)

