(*
matching of val specification with multiple bindings.

<ul>
  <li>the number of bindings of the specified name
    <ul>
      <li>2</li>
    </ul>
  </li>
  <li>type of bindings.
    <ul>
      <li>same matching type</li>
      <li>non matching type, matching type</li>
      <li>matching type, non matching type</li>
    </ul>
  </li>
</ul>
*)
signature S =
sig
  val x : int
end;

structure S1 : S =
struct
  val x = 1
  val x = 2
end;

structure S2 : S =
struct
  val x = "abc"
  val x = 2
end;

structure S3 : S =
struct
  val x = 3
  val x = "bcd"
end;
