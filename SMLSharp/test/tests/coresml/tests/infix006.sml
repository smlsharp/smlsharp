(*
scope of infix declaration.
 *
<ul>
  <li>kind of local infix declaration
    <ul>
      <li>infix</li>
      <li>nonfix</li>
    </ul>
  </li>
  <li>local or let
    <ul>
      <li>local</li>
      <li>let</li>
    </ul>
  </li>
</ul>
 *)
datatype t = ## of int * int;

local
  infix 1 ##
  val lv1 = 1 ## 2
in
val v1 = 2 ## 3
end;
val gv1 = ## (3, 4);

val v2 =
    let
      infix 1 ##
      val lv2 = 2 ## 3
    in
      3 ## 4
    end;
val gv2 = ## (3, 4);

infix 1 ##

local
  nonfix ##
  val lv3 = ## (3, 4)
in
val v3 = ## (4, 5)
end;
val gv3 = 5 ## 6;

val v4 =
    let
      nonfix ##
      val lv4 = ## (4, 5)
    in
      ## (5, 6)
    end;
val gv4 = 6 ## 7;
