(*
label duplication should be rejected.
<p>
The SML Definition says:
<BLOCKQUOTE>
No expression row, pattern row or type-expression row may bind the same lab
twice.
</BLOCKQUOTE>
</p>

<ul>
  <li>
    <ul>
      <li>record expression</li>
      <li>record pattern in case/fn expression</li>
      <li>record pattern in fun declaration</li>
      <li>record type expression in typed pattern</li>
      <li>record type expression in layered pattern</li>
      <li>record type expression in record type expression</li>
      <li>record type expression in constructed type expression</li>
      <li>record type expression in domain of function type expression</li>
      <li>record type expression in range of function type expression</li>
      <li>record type expression in typed expression</li>
      <li>record type expression in type bind</li>
      <li>record type expression in data constructor bind</li>
      <li>record type expression in exception constructor bind</li>
      <li>record type expression annotated with label in pattern row in
        derived form</li>
      <li>record type expression in tuple type expression</li>
      <li>record type expression in fun declaration in derived form</li>
    </ul>
  </li>
</ul>
*)
(* expression *)
val e1 = {a = 1, b = 4, a = 2, b = 3};

(* pattern *)
val p1 = fn {a = 1, b = 4, a = 2, b = 3} => 1;
val p2 = fn x => case x of {a = 1, b = 4, a = 2, b = 3} => 1;
fun p3 {a = 1, b = 4, a = 2, b = 3} = 1;

(* type expression *)
val t1 = fn x => case x of _ : {a : int, b : bool, a : string, b : char} => a;
val t2 =
    fn x => case x of x : {a : int, b : bool, a : string, b : char} as y => y;
val t3 = fn x => (x : {a : {a : int, b : bool, a : string, b : char}});
type t4 = {a : int, b : bool, a : string, b : char} option;
type t5 = {a : int, b : bool, a : string, b : char} -> int;
type t6 = int -> {a : int, b : bool, a : string, b : char};
val t7 = fn x => (x : {a : int, b : bool, a : string, b : char});
type t8 = {a : int, b : bool, a : string, b : char};
datatype t9 = D9 of {a : int, b : bool, a : string, b : char};
exception t10 of {a : int, b : bool, a : string, b : char};
fun t11 x = case x of {r : {a : int, b : bool, a : string, b : char}} => r;
type t12 = {a : int, b : bool, a : string, b : char} * int;
fun t13 x : {a : int, b : bool, a : string, b : char} = x;
