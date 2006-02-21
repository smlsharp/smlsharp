(*
 equal operator for base types.

<ul>
  <li>type
    <ul>
      <li>int</li>
      <li>word</li>
      <li>char</li>
      <li>string</li>
    </ul>
  </li>
</ul>
 *)

val int1 = 1 = 1;
val int2 = 0 = 1;
val int3 = 0 = ~1;

val word1 = 0w1 = 0w1;
val word2 = 0w0 = 0w1;

val char1 = #"a" = #"a";
val char2 = #"a" = #"b";

val string1 = "a" = "a";
val string2 = "a" = "b";
val string3 = "" = "";
val string4 = "a" = "";
val string5 = "a" = "ab";
