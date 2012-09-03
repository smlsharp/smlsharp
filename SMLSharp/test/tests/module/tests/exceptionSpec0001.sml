(*
multiplicity of exception specification

<ul>
  <li>the number of names in a specification
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of exception specifications in a signature
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
signature S11 = 
sig
  exception e1
end;

signature S12 = 
sig
  exception e2
  exception e1
end;

signature S21 = 
sig
  exception e2 and e1
end;

signature S22 = 
sig
  exception e2 and e1
  exception f1 and f2
end;
