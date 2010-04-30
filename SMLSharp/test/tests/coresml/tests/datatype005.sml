(*
name resolution within a datatype declaration with "withtype".

<ul>
  <li>the number of type constructors in datatype
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of type constructors in withtype
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>name bound in withtype is used in datatype.
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
  <li>name bound in datatype is used in withtype.
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
</ul>
*)
datatype dt11nn1 = D11nn1 withtype t11nn1 = int;
val dt11nn1 = D11nn1;
val t11nn1 = 1 : t11nn1;

datatype dt11ny1 = D11ny1 withtype t11ny1 = int * dt11ny1;
val dt11ny1 = D11ny1;
val t11ny1 = (1, D11ny1) : t11ny1;

datatype dt11yn1 = D11yn1 of t11yn1 withtype t11yn1 = int;
val dt11yn1 = D11yn1 1;
val t11yn1 = 1 : t11yn1;

datatype dt11yy1 = D11yy1 of t11yy1 | E11yy1 withtype t11yy1 = dt11yy1 * int;
val dt11yy1 = D11yy1(E11yy1, 1);
val t11yy1 = (E11yy1, 1) : t11yy1;

datatype dt22nn1 = D22nn1 and dt22nn2 = D22nn2 
withtype t22nn1 = int and t22nn2 = int * int;
val dt22nn1 = D22nn1;
val dt22nn2 = D22nn2;
val t22nn1 = 1 : t22nn1;
val t22nn2 = (2, 3) : t22nn2;

datatype dt22ny1 = D22ny1 and dt22ny2 = D22ny2 
withtype t22ny1 = dt22ny1 * int and t22ny2 = int * int * dt22ny2;
val dt22ny1 = D22ny1;
val dt22ny2 = D22ny2;
val t22ny1 = (D22ny1, 1) : t22ny1;
val t22ny2 = (2, 3, D22ny2) : t22ny2;

datatype dt22yn1 = D22yn1 of t22yn2 * int and dt22yn2 = D22yn2 of t22yn1 * int
withtype t22yn1 = int and t22yn2 = int * int;
val dt22yn1 = D22yn1;
val dt22yn2 = D22yn2;
val t22yn1 = 1 : t22yn1;
val t22yn2 = (2, 3) : t22yn2;

datatype dt22yy1 = D22yy1 of t22yy2 * int | E22yy1
and dt22yy2 = D22yy2 of t22yy1 * int | E22yy2
withtype t22yy1 = int * dt22yy2 and t22yy2 = int * int * dt22yy1;
val dt22yy1 = D22yy1((1, 2, E22yy1), 3);
val dt22yy2 = D22yy2((2, E22yy2), 3);
val t22yy1 = (4, E22yy2) : t22yy1;
val t22yy2 = (5, 6, E22yy1) : t22yy2;
