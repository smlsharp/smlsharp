(*
equal operator for constructed type.

<ul>
  <li>type of contents
    <ul>
      <li>constant constructor</li>
      <li>constant constructor with multiple data constructor</li>
      <li>monomorphic eq type constructor</li>
      <li>monomorphic eq type constructor with multiple constructors</li>
      <li>polymorphic eq type constructor</li>
      <li>polymorphic eq type constructor with multiple constructors</li>
      <li>monomorphic nested eq type constructor with multiple constructors
      </li>
      <li>polymorphic nested eq type constructor with multiple constructors
      </li>
    </ul>
  </li>
</ul>
 *)

local
  datatype t1 = D11;
in
val t11 = D11 = D11;
end;

local
  datatype t2 = D21 | D22;
in
val t21 = D21 = D21;
val t22 = D21 = D22;
end;

local
  datatype t3 = D31 of int;
in
val t31 = (D31 0) = (D31 0);
val t32 = (D31 0) = (D31 1);
end;

local
  datatype t4 = D41 of int | D42 of int;
in
val t41 = (D41 0) = (D41 0); (* same constructor, equal arg *)
val t42 = (D41 0) = (D41 1); (* same constructor, dif arg *)
val t43 = (D41 0) = (D42 0); (* dif constructor, equal arg *)
val t44 = (D41 0) = (D42 1); (* dif constructor, dif arg *)
end;

local
  datatype 'a t5 = D51 of 'a;
in
val t51 = (D51 0) = (D51 0);
val t52 = (D51 0) = (D51 1);
end;

local
  datatype 'a t6 = D61 of 'a | D62 of int;
in
val t61 = (D61 0) = (D61 0); (* same constructor, equal arg *)
val t62 = (D61 0) = (D61 1); (* same constructor, dif arg *)
val t63 = (D61 0) = (D62 0); (* dif constructor, equal arg *)
val t66 = (D61 0) = (D62 1); (* dif constructor, dif arg *)
end;

local
  datatype t71 = D711 | D712
  datatype t72 = D721 of t71 | D722 of t71;
in
val t71 = (D721 D711) = (D721 D711); (* same constructor, equal arg *)
val t72 = (D721 D711) = (D721 D712); (* same constructor, dif arg *)
val t73 = (D721 D711) = (D722 D711); (* dif constructor, equal arg *)
val t74 = (D721 D711) = (D722 D712); (* dif constructor, dif arg *)
end;

local
  datatype t81 = D811 | D812
  datatype 'a t82 = D821 of 'a | D822 of 'a;
in
val t81 = (D821 D811) = (D821 D811); (* same constructor, equal arg *)
val t82 = (D821 D811) = (D821 D812); (* same constructor, dif arg *)
val t83 = (D821 D811) = (D822 D811); (* dif constructor, equal arg *)
val t84 = (D821 D811) = (D822 D812); (* dif constructor, dif arg *)
end;
