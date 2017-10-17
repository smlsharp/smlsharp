fun id x = x;
val f2 = fn (x : 'a) => fn y => (x, y);
val fPolyVar12 = f2 id;
val xPolyVar12 = fPolyVar12 1;

(*
2012-05-18 katsu

When the above input is inputed to the interactive mode, warning of dummy
type is caused twice.

# fun id x = x;
val id = _ : ['a. 'a -> 'a]
# val f2 = fn (x : 'a) => fn y => (x, y);
val f2 = _ : ['a. 'a -> ['b. 'b -> 'a * 'b]]
# val fPolyVar12 = f2 id;
(BuiltinContext.smi):43.11-43.14 Warning:
 (type inference 065) dummy type variable(s) are introduced due to value
 restriction in: fPolyVar12
val fPolyVar12 = _ : ['a. 'a -> (?X1 -> ?X1) * 'a]
# val xPolyVar12 = fPolyVar12 1;
(BuiltinContext.smi):43.11-43.14 Warning:
 (type inference 065) dummy type variable(s) are introduced due to value
 restriction in: xPolyVar12
val xPolyVar12 = (fn, 1) : (?X1 -> ?X1) * int

(***** ^^ The second warning should not be caused since the dummy type
variable ?X1 is already introduced *****)

*)
(*
2012-07-11 ohori fixed by 4300:a624ccfe0bc7
*)
