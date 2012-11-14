(******************************************************************************
* File:         puzzle.sch
* Description:  PUZZLE benchmark
* Author:       Richard Gabriel, after Forrest Baskett
* Created:      12-Apr-85
* Modified:     12-Apr-85 14:20:23 (Bob Shaw)
*               11-Aug-87 (Will Clinger)
*               22-Jan-88 (Will Clinger)
*               30-Mar-92 (Will Clinger -- empty list counts as true)
*               5-May-94  (Will Clinger -- translated into SML)
* Language:     Standard ML
* Status:       Public Domain
******************************************************************************)

val size = 511
val classmax = 3
val typemax = 12

val iii = ref 0
val kount = ref 0
val d = 8

fun start () =
let open Array
    val piececount = tabulate (classmax + 1, fn i => 0)
    val class = tabulate (typemax + 1, fn i => 0)
    val piecemax = tabulate (typemax + 1, fn i => 0)
    val puzzle = tabulate (size + 1, fn i => true)
    val p = tabulate (typemax + 1,
                      fn i => tabulate (size + 1,
                                        fn i => false))

    fun fit (i, j) =
      let val endd = sub (piecemax, i)
          fun loop k =
            if (k > endd)
               orelse ((sub (sub (p, i), k))
                       andalso sub (puzzle, j + k))
              then (k > endd)
              else loop (k + 1)
      in loop 0
      end

    fun place (i, j) =
      let val endd = sub (piecemax, i)
          fun loop1 k =
            if k > endd
              then ()
              else (if sub (sub (p, i), k)
                      then update (puzzle, j + k, true)
                      else ();
                    loop1 (k + 1))
          fun loop2 k =
            if (k > size) orelse not (sub (puzzle, k))
              then ((* print "\nPuzzle filled"; *)
                    if k > size then 0 else k)
              else loop2 (k + 1)
      in (loop1 0;
          update (piececount,
                  sub (class, i),
                  sub (piececount, sub (class, i)) - 1);
          loop2 j)
      end

    fun puzzle_remove (i, j) =
      let val endd = sub (piecemax, i)
          fun loop k =
            if k > endd
              then ()
              else (if sub (sub (p, i), k)
                      then update (puzzle, j + k, false)
                      else ();
                    loop (k + 1))
      in (loop 0;
          update (piececount,
                  sub (class, i),
                  sub (piececount, sub (class, i)) + 1))
      end

(*
 *  fun trial_output (x:int, y:int) =
 *    (print "\nPiece ";
 *     print (Int.toString x);
 *     print " at ";
 *     print(Int.toString y);
 *     print ".")
 *)

    fun trial j =
      let val k = ref 0
          fun loop i =
            if i > typemax
              then (kount := !kount + 1;
                    false)
              else if not (0 = sub (piececount, sub (class, i)))
                     then if fit (i, j)
                            then (k := place (i, j);
                                  if (trial (!k)) orelse (!k = 0)
                                    then ( (* trial_output (i+1, !k+1);
                                            *)
                                          kount := !kount + 1;
                                          true)
                                    else (puzzle_remove (i, j);
                                          loop (i + 1)))
                            else loop (i + 1)
                     else loop (i + 1)
      in loop 0
      end

    fun definePiece (iclass, ii, jj, kk) =
      let val index = ref 0
          fun loopi i =
            if i > ii
              then ()
              else (let fun loopj j =
                          if j > jj
                            then ()
                            else (let fun loopk k =
                                        if k > kk
                                          then ()
                                          else (index := i + d * (j + (d * k));
                                                update (sub (p, !iii),
                                                        !index,
                                                        true);
                                                loopk (k + 1))
                                  in loopk 0
                                  end;
                                  loopj (j + 1))
                    in loopj 0
                    end;
                    loopi (i + 1))
      in (loopi 0;
          update (class, !iii, iclass);
          update (piecemax, !iii, !index);
          if not (!iii = typemax)
            then iii := !iii + 1
            else ())
      end

    fun start () =
      let fun loop1 m =
            if m > size
              then ()
              else (update (puzzle, m, true);
                    loop1 (m + 1))
          fun loop2 i =
            if i > 5
              then ()
              else (let fun loopj j =
                          if j > 5
                            then ()
                            else (let fun loopk k =
                                        if k > 5
                                          then ()
                                          else (update (puzzle,
                                                        i +
                                                         (d * (j + (d * k))),
                                                        false);
                                                loopk (k + 1))
                                  in loopk 1
                                  end;
                                  loopj (j + 1))
                    in loopj 1
                    end;
                    loop2 (i + 1))
          fun loop3 i =
            if i > typemax
              then ()
              else (let fun loopm m =
                          if m > size
                            then ()
                            else (update (sub (p, i), m, false);
                                  loopm (m + 1))
                    in loopm 0
                    end;
                    loop3 (i + 1))
      in (kount := 0;

          loop1 0;
          loop2 1;
          loop3 0;
          iii := 0;

          definePiece (0, 3, 1, 0);
          definePiece (0, 1, 0, 3);
          definePiece (0, 0, 3, 1);
          definePiece (0, 1, 3, 0);
          definePiece (0, 3, 0, 1);
          definePiece (0, 0, 1, 3);

          definePiece (1, 2, 0, 0);
          definePiece (1, 0, 2, 0);
          definePiece (1, 0, 0, 2);

          definePiece (2, 1, 1, 0);
          definePiece (2, 1, 0, 1);
          definePiece (2, 0, 1, 1);

          definePiece (3, 1, 1, 1);

          update (piececount, 0, 13);
          update (piececount, 1, 3);
          update (piececount, 2, 1);
          update (piececount, 3, 1);

          let val m = (d * (d + 1)) + 1
              val n = ref 0
          in (if fit (0, m)
                then n := place (0, m)
                else print "\nError.";
              if trial (!n)
                then ((*
                      print "\nSuccess in ";
                      print (Int.toString (!kount));
                      print " trials."
                      *))
                else print "\nFailure.")
          end)
      end
in start()
end

fun run_benchmark x = x
val puzzle_iters = 100

fun puzzle_benchmark (n) =
  run_benchmark ("puzzle", n, fn () => start(), fn (x) => !kount = 2005)

fun main () = puzzle_benchmark (puzzle_iters)

structure Main =
struct
  fun testit out =
      let val (_,_,f,t) = main ()
      in TextIO.output (out, if t (f ()) then "OK\n" else "Fail\n") end
  fun doit () =
      let val (_,n,f,_) = main ()
          fun loop 0 = () | loop n = (f (); loop (n-1))
      in loop n end
end
