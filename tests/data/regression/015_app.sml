infixr ::
exception Failure of string

fun app f =
  let fun loop [] = ()
        | loop (h::t) = (f h : unit; loop t)
  in loop
  end

(*
2011-08-13 katsu

This causes BUG at ToYAANormal due to wrong compilation of ClosureConversion.

[BUG] searchEnvAcc
    raised at: ../toyaanormal/main/ToYAANormal.sml:733.13-733.64
   handled at: ../toplevel2/main/Top.sml:797.37
		main/SimpleMain.sml:269.53

val code c50 =
    _env $49 : {0: t57 list(t14) -> unit(t7)} / $2 =>
    fn $6 =>
       let frame () / (t57) =   (* <--- ????? *)
           _MERGE ()
       in let $2 : t57 list(t14) -> unit(t7) =
              (#0 /i cast(0wx0)) $49 /s cast(0wx4)
       in _TAILAPP $2 $6

c50 has a frame type variable but frame bitmap is missing.

*)

(*
2011-08-14 katsu

Fixed by changeset 92eba62e6350 and 625eabf6eaa2.

*)
