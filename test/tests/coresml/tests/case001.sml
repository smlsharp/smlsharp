(*
case expression whose target is base type.

<ul>
  <li>type of target
    <ul>
      <li>int</li>
      <li>word</li>
      <li>char</li>
      <li>string</li>
    </ul>
  </li>
  <li>target expression
    <ul>
      <li>constant</li>
      <li>variable</li>
      <li>other expression</li>
    </ul>
  </li>
</ul>
 *)

(*****************************************************************************)

val case_intconst1 =
    case 1 of 0 => false | 1 => true | 2 => false | x => false;

local val int1 = 1
in
val case_intvar =
    case int1 of 0 => false | 1 => true | 2 => false | x => false
end;

local val int1 = 1
in
val case_intexp =
    case int1 + 1 of 1 => false | 2 => true | 3 => false | x => false
end;

(*****************************************************************************)

val case_wordconst1 =
    case 0w1 of 0w0 => false | 0w1 => true | 0w2 => false | x => false;

local val word1 = 0w1
in
val case_wordvar =
    case word1 of 0w0 => false | 0w1 => true | 0w2 => false | x => false
end;

local val word1 = 0w1
in
val case_wordexp =
    case word1 + 0w1 of 0w1 => false | 0w2 => true | 0w3 => false | x => false
end;

(*****************************************************************************)

val case_charconst1 =
    case #"a" of #"z" => false | #"a" => true | #"b" => false | x => false;

local val char1 = #"a"
in
val case_charvar =
    case char1 of #"z" => false | #"a" => true | #"b" => false | x => false
end;

local val f = fn x => #"b"
in
val case_charexp =
    case f #"a" of #"a" => false | #"b" => true | #"c" => false | x => false
end;

(*****************************************************************************)

val case_stringconst1 =
    case "a" of "z" => false | "a" => true | "b" => false | x => false;

local val string1 = "a"
in
val case_stringvar =
    case string1 of "z" => false | "a" => true | "b" => false | x => false
end;

local val f = fn x => "b"
in
val case_stringexp =
    case f "a" of "a" => false | "b" => true | "c" => false | x => false
end;

(*****************************************************************************)
