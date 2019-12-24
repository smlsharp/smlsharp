open SMLUnit.Test SMLUnit.Assert

val _ = assertEqualInt 1 Str1a.v1
val _ = assertEqualInt 1 (Str1a.f1 1)
val _ = 1 : Str1a.t1
val _ = Str1a.v2 : Str1a.d1
val _ = (Str1a.f2 1) : Str1a.d2
val _ = (raise Str1a.Exn1) 
        handle Str1a.Exn1 => ()
             | _ => fail "NG Str1a.Exn1"
val _ = 1 : Str1a.Str11.t11
val _ = (raise Str1a.Str11.Exn11) 
        handle Str1a.Exn1 => ()
             | _ => fail "NG Str1a.Str11.Exn11"
val _ = 1 : Str1a.Str12.t11
val _ = (raise Str1a.Str12.Exn11) 
        handle Str1a.Exn1 => ()
             | _ => fail "NG Str1a.Str12.Exn11"

val _ = assertEqualInt 1 v1a
val _ = assertEqualInt 1 (f1a 1)
val _ = assertEqualString "A" (f1a "A")
