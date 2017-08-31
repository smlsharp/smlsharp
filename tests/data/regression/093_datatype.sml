datatype t1 = T1 of t2
and t2 = T2
fun f x =
let
  val T1 (y as T2) = x
in
  y
end

(*
2011-08-30 katsu

This causes BUG at DatatypeCompilation due to a bug of InferTypes.

[BUG] 093_datatype.sml:7.3-7.3: variable not found:y(2)
    raised at: ../staticanalysis/main/SAContext.sml:43.13-46.18
   handled at: ../toplevel2/main/Top.sml:868.37
                main/SimpleMain.sml:359.53

After type inference:

val f(0) : t1(t30[]) -> ERRORty =      (*** ERRORty?? ***)
 (fn x(1) : t1(t30[]) =>
  let
   val $T_b(4) : {} =
    case (bind)
     x(1) : t1(t30[])
     :{t1(t30[])}
    of
     T1 $T_a(3) : t2(t31[]) as T2  =>
     ()
      :{}
    : {}
  in
   y(2) : ERRORty : {ERRORty}        (*** y(2) is unbound ***)
  end
  :ERRORty)
*)


(*
2011-08-01 ohori

Fixed. This is a simple bug in varsInPat, and not due to something
related to ifGenterm.

*)

