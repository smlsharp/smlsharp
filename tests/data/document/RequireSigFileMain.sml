open SMLUnit.Test SMLUnit.Assert

val _ = assertEqualInt 1 Str1.v1
val _ = assertEqualInt 1 (Str1.f1 1)
val _ = 1 : Str1.t1
val _ = Str1.v2 : Str1.d1
val _ = (Str1.f2 1) : Str1.d2
val _ = (raise Str1.Exn1) 
        handle Str1.Exn1 => ()
             | _ => fail "NG Str1.Exn1"
val _ = 1 : Str1.Str11.t11
val _ = (raise Str1.Str11.Exn11) 
        handle Str1.Exn1 => ()
             | _ => fail "NG Str1.Str11.Exn11"
val _ = 1 : Str1.Str12.t11
val _ = (raise Str1.Str12.Exn11) 
        handle Str1.Exn1 => ()
             | _ => fail "NG Str1.Str12.Exn11"
