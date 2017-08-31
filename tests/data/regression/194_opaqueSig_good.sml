_interface "./194_opaqueSig.smi"
structure B :>
sig
  type foo
  structure C : 
     sig 
       val f : foo -> foo 
     end
  val a : foo
end
=
  struct
    type foo = int
    structure C = A
    val a = C.f 1
  end
(* val bad = B.C.f 1 *)
val good = B.C.f B.a
(*
2012-1-18 ohori.
bad is accepeted and good is rejected

This is due to incomplete implementation of structure replication
in interface in nameevaluation. 
*)
