_interface "085_provide.smi"

structure T :> sig
  structure S1 : sig type 'a t end
  structure S2 : sig type 'a t end
end
=
struct
  structure S1 =
  struct
    datatype 'a t = X of 'a list
  end
  structure S2 =
  struct
    open S1
  end
end

(*
2011-08-29 katsu

This causes an unexpected name error.

085_provide.smi:9.10-9.25 Error:
  (name evaluation 139) Provide check fails (type definition) : T.S2.t

*)

(*
2011-08-31 ohori

I assert that this is an expected name error.
The open statement is the same effect as
   datatype t = datatype S1.t
So without the signature constraint, S1.t and S2.t
are the same (generative) type.
The signature constraint hide this type. So a possible
interface would be:

structure T =
struct
  structure S1 =
  struct
    datatype 'a t (= X of 'a list)
  end
  structure S2 =
  struct
    datatype 'a t (= X of 'a list)
  end
end

For this, there are multiple instances, including:

(1)
structure T :> sig
  structure S1 : sig type 'a t end
  structure S2 : sig type 'a t end
end
=
struct
  structure S1 =
  struct
    datatype 'a t = X of 'a list
  end
  structure S2 =
  struct
    open S1
  end
end


(2)
structure T :> sig
  structure S1 : sig type 'a t end
  structure S2 : sig type 'a t end
end
=
struct
  structure S1 =
  struct
    datatype 'a t = X of 'a list
  end
  structure S2 =
  struct
    datatype 'a t = X of 'a list
  end
end

The current provide language cannot distinguish the two.

*)
