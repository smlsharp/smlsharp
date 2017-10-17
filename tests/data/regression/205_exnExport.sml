exception A of int
exception B = A;
exception C = A;

(* 2012-7-12 ohori 
This causes Compiler bug:
  # exception A of int
  > exception B = A;
  exception B of int
  # exception C = A;
  Compiler bug:compileDecl: RCEXPORTEXN
The anomary in printing shown by 199_exn.sml is due to this bug.
*)

(*
2012-07-12 ohori 
Fixed by 4302:eead5f56b84a

*)
