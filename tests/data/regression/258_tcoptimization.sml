fun f g = g () handle e => raise e

(*
2013-07-01 katsu

After TCOptimization, resultTy of TPHANDLE becomes a unbound type variable.

Type Inference:
val f(0) : ['a. (unit(t8[]) -> 'a) -> 'a] =
 [
  'a(36).
   fn {g(1) : unit(t8[]) -> 'a} =>
    (
      handle
        (g(1) : unit(t8[]) -> 'a) () : unit
       with
         fn $T_a(3) : exn(t13[]) =>
            case (handle) $T_a(3) : exn(t13[]) of
              e(2) : exn(t13[]) => raise e(2) : exn(t13[]) : 'a
    ) : 'a
        ^^ ***HERE***
  ]
export f(4) : (unit(t8[]) -> unit(t8[])) -> unit(t8[])
    as f : (unit -> unit) -> unit

TypedCalc Optimized:
val f(4) : (unit(t8[]) -> unit(t8[])) -> unit(t8[]) =
 (fn g(5) : unit(t8[]) -> unit(t8[]) =>
  (
    handle
      (g(5) : unit(t8[]) -> unit(t8[])) () : unit
    with
      fn $T_a(6) : exn(t13[]) =>
         case (handle) $T_a(6) : exn(t13[]) of
           e(7) : exn(t13[]) => raise e(7) : exn(t13[]) : unit
  ) : FREEBTV(36)
      ^^^^^^^^^^^
 ) : unit
export f(4) : (unit(t8[]) -> unit(t8[])) -> unit(t8[])
    as f : (unit -> unit) -> unit

*)

(*
2013-07-02 ohori
Fixed by 5216:8@7595dc04945 and 5215:4bfa51146b76
*)
