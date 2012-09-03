(*
The specification is:
* A non value term whose type contains free type variable cannot be
  generalized (according to the definition.)
The rest is upto the implementation.

smlsharp adopts the following strategy:
 If those non generalized type variables remain at the top-level
 binding, then they are replaced by unique atomic types.
 Those atomic types cannot be unified with any other types, but they
 can be instance types of polymorphic types.
*)

datatype 'a dt = D;
val x1 = D; (* non-expansive expression *)
val x2 = !(ref D); (* expansive expression *)

fun f1 _ = 0;
fun f2 (_ : 'a dt) = 0;

val r11 = f1 x1; (* accepted *)

val r12 = f1 x2; (* accepted *)
val r21 = f2 x1; (* accepted since no unification occurs. *)
val r22 = f2 x2; (* rejected since unification occurs. *)
