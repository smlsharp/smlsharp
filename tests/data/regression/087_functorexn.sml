functor F (A : sig exception E end) =
struct
  structure B = A
  exception E = B.E
end

(*
2011-08-29 katsu

This causes BUG at DatatypeCompilation due to unbound exception.

[BUG] compileExp: RCEXN_CONSTRUCTOR
    raised at: ../datatypecompilation/main/DatatypeCompilation.sml:849.27-849.70
   handled at: ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53

after InferTypes:

val F(2) : ({} -> {}) -> exn(t13[]) -> {1: exn(t10[])} =
    (fn {id(1) : {} -> {}} =>
       fn {E(0) : exn(t13[])} =>   (**** E(0) is a variable ****)
         let
           exception    (**** What is this? ****)
         in
           (**** B.E(e0) is unbound exception constructor ****)
           {1 = RCEXN_CONSTRUCTOR {exnInfo = B.E(0)}}
         end)
*)

(*
2011-08-31 ohori

Fixed.
*)

