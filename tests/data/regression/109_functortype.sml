functor F () =
struct
  type t = int
end
structure S = F ()
val x = 0 : S.t

(*
2011-09-05 katsu

This causes an unexpected type error.

109_functortype.sml:6.9-6.15 Error:
  (type inference 012) type and type annotation don't agree
    inferred type: 'D::{int(t0[]),
                        SMLSharp.IntInf.int(t11[]),
                        ('B::{int(t0[]), int(t0[]) option(t16[])}, 'C)
                          value(t25[])}
  type annotation: S.t(t30[])
*)


(*
2011-09-05 ohori

Fixed. By filttering the typidSet in NameEval to those new ones
that are created in functor body.
*)
