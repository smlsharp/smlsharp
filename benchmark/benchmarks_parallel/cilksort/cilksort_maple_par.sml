val args = CommandLine.arguments ()
val repeat = case args of s::_ => valOf (Int.fromString s) | _ => 10
val size = case args of _::s::_ => valOf (Int.fromString s) | _ => 4194304
val cutOff = case args of _::_::s::_ => valOf (Int.fromString s) | _ => 32

(* copy a[b..e] to d[j..] *)
fun copy (a : real array) b e d j =
    if e < b then 0
    else (Array.update (d, j, Array.sub (a, b));
          copy a (b+1) e d (j+1))

(* search for the index of the first element in a[b..e] greater than k.
 * It is assumed that a[b..e] is sorted.
 * If k is greater than any element in a[b..e], e+1 is returned. *)
fun search a b e k =
    if e < b then e + 1
    else if e = b
    then if k < Array.sub (a, e) then e else e + 1
    else
      let
        val m = Int.quot (b + e, 2)
        val x = Array.sub (a, m) : real
      in
        if k < x
        then search a b m k
        else search a (m+1) e k
      end

(* merge two sorted fragments a[b1..e1] and a[b2..e2] into d[k..] *)
fun merge a b1 e1 b2 e2 d j =
    if e1 < b1 then copy a b2 e2 d j
    else if e2 < b2 then copy a b1 e1 d j
    else if e1 - b1 < e2 - b2 then merge a b2 e2 b1 e1 d j
    else if Array.sub (a,e1) <= Array.sub (a,b2)
    then (copy a b1 e1 d j;
          copy a b2 e2 d (j+(e1-b1+1)))
    else if Array.sub (a,e2) <= Array.sub (a,b1)
    then (copy a b2 e2 d j;
          copy a b1 e1 d (j+(e2-b2+1)))
    else
      let
        val m = Int.quot (b1 + e1, 2)
        val n = search a b2 e2 (Array.sub (a, m))
      in
        if e1 - b1 <= cutOff then
          (
            merge a b1 m b2 (n-1) d j;
            merge a (m+1) e1 n e2 d (j+(m-b1+1)+(n-b2))
          )
        else
          (ForkJoin.par
             (fn _ => merge a b1 m b2 (n-1) d j,
              fn _ => merge a (m+1) e1 n e2 d (j+(m-b1+1)+(n-b2)));
           0)
      end

(* sort a[b..e] by using d[j...] as a temporary buffer. *)
fun cilksort a b e d j =
    if e <= b then 0 else
    let
      (* divide the given array into 4 distinct fragments *)
      val q2 = Int.quot (b + e, 2)
      val q1 = Int.quot (b + q2, 2)
      val q3 = Int.quot (q2+1 + e, 2)
    in
      if e - b <= cutOff then
        (
          (* sort each of the fragments *)
          cilksort a b q1 d j;
          cilksort a (q1+1) q2 d (j+(q1-b+1));
          cilksort a (q2+1) q3 d (j+(q2-b+1));
          cilksort a (q3+1) e d (j+(q3-b+1));
          (* merge two of the fragments in the given buffer *)
          merge a b q1 (q1+1) q2 d j;
          merge a (q2+1) q3 (q3+1) e d (j+(q2-b+1));
          (* merge two results back in the given array *)
          merge d b q2 (q2+1) e a b
        )
      else
        (ForkJoin.par
           (fn _ =>
               (ForkJoin.par
                  (fn _ => cilksort a b q1 d j,
                   fn _ => cilksort a (q1+1) q2 d (j+(q1-b+1)));
                merge a b q1 (q1+1) q2 d j),
            fn _ =>
               (ForkJoin.par
                  (fn _ => cilksort a (q2+1) q3 d (j+(q2-b+1)),
                   fn _ => cilksort a (q3+1) e d (j+(q3-b+1)));
                merge a (q2+1) q3 (q3+1) e d (j+(q2-b+1))));
         merge d b q2 (q2+1) e a b)
    end

val pmseed = ref 1
fun pmrand () =
    let val hi = !pmseed div (2147483647 div 48271)
        val lo = !pmseed mod (2147483647 div 48271)
        val test = 48271 * lo - (2147483647 mod 48271) * hi
    in pmseed := (if test > 0 then test else test + 2147483647);
       !pmseed
    end
fun randReal () = real (pmrand ()) / real (pmrand ())

fun init_a () =
    (
      pmseed := 1;
      Array.tabulate (size, fn _ => randReal ())
    )

fun init_d () =
    Array.array (size, 0.0)

fun doit a d =
    (cilksort a 0 (size - 1) d 0; ())

fun rep 0 = ()
  | rep n =
    let val a = init_a ()
        val d = init_d ()
        val t1 = Time.now ()
        val () = doit a d
        val t2 = Time.now ()
(*
        val _ = 
            Array.app
              (fn x => TextIO.output (TextIO.stdErr, Real.toString x ^ "\n"))
              a
*)
        val d1 = Time.toReal t1
        val d2 = Time.toReal t2
    in print (" - {result: 0, time: "
              ^ Real.toString (d2 - d1) ^ "}\n");
       rep (n - 1)
    end

val _ = print (" bench: cilksort_maple_par\n size: "
               ^ Int.toString size ^ "\n cutoff: " ^ Int.toString cutOff
               ^ "\n results:\n")
val _ = rep repeat
