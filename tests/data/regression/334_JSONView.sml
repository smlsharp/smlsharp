val a = "{\"name\" : \"a\"}"
val b = JSON.import a
val c = _json b as {name : string option} JSON.dyn
val d = JSON.view c
        handle e => raise Fail "must be {name = SOME \"a\"}"
(*
2016-11-10 osaka

This causes JSON.RuntimeTypeError. (on both Interactive mode and compile mode)

By adding following case to coerceJson, this problem may be solved.
  | (OPTIONty ty, j) => (coerceJson ty) j
*)
