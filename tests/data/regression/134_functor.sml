_interface "134_functor.smi"
structure S = F(
  type t1 = int
  type t2 = real
  val x1 = 1
  val x2 = 1.0
)

(*
2011-09-07 katsu

The definition of "_.F" in 134_functor2.sml and the use of it in
134_funtor.sml have different types.

After record compilation:

134_functor2.sml:

val _.F(9)
    : ['a,
       'b.
       {TAG('a), SIZE('a), TAG('b), SIZE('b)}
       -> ('a * 'b -> 'a * 'b) -> {'a, 'b} -> {1: unit(t7[]) -> 'a * 'b}] =
      (****** 'a denotes t1, 'b denotes t2 ******)              ^^^^^^^^
    ...

134_functor.sml:

val $T_a(9) : {1: unit(t7[]) -> t1(t0[]) * t2(t5[])} =
    (_cast(_.F)
     : ['a,
        'b.
        {TAG('a), SIZE('a), TAG('b), SIZE('b)}
        -> ('a * 'b -> 'a * 'b) -> {'b, 'a} -> {1: unit(t7[]) -> 'b * 'a}])
      (****** 'a denotes t2, 'b denotes t1 ******)               ^^^^^^^
      {t2(t5[]), t1(t0[])}
      {_tagof(t2(t5[])), _sizeof(t2(t5[])), _tagof(t1(t0[])), _sizeof(t1(t0[]))}
      ...

*)


(*
2011-09-07 ohori

This is a bug in name evaluator; if the parameter signature in
functor definition and functor application are different in 
declaration order, then types are not properly passed.

I took the order of lifted type variables according the order
on the path of original type names.

*)
