datatype 'a t = X of 'a t

signature S =
sig
  datatype 'a t = X of 'a t
end

structure A =
struct
  datatype t = datatype t
end
:> S where type 'a t = 'a t

(*
2011-08-23 katsu

This causes an unexpected type mismatch error.

057_sig.sml:11.4-11.27 Error:
  (name evaluation 082) Type mismatch in sig where:t.(3)

2011-08-24 katsu

A bug is found in the above test code.
I fixed the bug but this code still causes the error.

*)

(*
2011-08-24 ohori

The abve phenomenon was indeed bug in sigCheck of datatype against datatype.
Constror types should be checked on the assumption that the two datatypes are
equivalent. This code is added.

*)
