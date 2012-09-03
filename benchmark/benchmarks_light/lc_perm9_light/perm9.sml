fun ! (ref x) = x
fun hd (h::t) = h | hd nil = raise Fail ""
fun tl (h::t) = t | tl nil = raise Fail ""
fun length [] = 0
  | length list =
    let
      fun scan [] result = result
        | scan (_ :: tail) len = scan tail (len + 1)
    in scan list 0 end

(*
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; File:         perm9.sch
; Description:  memory system benchmark using Zaks's permutation generator
; Author:       Lars Hansen, Will Clinger, and Gene Luks
; Created:      18-Mar-94
; Language:     Scheme
; Status:       Public Domain
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; 940720 / lth Added some more benchmarks for the thesis paper.
; 970215 / wdc Increased problem size from 8 to 9; improved tenperm9-benchmark.
; 970531 / wdc Cleaned up for public release.
; 981116 / wdc Simplified to fit in with Feeley's benchmark suite.
; 990624 / wdc Translated into Standard ML

; The perm9 benchmark generates a list of all 362880 permutations of
; the first 9 integers, allocating 1349288 pairs (typically 10,794,304
; bytes), all of which goes into the generated list.  (That is, the
; perm9 benchmark generates absolutely no garbage.)  This represents
; a savings of about 63% over the storage that would be required by
; an unshared list of permutations.  The generated permutations are
; in order of a grey code that bears no obvious relationship to a
; lexicographic order.
;
; The 10perm9 benchmark repeats the perm9 benchmark 10 times, so it
; allocates and reclaims 13492880 pairs (typically 107,943,040 bytes).
; The live storage peaks at twice the storage that is allocated by the
; perm9 benchmark.  At the end of each iteration, the oldest half of
; the live storage becomes garbage.  Object lifetimes are distributed
; uniformly between 10.3 and 20.6 megabytes.

; Date: Thu, 17 Mar 94 19:43:32 -0800
; From: luks@sisters.cs.uoregon.edu
; To: will
; Subject: Pancake flips
; 
; Procedure P_n generates a grey code of all perms of n elements
; on top of stack ending with reversal of starting sequence
; 
; F_n is flip of top n elements.
; 
; 
; procedure P_n
; 
;   if n>1 then
;     begin
;        repeat   P_{n-1},F_n   n-1 times;
;        P_{n-1}
;     end
; 
*)

fun permutations x0 =
  let val x = ref x0
      val perms = ref [x0]
      fun P n =
        if n > 1
          then let fun loop j =
                      if j = 0
                        then P (n - 1)
                        else ( P (n - 1);
                               F n;
                               loop (j - 1) )
               in loop (n - 1)
               end
          else ()
      and F n =
        ( x := revloop (!x, n, list_tail (!x, n));
          perms := !x :: !perms )
      and revloop (x, n, y) =
        if n = 0
          then y
          else revloop (tl x, n - 1, (hd x) :: y)
      and list_tail (x, n) =
        if n = 0
          then x
          else list_tail (tl x, n - 1)
  in (P (length (!x)); !perms)
  end

(*
; Given a list of lists of numbers, returns the sum of the sums
; of those lists.
;
; for (; x != NULL; x = x->rest)
;     for (y = x->first; y != NULL; y = y->rest)
;         sum = sum + y->first;
*)

fun sumlists x =
  let fun loop1 (x, sum) =
        if x = []
          then sum
          else let fun loop2 (y, sum) =
                     if y = []
                       then sum
                       else loop2 (tl y, sum + (hd y))
               in loop1 (tl x, loop2 (hd x, sum))
               end
  in loop1 (x, 0)
  end

val perms : int list list ref = ref []

fun one2n n =
  let fun loop (n, p) =
        if n = 0
          then p
          else loop (n - 1, n :: p)
  in loop (n, [])
  end

fun perm9_benchmark (m, n : int) =
  let fun factorial n =
        if n = 1
          then 1
          else n * factorial (n - 1)
  in run_benchmark ("perm9" (*concat ([Int.toString (m), "perm", Int.toString (n)])*),
                    1,
                    fn () =>
                      ( perms := permutations (one2n n);
                        let fun loop m =
                              if m = 0
                                then !perms
                                else ( perms := permutations (hd (!perms));
                                       loop (m - 1) )
                        in loop m
                        end ),
                    fn (result) =>
                      (sumlists result)
                        = Int.quot ((n * (n + 1) * factorial (n)), 2))
  end

fun main () = perm9_benchmark (5, 9)
