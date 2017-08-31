signature S = 
sig
  datatype t = D
end

structure S =
struct
  datatype t = D
end :> S

val x = S.D

(*
2012-07-11 endo

datatype宣言をしたstructureにsignatureをopaqueで適用し、要素を呼び出そうとするとバグが発生。
*)

(*
2012-07-19 ohori
I cannot reconstruct the bug; assumed that this has been fixed by
some of the previous fixes.
*)
