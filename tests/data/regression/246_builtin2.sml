(* a check code of the bug fix 246_builtin 
*)
structure A = F()
val x = A.toIntX 0w99
val y = print (Int.toString x)


