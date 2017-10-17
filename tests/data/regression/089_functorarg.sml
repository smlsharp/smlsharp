_interface "089_functorarg.smi"
functor F (type t) =
struct
  structure A = SomethingWrong (* comment out this line, and no BUG occurs. *)
end
structure S = F (type t = SomethingWrong.t)

(*
2011-08-29 katsu

This causes BUG at BitmapCompilation due to the fact that tycon "t"
of an argument of functor "F" is DTY but it has no data constructor
information.

[BUG] datatypeLayout: no variant _X.t(t34[])
    raised at: ../datatypecompilation/main/DatatypeCompilation.sml:354.24-354.116
   handled at: ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53

*)


(*
2011-09-01 Ohori

Fixed this well tracked down bug by applying tfvSubst to dtyKind
in making castList in NameEval.sml

*)
