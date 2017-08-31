functor F (A : sig type 'a t end) =
struct
  datatype 'a t = T of 'a A.t
end
structure S = F(type 'a t = int)

(*
2011-08-22 katsu

This causes BUG.

[BUG] NameEval: tfun def
    raised at: ../nameevaluation/main/NameEval.sml:1906.43-1906.57
   handled at: ../nameevaluation/main/NameEval.sml:2220.15
                ../nameevaluation/main/NameEval.sml:2722.31
                ../nameevaluation/main/NameEval.sml:2735.27-2735.30
                ../toplevel2/main/Top.sml:756.66-756.69
                ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53
*)

(*
2011-08-25 ohori 
Fixed (2623:4667c5b3c2e5) by rejecting this and all those that
instantiate 'a t to something other than datatype. 

*)
