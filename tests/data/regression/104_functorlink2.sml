_interface "104_functorlink2.smi"
val F = ((_import "puts" : string -> int) "2"; ())
structure S = F()
