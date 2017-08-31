_interface "094_provideopen.smi"

structure A =
struct
  structure S =
  struct
    type t = int
  end
  structure T =
  struct
    fun f n = n : int
  end
end

open A

(*
2011-09-01 katsu

This causes an unexpected name error.

094_provideopen.smi:7.18-7.20 Error:
  (name evaluation 0621) unbound type constructor or type alias: S.t
*)

(*
2011-09-01 ohori

Fixed.

*)
