(*
overloaded primitive operators.

<ul>
  <li>operator
    <ul>
      <li>abs</li>
      <li>~</li>
      <li>div</li>
      <li>mod</li>
      <li>*</li>
      <li>/</li>
      <li>+</li>
      <li>-</li>
      <li>&lt;</li>
      <li>&gt;</li>
      <li>&lt;=</li>
      <li>&gt;=</li>
    </ul>
  </li>
</ul>
 *)

(* abs is defined on realint *)
val abs_int1 = abs 2;
val abs_int2 = abs ~2;
val abs_real1 = abs 1.23;
val abs_real2 = abs ~1.23;

(* ~ is defined on realint *)
val neg_int1 = ~(2);
val neg_int2 = ~(~2);
val neg_real1 = ~(1.23);
val neg_real2 = ~(~1.23);

(* div is defined on wordint *)
val div_int = 5 div 2;
val div_word = 0w5 div 0w2;

(* mod is defined on wordint *)
val mod_int = 5 mod 2;
val mod_word = 0w5 mod 0w2;

(* * is defined on num *)
val mul_int = 2 * 3;
val mul_real = 1.2 * 2.3;
val mul_word = 0w2 * 0w3;

(* / is defined on real *)
val div_real = 4.0 / 2.0;

(* + is defined on num *)
val add_int = 1 + 2;
val add_real = 1.2 + 3.4;
val add_word = 0w1 + 0w2;

(* - is defined on num *)
val sub_int = 1 - 2;
val sub_real = 1.2 - 3.4;
val sub_word = 0w2 - 0w1;
val sub_word2 = 0w1 - 0w2;

(* < is defined on numtxt *)
val lt_int1 = 1 < 2;
val lt_int2 = 1 < 1;
val lt_int3 = 2 < 1;
val lt_real1 = 1.1 < 1.2;
val lt_real2 = 1.1 < 1.1;
val lt_real3 = 1.2 < 1.1;
val lt_word1 = 0w1 < 0w2;
val lt_word2 = 0w1 < 0w1;
val lt_word3 = 0w2 < 0w1;
val lt_char1 = #"a" < #"b";
val lt_char2 = #"a" < #"a";
val lt_char3 = #"b" < #"a";
val lt_string1 = "a" < "b";
val lt_string2 = "a" < "a";
val lt_string3 = "b" < "a";

(* > is defined on numtxt *)
val gt_int1 = 1 > 2;
val gt_int2 = 1 > 1;
val gt_int3 = 2 > 1;
val gt_real1 = 1.1 > 1.2;
val gt_real2 = 1.1 > 1.1;
val gt_real3 = 1.2 > 1.1;
val gt_word1 = 0w1 > 0w2;
val gt_word2 = 0w1 > 0w1;
val gt_word3 = 0w2 > 0w1;
val gt_char1 = #"a" > #"b";
val gt_char2 = #"a" > #"a";
val gt_char3 = #"b" > #"a";
val gt_string1 = "a" > "b";
val gt_string2 = "a" > "a";
val gt_string3 = "b" > "a";

(* <= is defined on numtxt *)
val lteq_int1 = 1 <= 2;
val lteq_int2 = 1 <= 1;
val lteq_int3 = 2 <= 1;
val lteq_real1 = 1.1 <= 1.2;
val lteq_real2 = 1.1 <= 1.1;
val lteq_real3 = 1.2 <= 1.1;
val lteq_word1 = 0w1 <= 0w2;
val lteq_word2 = 0w1 <= 0w1;
val lteq_word3 = 0w2 <= 0w1;
val lteq_char1 = #"a" <= #"b";
val lteq_char2 = #"a" <= #"a";
val lteq_char3 = #"b" <= #"a";
val lteq_string1 = "a" <= "b";
val lteq_string2 = "a" <= "a";
val lteq_string3 = "b" <= "a";

(* >= is defined on numtxt *)
val gteq_int1 = 1 >= 2;
val gteq_int2 = 1 >= 1;
val gteq_int3 = 2 >= 1;
val gteq_real1 = 1.1 >= 1.2;
val gteq_real2 = 1.1 >= 1.1;
val gteq_real3 = 1.2 >= 1.1;
val gteq_word1 = 0w1 >= 0w2;
val gteq_word2 = 0w1 >= 0w1;
val gteq_word3 = 0w2 >= 0w1;
val gteq_char1 = #"a" >= #"b";
val gteq_char2 = #"a" >= #"a";
val gteq_char3 = #"b" >= #"a";
val gteq_string1 = "a" >= "b";
val gteq_string2 = "a" >= "a";
val gteq_string3 = "b" >= "a";

