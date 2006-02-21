(*
multiplicity of eqtype specification

<ul>
  <li>the number of names in a specification
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of eqtype specifications in a signature
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
signature S11 = 
sig
  eqtype t
end;

signature S12 = 
sig
  eqtype s
  eqtype t
end;

signature S21 = 
sig
  eqtype s and t
end;

signature S22 = 
sig
  eqtype s and t
  eqtype u and v
end;
