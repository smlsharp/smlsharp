_interface "101_functorapp.smi"
structure S = F()

(*
2011-09-02 katsu

extern F.f is lacking.
This does not cause compile error, but may cause link or runtime error.

extern val F : unit(t7[]) -> {1: unit(t7[]) -> unit(t7[])}
val $T_a(2) : {1: unit(t7[]) -> unit(t7[])} =
    (EXVAR(F : unit(t7[]) -> {1: unit(t7[]) -> unit(t7[])})
     : unit(t7[]) -> {1: unit(t7[]) -> unit(t7[])})
      ()
val F.f(0) : unit(t7[]) -> unit(t7[]) =
    #1
      _indexof(1, {1: unit(t7[]) -> unit(t7[])})
      ($T_a(2) : {1: unit(t7[]) -> unit(t7[])} : {1: unit(t7[]) -> unit(t7[])})
    : unit(t7[]) -> unit(t7[])
(**** EXVAR(F.f) is unbound ****)
val F.f(1) : unit(t7[]) -> unit(t7[]) = EXVAR(F.f : unit(t7[]) -> unit(t7[]))
export val F.f(1) : unit(t7[]) -> unit(t7[])

*)

(*
2011-09-02 ohori

The generated code seems to be OK. The name evaluator produces
the sequnce:

1. extern var F
2. val T_a = F ()
3. val F.f = #1 T_a 
4. export val F.f

*)
