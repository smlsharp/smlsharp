_interface "035_sig.smi"

fun GenericOS_poll
      (fds : (int * word) array, timeout : (int * int) option)
      : (int * word) array = raise Fail ""

(*
2011-08-19 katsu

This code causes unexpected type error.

  035_sig.smi:1.5-2.67 Error:
  (type inference 063) type and type annotation don't agree
  inferred type: (int(t0) * word(t1))
                  array(t9)
                 * (int(t0) * int(t0))
                  option(t15)
                 -> int(t0) * word(t1)
                  array(t9)
  type annotation: {} array(t9) * {} option(t15) -> {} array(t9)

2011-08-19 ohori
Fixed. This is due to a bug in interface.grm.

Corrected the code:
fun GenericOS_poll
      (fds : (int * word) SMLSharp.PrimArray.array, timeout : (int * int) option)
      : (int * word) SMLSharp.PrimArray.array = raise Fail ""

*)
