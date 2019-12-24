open SMLUnit.Test SMLUnit.Assert
val _ = (raise Exn1) 
        handle Exn1 => ()
             | _ => fail "NG Exn1"

val _ = (raise v2) 
        handle Exn2 1 => ()
             | _ => fail "NG Exn2"

val _ = (raise v3) 
        handle Exn3 _ => ()
             | _ => fail "NG Exn3"

val _ = (raise Exn41) 
        handle Exn42 => fail "NG Exn42"
             | Exn41 => ()
             | _ => fail "NG Exn4"

val _ = (raise Exn1) 
        handle Exn5 => ()
             | _ => fail "NG Exn5"

val _ = (raise Exn5; 1)
        handle Exn5 => 1
             | _ => fail "NG Exn5"

val _ = (raise Exn5; 1)
        handle Exn1 => 1
             | _ => fail "NG Exn5"

val _ = (raise (1 Exn6 2))
        handle 1 Exn6 2 => ()
             | _ => fail "NG Exn6"

val _ = (raise Exn7 (fn x => x))
        handle Exn7 f => assertEqualInt 1 (f 1)
             | _ => fail "NG Exn7"

val _ = (raise Exn8 {A = 1, B = "A"})
        handle Exn8 {A = 1, B = "A"} => ()
             | _ => fail "NG Exn8"

val _ = (raise Exn9 [1, 2, 3])
        handle Exn9 [1, 2, 3] => ()
             | _ => fail "NG Exn9"
