val args = CommandLine.arguments ()
val valOf = Option.valOf
val repeat = case args of s::_ => valOf (Int.fromString s) | _ => 10
val size = case args of _::s::_ => valOf (Int.fromString s) | _ => 4194304
val cutOff = case args of _::_::s::_ => valOf (Int.fromString s) | _ => 32

(* NOTE: Manticore limits the length of arrays to 500000 *)
(*
(* nested sequential array causes segmentation fault *)
type 'a Array_array = 'a Array.array Array.array
fun Array_tabulate (n, f) =
    Array.tabulate
      ((n + 32767) div 32768,
       fn i => Array.tabulate
                 (Int.min (n - i * 32768, 32768),
                  fn j => f (i * 32768 + j)))
fun Array_sub (a, i) =
    Array.sub (Array.sub (a, i div 32768), i mod 32768)
fun Array_update (a, i, v) =
    Array.update (Array.sub (a, i div 32768), i mod 32768, v)
fun Array_app f a =
    Array.app (Array.app f) a
*)
type 'a Array_array =
    'a Array.array * 'a Array.array * 'a Array.array * 'a Array.array *
    'a Array.array * 'a Array.array * 'a Array.array * 'a Array.array *
    'a Array.array * 'a Array.array * 'a Array.array * 'a Array.array *
    'a Array.array * 'a Array.array * 'a Array.array * 'a Array.array
fun Array_tabulate (n, f) =
    let
      fun loop i 0 = if n > i then raise Fail "size too large" else nil
        | loop i c =
          Array.tabulate
            (Int.max (1, Int.min (262144, n - i)), fn j => f (i + j))
          :: loop (i + Int.min (262144, n - i)) (c - 1)
    in
      case loop 0 16 of
        a0 :: a1 :: a2 :: a3 :: a4 :: a5 :: a6 :: a7 ::
        a8 :: a9 :: aa :: ab :: ac :: ad :: ae :: af :: nil =>
        (a0, a1, a2, a3, a4, a5, a6, a7, a8, a9, aa, ab, ac, ad, ae, af)
      | _ => raise Match
    end
fun Array_sel (a0, a1, a2, a3, a4, a5, a6, a7,
               a8, a9, aa, ab, ac, ad, ae, af) n =
    case n div 262144 of
      0 => a0 | 1 => a1 | 2 => a2 | 3 => a3
    | 4 => a4 | 5 => a5 | 6 => a6 | 7 => a7
    | 8 => a8 | 9 => a9 | 10 => aa | 11 => ab
    | 12 => ac | 13 => ad | 14 => ae | _ => af
fun Array_sub (a, i) = Array.sub (Array_sel a i, i mod 262144)
fun Array_update (a, i, v) = Array.update (Array_sel a i, i mod 262144, v) 
fun Array_app f (a0, a1, a2, a3, a4, a5, a6, a7,
                 a8, a9, aa, ab, ac, ad, ae, af) =
    (Array.app f a0; Array.app f a1; Array.app f a2; Array.app f a3;
     Array.app f a4; Array.app f a5; Array.app f a6; Array.app f a7;
     Array.app f a8; Array.app f a9; Array.app f aa; Array.app f ab;
     Array.app f ac; Array.app f ad; Array.app f ae; Array.app f af)
(*
type 'a Array_array = 'a Array.array
val Array_tabulate = Array.tabulate
val Array_sub = Array.sub
val Array_update = Array.update
val Array_app = Array.app
*)

fun copy (a : double Array_array) b e d j =
    if e < b then ()
    else (Array_update (d, j, Array_sub (a, b));
          copy a (b+1) e d (j+1))

fun search a b e k =
    if e < b then e + 1
    else if e = b then if k < Array_sub (a, e) then e else e + 1
    else
      let
        val m = Int.quot (b + e, 2)
        val x = Array_sub (a, m) : double
      in
        if k < x
        then search a b m k
        else search a (m+1) e k
      end

fun merge a b1 e1 b2 e2 d j =
    if e1 < b1 then copy a b2 e2 d j
    else if e2 < b2 then copy a b1 e1 d j
    else if e1 - b1 < e2 - b2 then merge a b2 e2 b1 e1 d j
    else if Array_sub (a,e1) <= Array_sub (a,b2)
    then (copy a b1 e1 d j;
          copy a b2 e2 d (j+(e1-b1+1)))
    else if Array_sub (a,e2) <= Array_sub (a,b1)
    then (copy a b2 e2 d j;
          copy a b1 e1 d (j+(e2-b2+1)))
    else
      let
        val m = Int.quot (b1 + e1, 2)
        val n = search a b2 e2 (Array_sub (a, m))
      in
        if e1 - b1 <= cutOff then
          (
            merge a b1 m b2 (n-1) d j;
            merge a (m+1) e1 n e2 d (j+(m-b1+1)+(n-b2))
          )
        else
          (
            (| merge a b1 m b2 (n-1) d j,
               merge a (m+1) e1 n e2 d (j+(m-b1+1)+(n-b2)) |);
            ()
          )
      end

fun cilksort a b e d j =
    if e <= b then () else
    let
      val q2 = Int.quot (b + e, 2)
      val q1 = Int.quot (b + q2, 2)
      val q3 = Int.quot (q2+1 + e, 2)
    in
      if e - b <= cutOff then
        (
          cilksort a b q1 d j;
          cilksort a (q1+1) q2 d (j+(q1-b+1));
          cilksort a (q2+1) q3 d (j+(q2-b+1));
          cilksort a (q3+1) e d (j+(q3-b+1));
          merge a b q1 (q1+1) q2 d j;
          merge a (q2+1) q3 (q3+1) e d (j+(q2-b+1));
          merge d b q2 (q2+1) e a b
        )
      else
        (
          (|
             ((| cilksort a b q1 d j,
                 cilksort a (q1+1) q2 d (j+(q1-b+1)) |);
              merge a b q1 (q1+1) q2 d j),
             ((| cilksort a (q2+1) q3 d (j+(q2-b+1)),
                 cilksort a (q3+1) e d (j+(q3-b+1)) |);
              merge a (q2+1) q3 (q3+1) e d (j+(q2-b+1)))
          |);
          merge d b q2 (q2+1) e a b
        )
    end

val pmseed = IntRef.new 1
fun pmrand () =
    let val hi = IntRef.get pmseed div (2147483647 div 48271)
        val lo = IntRef.get pmseed mod (2147483647 div 48271)
        val test = 48271 * lo - (2147483647 mod 48271) * hi
        val seed = if test > 0 then test else test + 2147483647
    in IntRef.set (pmseed, seed);
       seed
    end
fun randReal () = Double.fromInt (pmrand ()) / Double.fromInt (pmrand ())

fun init_a () =
    (
      IntRef.set (pmseed, 1);
      Array_tabulate (size, fn _ => randReal ())
    )

fun init_d () =
    Array_tabulate (size, fn _ => 0.0)

fun doit a d () =
    cilksort a 0 (size - 1) d 0

fun rep 0 = ()
  | rep n =
    let val a = init_a ()
        val d = init_d ()
        val (r, t) = Time.timeToEval (doit a d)
(*
        val _ = Array_app (fn x => print (Double.toString x ^ "\n")) a
*)
    in print (" - {result: " ^ Int.toString 0 ^ ", time: "
              ^ Time.toString t ^ "}\n");
       rep (n - 1)
    end

val _ = print (" bench: cilksort_manticore_ptuple\n size: "
               ^ Int.toString size ^ "\n cutoff: " ^ Int.toString cutOff
               ^ "\n results:\n")
val _ = rep repeat
