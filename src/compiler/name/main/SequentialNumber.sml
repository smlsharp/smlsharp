(**
 *
 * sequence number generator.
 *
 * @copyright (c) 2006, Tohoku University.
 * @author YAMATODANI Kiyoshi
 * @version $Id: SequentialNumber.sml,v 1.4 2006/02/27 06:26:14 bochao Exp $
 *)
structure SequentialNumber
  : sig
      type sequence
      val generateSequence : int -> sequence
      val init : sequence -> unit
      val generate : sequence -> int
      val advance : sequence -> int -> unit
      val peek : sequence -> int
    end =
struct

  (***************************************************************************)

  type sequence = {first : int, next : int ref}

  (***************************************************************************)

  fun generateSequence first = {first = first, next = ref first}

  fun peek ({next, ...} : sequence) = !next

  fun generate ({next, ...} : sequence) = 
      !next before next := (!next) + 1

  fun advance ({next, ...} : sequence) count = next := (!next) + count

  fun init ({first, next, ...} : sequence) = next := first

  (***************************************************************************)

end;
