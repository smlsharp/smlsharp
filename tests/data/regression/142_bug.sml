functor S(A: sig
  type 'a t
  val f : 'a t -> 'a t
end) =
struct
  fun f x = A.f x
end

(*
2011-09-09 katsu

This causes BUG.

[BUG] datatypeLayout: no variant
    raised at: ../datatypecompilation/main/DatatypeCompilation.sml:435.22-435.62
   handled at: ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53

*)

(*
2011-11-25 ohori

Fixed.

*)
