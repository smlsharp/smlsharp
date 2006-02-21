(*
ref constructor.

<ul>
  <li>type of contents
    <ul>
      <li>int</li>
      <li>real</li>
      <li>word</li>
      <li>char</li>
      <li>string</li>
      <li>constructed type</li>
      <li>ref type</li>
    </ul>
  </li>
</ul>
 *)
val v11 = ref 1;
val _ = v11 := 2;
val v12 = ! v11;

val v21 = ref 1.23;
val _ = v21 := 2.34;
val v22 = ! v21;

val v31 = ref 0w1;
val _ = v31 := 0w3;
val v32 = ! v31;

val v41 = ref #"a";
val _ = v41 := #"z";
val v42 = ! v41;

val v51 = ref "foo";
val _ = v51 := "bar";
val v52 = ! v51;

datatype t6 = C61 of int | C62 of string;
val v61 = ref (C61 6);
val _ = v61 := C62 "foo";
val v62 = ! v61;

val v71 = ref (ref (1, 2));
val _ = (! v71) := (2, 3);
val v72 = ! (! v71);
val _ = v71 := ref (3, 4);
val v73 = ! v71;
