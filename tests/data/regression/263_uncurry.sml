infixr ::
fun app (f:int) nil = ()
  | app f (h::t) = app f t

(*
2013-07-18 katsu

Uncurry optimization generates wrong type annotations.

Uncurrying Optimized:
valpolyrec[
  'a.
  val rec app : {int, 'a list} -> unit =
      (fn {$T_d : int, $T_c : 'a list} =>
          (case (match) {$T_d : int, $T_c : 'a list} : {int, 'a list} of
             {f : int, nil} => () : unit
           | {f : int, :: (h : 'a, t : 'a list)} =>
             (app : {int, 'a list} -> unit) {f : int,t : 'a list} : unit
          ) : unit
      ) : unit
]
val app : ['a. int -> 'a list -> unit] =
[
  'a.
  (fn $T_a : int =>
      (fn $T_b : 'a list =>
          (app : ['b. {int, 'b list} -> unit]) {'a} {$T_a : int, $T_b : 'a list}
          :unit
      ) : 'a list -> unit
  ) : {int, 'a list} -> unit
      ^^^^^^^^^^^^^^ **** WRONG ****
]
export app : ['a. int -> 'a list -> unit]
    as app : ['a. int -> 'a list -> unit]
*)

(*
2013-08-07 ohori
Fixed
*)
