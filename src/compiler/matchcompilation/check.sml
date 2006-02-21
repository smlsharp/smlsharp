(* The ClosureConv types blocks as UNBOXED, but they should be BOXED.
 *)
fun f x = 1;
(* should be a UBRECCALL, not be a normal UBCALL. *)
fun f 0 = 1 | f n = f (n - 1);
(* The ClosureConv generates an expression where a RecClosure occurs
as an argument of MakeBlock where only atom is expected. *)
fun f 0 m = m | f n m = f (n - 1) (m + n);
(* env accesses appear as arguments *)
fun f m n s = if m = n then s else f m (n + 1) (s + n);
(*
Bugs report:*
Anormal transformation has a bug when compile the following code
*)
datatype 'a test = A of int | B of ('a->('a * 'a))
val x = A(1)
