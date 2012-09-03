(*
An expression any of whose subexpression is expansive is typed to monomorphic.
These cases are monomorphic typed in SML type system, but IML types them polymorphic.
<ul>
  <li>expansive expression
    <ul>
      <li>record any of whose field is expansive</li>
      <li>let expression</li>
      <li>function application</li>
      <li>application of constructor to expansive</li>
      <li>application of typed constructor to expansive</li>
      <li>application of "ref" constructor</li>
      <li>typed expansive</li>
      <li>handle expression</li>
      <li>raise expression</li>
      <li>case expression</li>
    </ul>
  </li>
</ul>
*)
fun id x = x;

val vrecord = {a = id, b = id 1};

val vlet = let in id end;

val vapp1 = (fn x => x) (fn x => x);
val vapp2 = (fn x => x) id;
val vapp3 = id (fn x => x);

datatype 'a dt1 = D of int;
val vconstructed1 = D (id 2);
(*
val vtypedconstructed1 = (D : int -> 'a dt1) 2;
*)

val vref1 = ref id;
val vref2 = {a = id, b = ref 1};

(*
val vtyped1 = id : 'a -> 'a;
*)
val vhandle = id handle e => id;

exception E;
val vraise = fn (x : int) => D (raise E);

val vcase1 = case id 2 of x => id;
val vcase2 = case 2 of x => (id, id 2);
