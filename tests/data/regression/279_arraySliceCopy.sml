fun fromSliceToArray s =
    Array.tabulate(ArraySlice.length s, fn i => ArraySlice.sub(s, i))
val a1 = Array.tabulate(10, fn i => i);
val a2 = ArraySlice.slice(a1, 0, SOME (Array.length a1 - 1))
val a3 = fromSliceToArray a2
val a4 = ArraySlice.copy{src=a2, dst=a1, di=1}
val a5 = a1

val _ =
    if List.tabulate (Array.length a5, fn i => Array.sub (a5, i))
       = [0,0,1,2,3,4,5,6,7,8]
    then ()
    else raise Fail "ng"

(* 2014-01-26 ohori
val a5 = <0,0,0,0,0,0,0,0,0,0> : int array
となり，arraysliceから元になっているarrayへのcopy
でメモリーが破壊される．
*)

(*
2014-01-29 katsu

fixed
*)
