(*
multiplicity of type specification

<ul>
  <li>the number of names in a specification
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of type specifications in a signature
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
signature S11 = 
sig
  type t
end;

signature S12 = 
sig
  type s
  type t
end;

signature S21 = 
sig
  type s and t
end;

signature S22 = 
sig
  type s and t
  type u and v
end;
