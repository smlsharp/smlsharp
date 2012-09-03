(*
use of alias type defined by a type declaration.

<ul>
  <li>occurrence of alias type
    <ul>
      <li>typed expression</li>
    </ul>
  </li>
  <li>actual type
    <ul>
      <li>atomic type</li>
      <li>monomorphic function type</li>
      <li>polymorphic function type</li>
      <li>record type</li>
    </ul>
  </li>
</ul>
*)
type t1 = int;
val x1 : t1 = 1;

type t2 = int -> int;
fun f21 x = x + 1;
val x21 = (f21 : t2) 1;
val f22 = f21 : t2
val x22 = f22 1;

type 'a t3 = 'a -> ('a * 'a);
fun f31 x = (x, x);
val x31 = (f31 : int t3) 1;
val f32 = f31 : int t3;
val x32 = f32 2;

type t4 = {a : int, b : string};
fun f (x : t4) = (#a x, #b x);
val x4 = f {a = 1, b = "abc"};

