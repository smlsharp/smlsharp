signature A = 
  sig 
     datatype foo = A | B
     datatype ZZZ = C
  end
functor F (XXXXX:A) = struct val x = 1 end;
(* 2012-8-7 ohori
   extra 3 new lines for A B C are printed in functor F;
   strengely, no new lines are printed in signature A
*)

(* 2012-8-7 ohori 
   Made an ad-hoc fix (4378:5e44dff2dce3) 
   by filtering out IDSPECCON in varE
   just before printing in module Reify.sml
*)
