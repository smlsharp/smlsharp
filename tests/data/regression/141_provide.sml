structure S :> sig
  type 'a t 
  val x : 'a t
end =
struct
  type 'a t = int * 'a list
  val x = (0, nil)
end

(*
2011-09-09 katsu

This causes an unexpected type error.

141_provide.smi:3.8-3.27 Error:
  (name evaluation CP-200) Provide check fails (type definition) : S.t

*)

(*
2011-11-25 ohori

Fixed by relazing the set of non-expansive terms to include 
  #l non-expansive-term
This is needed to deal with this case.

Since (0, nil) is compiled to (0, nil:['a. 'a list]) : int * ['a. 'a list],
the compiler need to construct the following
   val x = (#1 x, #2 x {'x}) 
For this to have the type ['a. int * 'a list], the compiler need to abstract 'x
to form 
   val x = ['a. (#1 x, #2 x {'a})]  

*)
