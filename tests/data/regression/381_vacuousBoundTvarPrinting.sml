fun f 0 y = y
  | f x y = (g (x - 1) (fn x => x); y)
and g 0 y = y
  | g x y = (f (x - 1) (fn x => x); y);

(*
This code generates the following interactive output:
  SML# 4.0.0 (2021-04-06 05:12:50 JST) for x86_64-pc-linux-gnu with LLVM 11.1.0
  # fun f 0 y = y
  >  | f x y = (g (x - 1) (fn x => x); y)
  > and g 0 y = y
  >  | g x y = (f (x - 1) (fn x => x); y);
  val f = fn : ['a, 'BT5438. int -> ('a -> 'a) -> 'a -> 'a]
  val g = fn : ['a, 'BT5437. int -> ('a -> 'a) -> 'a -> 'a]
  # 

The reason: the code generates the following IR if TypedCalc: 
POLYREC(
  {'BT5437, 'BT5438}.
   f = fn : int -> ('BT5437 -> 'BT5437) -> 'BT5437 -> 'BT5437
   g = fn : int -> ('BT5438 -> 'BT5438) -> 'BT5438 -> 'BT5438
 )
(as expected). Then, for each id (f,g in this case), the SML# type printer 
sorts/renames the bound type variables according to their occurrences in 
the type of id, leaving those that do no appear in the type.

This can be fixed by modifying the function
 helper_format_boundTvars (in Types.ppg)
to eliminate those btvs that do not appear in btvOrder.
*)
