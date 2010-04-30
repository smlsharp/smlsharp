(* bit-vector-sig.sml
 *
 * COPYRIGHT (c) 1995 by AT&T Bell Laboratories.  See COPYRIGHT file for details.
 *
 *)

signature BIT_VECTOR =
  sig
    include MONO_VECTOR
(**
      where type elem = bool
**)

    val fromString : string -> vector
      (* The string argument gives a hexadecimal
       * representation of the bits set in the
       * vector. Characters 0-9, a-f and A-F are
       * allowed. For example,
       *  fromString "1af8" = 0001101011111000
       *  (by convention, 0 corresponds to false and 1 corresponds
       *  to true, bit 0 appears on the right,
       *  and indices increase to the left)
       * The length of the vector will be 4*(size string).
       * Raises LibBase.BadArg if a non-hexadecimal character
       * appears in the string.
       *)

    val bits : (int * int list) -> vector
      (* Create vector of the given length with the indices of its set bits 
       * given by the list argument.
       * Raises Subscript if a list item is < 0 or >= length.
       *)

    val getBits : vector -> int list
      (* Returns list of bits set in bit array, in increasing
       * order of indices.
       *)

    val toString : vector -> string
      (* Inverse of stringToBits.
       * The bit array is zero-padded to the next
       * length that is a multiple of 4. 
       *)

    val isZero  : vector -> bool
      (* Returns true if and only if no bits are set. *)

    val extend0 : (vector * int) -> vector
    val extend1 : (vector * int) -> vector
      (* Extend bit array by 0's or 1's to given length.
       * If bit array is already >= argument length, return a copy
       * of the bit array.
       * Raises Size if length < 0.
       *)

    val eqBits : (vector * vector) -> bool
      (* true if set bits are identical *)
    val equal : (vector * vector) -> bool
      (* true if same length and same set bits *)

    val andb : (vector * vector * int) -> vector
    val orb  : (vector * vector * int) -> vector
    val xorb : (vector * vector * int) -> vector
      (* Create new vector of the given length
       * by logically combining bits of original 
       * vectors using and, or and xor, respectively. 
       * If necessary, the vectors are
       * implicitly extended by 0 to be the same length 
       * as the new vector.
       *)

    val notb  : vector -> vector
      (* Create new vector with all bits of original
       * vector inverted.
       *)

    val lshift  : (vector * int) -> vector
      (* lshift(ba,n) creates a new vector by
       * inserting n 0's on the right of ba.
       * The new vector has length n + length ba.
       *)

    val rshift  : (vector * int) -> vector
      (* rshift(ba,n) creates a new vector of
       * of length max(0,length ba - n) consisting
       * of bits n,n+1,...,length ba - 1 of ba.
       * If n >= length ba, the new vector has length 0.
       *)

  end
    where type elem = bool
