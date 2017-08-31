_interface "114_exnrep.smi"
structure S =
struct
  structure T = T2
end

(*
2011-09-05 katsu

This causes an unexpected name error.

114_exnrep.smi:6.15-6.22 Error:
  (name evaluation CP-310) exception id expected in exception replication : T2.E
*)

(*
2011-09-05 ohori

Fixed.

*)
