(* expression *)
val v1 = {a = 1, b = 4, a = 2, b = 3};

(* pattern *)
val v2 = fn {a = 1, b = 4, a = 2, b = 3} => 1;
fun f3 {a = 1, b = 4, a = 2, b = 3} = 1;

(* type expression *)
val v4 = fn x => case x of _ : {a : int, b : bool, a : string, b : char} => a;
val v5 =
    fn x => case x of x : {a : int, b : bool, a : string, b : char} as y => y;
val v6 = fn x => (x : {a : int, b : bool, a : string, b : char});
type t7 = {a : int, b : bool, a : string, b : char};
datatype t8 = D8 of {a : int, b : bool, a : string, b : char};
exception E9 of {a : int, b : bool, a : string, b : char};
fun f10 x = case x of {r : {a : int, b : bool, a : string, b : char}} => r;
type t11 = {a : int, b : bool, a : string, b : char} * int;
fun f12 x : {a : int, b : bool, a : string, b : char} = x;
