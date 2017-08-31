val a = "[1, null, 2]"
val b = JSON.import a
val c = _json b as int option list
        handle e =>
               raise Fail "must be [SOME 1, NONE, SOME 2] : int option list"

(* 
2016-11-10 osaka

This causes JSON.RuntimeTypeError (ONLY on interactive mode).
*)
