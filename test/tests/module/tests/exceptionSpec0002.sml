(*
arity of exception constructor in a exception specification

<ul>
  <li>exception constructor takes an argument
    <ul>
      <li>yes</li>
    </ul>
  </li>
  <li>the number of description in a exception specification
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
signature S1 = 
sig
  exception e of int
end;

signature S2 = 
sig
  exception e1 of string and e2 of int * bool
end;
