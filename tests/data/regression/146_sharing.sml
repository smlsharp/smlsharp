signature S =
sig
  structure X : sig
    datatype t = D
  end
  structure Y : sig
    type t
  end
  sharing type Y.t = X.t
end

(*
2011-11-25 katsu

This causes an infinite loop at NameEvaluation.
*)

(*
2011-11-25 ohori

Fixed.
*)
