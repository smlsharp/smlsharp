signature S221 =
sig
  datatype s = D
  structure S : sig datatype t = E end where type t = s
end;

signature S222 =
sig
  datatype t = D
  structure S : sig datatype t = E end where type t = t
end;

(*
2012-07-13 ymukade

where type の型不適合エラー
この形は許されているはず

(interactive):5.17-5.55 Error:
  (name evaluation Sig-110) Type mismatch in sig where:t.(2)
(interactive):11.17-11.55 Error:
  (name evaluation Sig-110) Type mismatch in sig where:t.(2)
*)

(*
2012-07-19 ohori

This is the feature of SML# language, which rejects signatures that do not
have any instance.

Rejecting them is necessary for separately compiling a functor.
To compiler a functor, the SML# compiler generates a temprate structure from
a signature for compiling the body of the functor. To do this, we only allow
a signature that has an instance structure.

*)
