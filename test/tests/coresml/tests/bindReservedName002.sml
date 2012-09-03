(*
Reserved names may not be bound by id in pattern "id < : ty > < as pat >" in val binding.

<ul>
  <li>optinal type annotation
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
  <li>optinal layered pattern
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
  <li>reserved name
    <ul>
      <li>true</li>
      <li>false</li>
      <li>nil</li>
      <li>::</li>
      <li>ref</li>
    </ul>
  </li>
</ul>
*)

val true = true;
val false = false;
val nil = nil;
val op :: = op ::;
val ref = ref;

val true : bool = true;
val false : bool = false;
val nil : int list = nil;
val op :: : int * int list -> int list = fn (x, y) => x :: y;
val ref : int -> int ref = fn x => ref x;

val true as x = true;
val false as x = false;
val nil as x = nil;
val op :: as x = op ::;
val ref as x = ref;

val true : bool as x = true;
val false : bool as x = false;
val nil : int list as x = nil;
val op :: : int * int list -> int list as x = op ::;
val ref : int -> int ref as x = ref;
