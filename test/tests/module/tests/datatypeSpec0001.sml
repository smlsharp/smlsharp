(*
multiplicity of datatype specification

<ul>
  <li>the number of constructor in a datatype description
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of names in a specification
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of datatype specifications in a signature
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
signature S111 = 
sig
  datatype t = D
end;

signature S121 = 
sig
  datatype t = D and s = E
end;

signature S122 = 
sig
  datatype t = D and s = E
  datatype v = F and u = G
end;

signature S211 = 
sig
  datatype t = D | E 
end;

signature S221 = 
sig
  datatype t = D | E and s = F | G
end;

signature S222 = 
sig
  datatype t = E | D and s = G | F
  datatype u = H | I and v = J | K
end;

