_interface "083_provide.smi"
local
structure T =
struct
  datatype t = X
end
in
structure S :> sig type t end = T
end

(*
2011-08-27 katsu

This causes an unexpected name error.

083_provide.smi:3.3-3.18 Error:
  (name evaluation 126) Provide check fails (datatype expceted) : S.t
mbp3:1:~/smlsharp-ng/doc/tests katsu$ cat 083_provide.smi
*)

(*
2011-08-29 ohori

It compiles OK (with no output). So this is the same bug as 082.

*)
