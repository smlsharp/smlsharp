_interface "085_provide2.smi"

structure T :> sig
  structure S1 : sig type 'a t end
  structure S2 : sig type 'a t end
end
=
struct
  structure S1  =
  struct
    datatype 'a t = X of 'a list
  end
  structure S2 =
  struct
    datatype t = datatype S1.t
  end
end

(*
2011-09-03 ohori

This cuase unexpected type error.

085_provide2.smi:9.5-9.31 Error:
  (name evaluation 143) Provide check fails (type definition) : T.S2.t

The code for datatype replication interface is not yet properly written.

*)

(*
2011-09-04 ohori

FIXED.
*)

