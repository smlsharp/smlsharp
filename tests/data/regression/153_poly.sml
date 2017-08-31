infixr ::
structure Fifo :> sig
  type 'a queue
  val empty : 'a queue
  val get : 'a queue -> 'a * 'a queue
end 
= 
struct
  type 'a queue = 'a list
  val empty = nil
  fun get (foo::x) = (foo, x)
end

val (_, x) = Fifo.get Fifo.empty

(*
2011-11-28 katsu

This causes BUG at RecordCompilation.

TAG(FREEBTV(38))
[BUG] generateInstance
    raised at: ../recordcompilation/main/RecordCompilation.sml:309.26-309.56
   handled at: ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53

This BUG seems to be due to that the type inference does not replace
FREEBTVs with DUMMYtys.

RecordCalc:

val $T_b(8) : FREEBTV(38) * FREEBTV(38) queue(t30[[opaque(rv1,queue(t15[]))]]) =
    Fifo.get(4) {FREEBTV(38)} (Fifo.empty(5) {FREEBTV(38)})

This should be

val $T_b(8) : DUMMY * DUMMY queue(t30[[opaque(rv1,queue(t15[]))]]) =
    Fifo.get(4) {DUMMY} (Fifo.empty(5) {DUMMY})

*)

(*
2011-11-28 ohori

Fixed. See 157_polyValBind.sml
*)
