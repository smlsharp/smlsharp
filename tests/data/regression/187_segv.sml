infixr ::
fun put(a,x) = (a,x:int list)
fun f x y = x y : int * int list

(* comment out this function and the SEGV does not occur. *)
fun SEGV_OCCURES_DUE_TO_EXISTENCE_OF_THIS_FUNCTION x =
    f put x : int * int list

(* put does not return a pointer to a pair *)
val x = #2 (put (0xdead,[0xbeaf]))
val _ = case x of [0xbeaf] => ()

(*
2011-12-17 katsu

This causes segmentation fault.

*)

(*
2011-12-18 katsu

fixed by changeset bb4ce4380319.

The situation is the following.

val put =
    ['a. fn x : {1: 'a, 2: int}^{B} => {#1 x, #2 x} : {'a, int}]

val {_, x} =
    (put : ['a. {1: 'a, 2: int}^{B} -> {'a, int})
      {int}
      ({1 = 0xdead, 2 = 0xbeaf} : {1: int, 2: int}^{B})

The argument type of put is {1:'a, 2:int}^{B}. 
On the other hand, the argument expression {1=0xdead, 2=0xbeaf} of put
is {1:int, 2:int}^{B}.
Of course, the layout of these two record type must be same.
However, BitmapCompilation compiles these two records to different record
layouts since these record types has no "align" annotation and the type
term of the first field of these two type annotations are different.
One is 'a, whose max size is 16, and another is int, whose max size is 4.

This means that the optimal layout of records with no "align"
annotation cannot be computed from their types independently.
One workaround of this issue is to fix the size of all fields of no "align"
records to the maximum size of all types.

*)
