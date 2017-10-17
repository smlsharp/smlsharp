infix ::;
fun f x nil = ()
  | f x (h::t) = f x t

(*
2011-09-07 katsu

Uncurry optimization generates wrong POLYty in TPVAR.

After uncurry optimization:

['a, 'b.
 val rec f(0) : {'a, 'b list(t15[])} -> unit(t7[]) =
     ...
]
val f(0) : ['a, 'b. 'a -> 'b list(t15[]) -> unit(t7[])] =
    ['a, 'b.
     (fn {$T_c(7) : 'a}
         : 'b list(t15[]) -> unit(t7[]) =>
        fn {$T_d(8) : 'b list(t15[])}
           : unit(t7[]) =>
          ((f(0) : ['c, 'd. {'a, 'b list(t15[])} -> unit(t7[])]
                  (******** "'a, 'b list" should be "'c, 'd list" ********)
            : ['c, 'd. {'a, 'b list(t15[])} -> unit(t7[])])
             {'a, 'b}
           : {'a, 'b list(t15[])} -> unit(t7[]))
            {$T_c(7) : 'a, $T_d(8) : 'b list(t15[])})
     : 'a -> 'b list(t15[]) -> unit(t7[])]
*)

(*
2011-09-08 ohori

Fixed  by setting propert btvenv in instantiateAndCurryFun 
in UncurryFundecl.

This however indicate a potential problem of rebinding the same id.
As a conventional optimizer, UncurryFundecl copies declarations by 
assuming static scoping. This need to be rectified.

*)
