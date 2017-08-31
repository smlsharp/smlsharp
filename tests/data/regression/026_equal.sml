infix =
val puts = _import "puts" : string -> int
fun f x = (x,x)
val t = (5,5)
val _ = if f 5 = t then puts "true" else (puts "false"; raise Fail "ng")

(*
2011-08-17 katsu

This code is expected to print "true" but actually it prints "false".

This wrong behaviour is due to the following reasons:
(1) Function "f" in line 2 is a polymorphic function, so compiler produces
    the code allocating an object of RECORD obj_type and dynamically
    computing its bitmap.
(2) In line 3, in contrast, compiler can compute the bitmap of "(5,5)"
    statically and it is 0, compiler generates the code allocating an
    UNBOXED_VECTOR object.
(3) In line 4, sml_obj_equal function is called to perform equality check.
    The sml_obj_equal first checks whether two objects have same obj_type.
    In this situation, since one is RECORD but another is UNBOXED_VECTOR,
    this check fails and then sml_obj_equal returns false.

This bug is occurred in not only the smlsharp_ng version but also the main
trunk version.

*)

(*
2011-08-17 katsu

Fixed by changeset e9a9524b0a3e.
*)
