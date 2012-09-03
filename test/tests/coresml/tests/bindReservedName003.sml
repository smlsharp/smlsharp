(*
Reserved names may not be bound by id in pattern row of abbreviated form "label < : ty> < as pat >" in val binding.

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

val {true} = {true = 1};
val {false} = {false = 1};
val {nil} = {nil = 1};
val {::} = {:: = 1};
val {ref} = {ref = 1};

val {true : int} = {true = 1};
val {false : int} = {false = 1};
val {nil : int} = {nil = 1};
val {:: : int} = {:: = 1};
val {ref : int} = {ref = 1};

val {true as x} = {true = 1};
val {false as x} = {false = 1};
val {nil as x} = {nil = 1};
val {:: as x} = {:: = 1};
val {ref as x} = {ref = 1};

val {true : int as x} = {true = 1};
val {false : int as x} = {fasle = 1};
val {nil : int as x} = {nil = 1};
val {:: : int as x} = {:: = 1};
val {ref : int as x} = {ref = 1};

