(*
This cause a bug exception 

  # use "342_findConset.sml";
  # Astr.new 1;
  findconset in travserseReifiedTy
  int foo(5174) LAYOUT_SINGLE_ARG{wrap:true}
  find conset in travserseReifiedTy 
   Bug.Bug: findconset in travserseReifiedTy at src/compiler/extensions/reflection/main/TyToReifiedTy.sml:205
*)

signature A = sig
  type 'a foo
  val new : 'a -> 'a foo
end

structure Astr :> A = 
struct
  datatype 'a foo = A of 'a 
  fun new x = A x
end
;

Astr.new 1;
