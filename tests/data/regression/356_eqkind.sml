fun order (x, y) =
    if x <= y then (x, y) else (y, x)
fun cpin nil = nil
  | cpin (h :: t) = (order h, order h) :: cpin t
fun sub nil = false
  | sub ((a, b) :: t) = a = b orelse sub t
fun check y =
    sub (cpin y)

(*
2020-01-17 katsu

This causes the following unexpected type error.

356_eqkind.sml:8.4-8.14 Error:
  (type inference 016) operator and operand don't agree
  operator domain: ('BRT#eq * 'BRT#eq) list
          operand: (('BRS::{int, word, int8, word8, ...}
                     * 'BRS::{int, word, int8, word8, ...})
                    * ('BRS::{int, word, int8, word8, ...}
                       * 'BRS::{int, word, int8, word8, ...}))
                     list

*)
