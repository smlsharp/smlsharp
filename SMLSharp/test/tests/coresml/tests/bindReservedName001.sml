(*
Reserved names may not be bound by constructor binding.

<ul>
  <li>binding
    <ul>
      <li>data constructor bind</li>
      <li>exception constructor bind</li>
    </ul>
  </li>
  <li>reserved name
    <ul>
      <li>true</li>
      <li>false</li>
      <li>nil</li>
      <li>::</li>
      <li>ref</li>
      <li>it</li>
    </ul>
  </li>
</ul>
*)

datatype dt = true;
datatype dt = false;
datatype dt = nil;
datatype dt = ::;
datatype dt = ref;
datatype dt = it;

exception true;
exception false of int;
exception nil;
exception ::;
exception ref;
exception it;
