type bar = int array
datatype foo = WWWWWWWWW of {A:bar, B:int};
fun f (x:foo, y:foo) =  x = y

(* 2012-10-28 ohori
This causes unexpected type error.
The same as 192_eqtypeRef; the fix was imcomplete.
*)

(* 2012-10-28 ohori
*)
