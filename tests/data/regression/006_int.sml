val x = 1
(*
2011-08-11 ohori

Type Inference:
  ...
val x(0) =
    1 : '::{{}int(t0),
            {}int(t11),
            ('::{{}int(t0), {}int(t0) {}option(t15)}, ') {}value(t23)}

2011-08-11 ohori
Fixed. Code to deal with this was in module type inference.
Renew the code and added it in typeinference.

*)

