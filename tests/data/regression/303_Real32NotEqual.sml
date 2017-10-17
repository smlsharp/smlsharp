val _ = 
    case Real32.!= (1.0, 2.0) of true => () | _ => raise Fail "Unexpected"

(*
2014-08-01 Sasaki

This code cannot compile.

uncaught exception: Bug.Bug: compilePrim: Float_notEqual at src/compiler/datatypecompilation/main/PrimitiveTypedLambda.sml:120
*)
