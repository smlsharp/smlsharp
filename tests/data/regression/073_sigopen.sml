_interface "073_sigopen.smi"

structure T :> sig
  structure S : sig
    type 'a t
  end
end
=
struct
  structure S =
  struct
    type 'a t = 'a list
  end
end

open T

(*
2011-08-25 katsu

This causes an unexpected name error.

073_sigopen.smi:3.8-3.23 Error:
  (name evaluation 131) Provide check fails (type definition) : S.t
*)

(*
2011-08-27 ohori

Fixed. 
PITYPE case in CheckProvide should check dtyKind if its opacity is
OPAQUE*.

*)
