module T = Domainslib.Task

let num_domains = try int_of_string (Sys.getenv "NPROCS") with _ -> 1
let repeat = try int_of_string Sys.argv.(1) with _ -> 10
let size = try int_of_string Sys.argv.(2) with _ -> 4194304
let cutOff = try int_of_string Sys.argv.(3) with _ -> 32
let pool = T.setup_pool ~num_domains:(num_domains - 1)

(* copy a[b..e] to d[j..] *)
let rec copy a b e d j =
    if e < b then ()
    else (Float.Array.set d j (Float.Array.get a b);
          copy a (b+1) e d (j+1))

(* search for the index of the first element in a[b..e] greater than k.
 * It is assumed that a[b..e] is sorted.
 * If k is greater than any element in a[b..e], e+1 is returned. *)
let rec search a b e k =
    if e < b then e + 1
    else if e = b
    then if k < Float.Array.get a e then e else e + 1
    else
      let m = (b + e) / 2 in
      let x = Float.Array.get a m in
      if k < x
      then search a b m k
      else search a (m+1) e k

(* merge two sorted fragments a[b1..e1] and a[b2..e2] into d[k..] *)
let rec merge a b1 e1 b2 e2 d j =
    if e1 < b1 then copy a b2 e2 d j
    else if e2 < b2 then copy a b1 e1 d j
    else if e1 - b1 < e2 - b2 then merge a b2 e2 b1 e1 d j
    else if Float.Array.get a e1 <= Float.Array.get a b2
    then (copy a b1 e1 d j;
          copy a b2 e2 d (j+(e1-b1+1)))
    else if Float.Array.get a e2 <= Float.Array.get a b1
    then (copy a b2 e2 d j;
          copy a b1 e1 d (j+(e2-b2+1)))
    else
      let m = (b1 + e1) / 2 in
      let n = search a b2 e2 (Float.Array.get a m) in
      if e1 - b1 <= cutOff then
        (
          merge a b1 m b2 (n-1) d j;
          merge a (m+1) e1 n e2 d (j+(m-b1+1)+(n-b2))
        )
      else
        let t1 = T.async pool (fun _ -> merge a b1 m b2 (n-1) d j) in
        merge a (m+1) e1 n e2 d (j+(m-b1+1)+(n-b2));
        T.await pool t1

(* sort a[b..e] by using d[j...] as a temporary buffer. *)
let rec cilksort a b e d j =
    if e <= b then () else
    (* divide the given array into 4 distinct fragments *)
    let q2 = (b + e) / 2 in
    let q1 = (b + q2) / 2 in
    let q3 = (q2+1 + e) / 2 in
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
      let t1 =
          T.async
            pool
            (fun _ ->
                 let t1 = T.async pool (fun _ -> cilksort a b q1 d j) in
                 cilksort a (q1+1) q2 d (j+(q1-b+1));
                 T.await pool t1;
                 merge a b q1 (q1+1) q2 d j) in
      let t2 = T.async pool (fun _ -> cilksort a (q2+1) q3 d (j+(q2-b+1))) in
      cilksort a (q3+1) e d (j+(q3-b+1));
      T.await pool t2;
      merge a (q2+1) q3 (q3+1) e d (j+(q2-b+1));
      T.await pool t1;
      merge d b q2 (q2+1) e a b

let pmseed = ref 1
let pmrand () =
    let hi = !pmseed / (2147483647 / 48271) in
    let lo = !pmseed mod (2147483647 / 48271) in
    let test = 48271 * lo - (2147483647 mod 48271) * hi in
    pmseed := (if test > 0 then test else test + 2147483647);
    !pmseed
let randReal () = float (pmrand ()) /. float (pmrand ())

let init_a () =
    pmseed := 1;
    Float.Array.init size (fun _ -> randReal ())

let init_d () =
    Float.Array.make size 0.0

let doit a d =
    cilksort a 0 (size - 1) d 0

let rec rep n =
    match n with
    | 0 -> ()
    | n ->
      let a = init_a () in
      let d = init_d () in
      let t1 = Unix.gettimeofday () in
      let () = doit a d in
      let t2 = Unix.gettimeofday () in
(*
      Float.Array.iter (fun x -> Printf.eprintf "%f\n" x) a;
*)
      Printf.printf " - {result: %d, time: %.6f}\n" 0 (t2 -. t1);
      rep (n - 1)

let _ = Printf.printf
          " bench: cilksort_ocaml_domainslib\n size: %d\n cutoff: %d\n results:\n"
          size
          cutOff
let _ = rep repeat
let _ = T.teardown_pool pool
