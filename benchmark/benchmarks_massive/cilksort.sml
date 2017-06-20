val cutOff = ref 1024
val size = ref 4194304

val _ = case Option.map Int.fromString (OS.Process.getEnv "CUTOFF") of
          SOME (SOME n) => cutOff := n
        | _ => ()
val _ = case Option.map Int.fromString (OS.Process.getEnv "SIZE") of
          SOME (SOME n) => size := n
        | _ => ()

structure CilkSort =
struct

(*
  (* swap a[i] and a[j] *)
  fun swap a i j =
      let
        val x = Array.sub (a, i) : real
      in
        Array.update (a, i, Array.sub (a, j));
        Array.update (a, j, x)
      end

  (* median of [ a[b], a[(b+e)/2], a[e] ] *)
  fun pivot a b e =
      let
        val x = Array.sub (a, b) : real
        val y = Array.sub (a, Int.quot (b + e, 2))
        val z = Array.sub (a, e)
      in
        if x < y
        then if y < z then y
             else if x < z then z else x
        else if x < z then x
             else if y < z then z else y
      end

  fun separate a b e (k : real) =
      let
        fun filterLeft a b k =
            if Array.sub (a, b) < k then filterLeft a (b+1) k else b
        fun filterRight a e k =
            if Array.sub (a, e) > k then filterRight a (e-1) k else e
        val i = filterLeft a b k
        val j = filterRight a e k
      in
        if i >= j
        then (i - 1, j + 1)
        else (swap a i j; separate a (i+1) (j-1) k)
      end

  (* sort a[b..e] by quick sort *)
  fun quickSort a b e =
      if e <= b then () else
      let
        val p = pivot a b e
        val (i, j) = separate a b e p
      in
        quickSort a b i;
        quickSort a j e;
        ()
      end
*)

  (* copy a[b..e] to d[j..] *)
  fun copy (a : real array) b e d j =
      if e < b then 0
      else (Array.update (d, j, Array.sub (a, b));
            copy a (b+1) e d (j+1))

  (* search for the index of the first element in a[b..e] greater than k.
   * It is assumed that a[b..e] is sorted.
   * If k is greater then any element in a[b..e], e+1 is returned. *)
  fun bsearch a b e k =
      if e < b then e + 1
      else if e = b then if k < Array.sub (a, e) then e else e + 1
      else
        let
          val m = Int.quot (b + e, 2)
          val x = Array.sub (a, m) : real
        in
          if k < x
          then bsearch a b m k
          else bsearch a (m+1) e k
        end

  (* merge sorted two fragments a[b1..e1] and a[b2..e2] into d[k..] *)
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
          val n = bsearch a b2 e2 (Array.sub (a, m))
        in
          if e1 - b1 <= !cutOff then
            (
              merge a b1 m b2 (n-1) d j;
              merge a (m+1) e1 n e2 d (j+(m-b1+1)+(n-b2))
            )
          else
            let
              val t1 = Myth.Thread.create
                         (fn () => merge a b1 m b2 (n-1) d j)
              val _ = merge a (m+1) e1 n e2 d (j+(m-b1+1)+(n-b2))
            in
              Myth.Thread.join t1
            end
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
        if e - b <= !cutOff then
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
          let
            val t1 =
                Myth.Thread.create
                  (fn () =>
                    let
                      val t1 = Myth.Thread.create
                                 (fn () => cilksort a b q1 d j)
                      val _ = cilksort a (q1+1) q2 d (j+(q1-b+1))
                    in
                      Myth.Thread.join t1;
                      merge a b q1 (q1+1) q2 d j
                    end)
            val _ =
                let
                  val t1 = Myth.Thread.create
                             (fn () => cilksort a (q2+1) q3 d (j+(q2-b+1)))
                  val _ = cilksort a (q3+1) e d (j+(q3-b+1))
                in
                  Myth.Thread.join t1;
                  merge a (q2+1) q3 (q3+1) e d (j+(q2-b+1))
                end
          in
            Myth.Thread.join t1;
            merge d b q2 (q2+1) e a b
          end
      end

  fun sort a =
      let
        val len = Array.length a
      in
        cilksort a 0 (len - 1) (Array.array (len, 0.0)) 0;
        a
      end

end



val srand = _import "srand" : word -> ()
val rand = _import "rand" : () -> int
fun randReal () = real (rand ()) / real (rand ())


fun doit () = let (* ------- *)

val _ = srand 0w0
val a = Array.tabulate (!size, fn _ => randReal ())
val _ = CilkSort.sort a
(*
val _ = Array.app (fn x => print ("* " ^ Real.toString x ^ "\n")) a
*)

in () end (* ------- *)

fun rep 0 = ()
  | rep n =
    let val t = Time.now ()
        val () = doit ()
    in print (Time.fmt 6 (Time.- (Time.now (), t))); print "\n";
       rep (n - 1)
    end
val _ = rep 3
