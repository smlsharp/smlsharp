_interface "084_provide.smi"
structure S0
 :>
  sig
    eqtype t
  end
=
struct
  type t = string
end
structure S 
=
struct
  open S0
end
(*
2011-08-29 katsu

This causes an unexpected name error.

084_provide.smi:3.10-3.21 Error:
  (name evaluation 137) Provide check fails (type definition) : S.t

*)

(*
2011-08-29 ohori

This should be an expected name error on the following
ground:

(1) 
interface: 
  structure S =
  struct
    eqtype t (= string)
  end

source: 
  _interface "..."
  structure S :> sig eqtype t end
  =
  struct
    type t = string
  end

(2) 
interface: 
  structure S =
  struct
    eqtype t (= string)
  end

source: 
  _interface "..."
  structure =
  struct
    type t = string
  end

(1) should name check, since its interface exactly specifies the source,
and, when required by other sources, produces the same environment as 
the result of evaluating the soruce. (2) does not have not this property 
so we should reject (2).

*)
