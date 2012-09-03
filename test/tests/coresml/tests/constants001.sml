(*
constant expressions.

<ul>
  <li>type of contents
    <ul>
      <li>int</li>
      <li>real</li>
      <li>word</li>
      <li>char</li>
      <li>string</li>
    </ul>
  </li>
</ul>
 *)
val plus_int = 1;
val minus_int = ~1;
val zero_int = 0;

val plus_real = 1.1;
val minus_real = ~1.1;
val zero_real = 0.0;

val plus_word = 0w1;
val zero_word = 0w0;
val plus_word16 = 0wxF;
val zero_word16 = 0wx0;

val char1 = #"a";
val char2 = #"\n";
val char3 = #"\r";
val char4 = #"\t";

val str1 = "";
val str2 = "a";
val str3 = "ab";
val str4 = "\n";
val str5 = "\r";
val str6 = "\t";
