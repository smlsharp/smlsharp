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


val _ = assertEqualInt 1 Str2.v1
val _ = assertEqualInt 1 (Str2.f1 1)
val _ = 1 : Str2.t1
val _ = Str2.v2 : Str2.d1
val _ = (Str2.f2 1) : Str2.d2
val _ = (raise Str2.Exn1) 
        handle Str2.Exn1 => ()
             | _ => fail "NG Str2.Exn1"
val _ = 1 : Str2.Str11.t11
val _ = (raise Str2.Str11.Exn11) 
        handle Str2.Exn1 => ()
             | _ => fail "NG Str2.Str11.Exn11"
val _ = 1 : Str2.Str12.t11
val _ = (raise Str2.Str12.Exn11) 
        handle Str2.Exn1 => ()
             | _ => fail "NG Str2.Str12.Exn11"


val _ = assertEqualInt 1 Str3.v1
val _ = assertEqualInt 1 (Str3.f1 1)
val _ = 1 : Str3.t1
val _ = Str3.v2 : Str3.d1
val _ = (Str3.f2 1) : Str3.d2
val _ = (raise Str3.Exn1) 
        handle Str3.Exn1 => ()
             | _ => fail "NG Str3.Exn1"
val _ = 1 : Str3.Str12.t11
val _ = (raise Str3.Str12.Exn11) 
        handle Str3.Exn1 => ()
             | _ => fail "NG Str3.Str12.Exn11"
