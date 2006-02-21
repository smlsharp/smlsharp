(*
arity of datatype specification

<ul>
  <li>the number of parameter types of a type description
    <ul>
      <li>1</li>
      <li>2</li>
      <li>3</li>
    </ul>
  </li>
  <li>the number of description in a type specification
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
signature S11 = 
sig
  datatype 'a t = D
end;

signature S12 = 
sig
  datatype 'c t = D and 'b s = E
end;

signature S21 = 
sig
  datatype ('b, 'a) t = D
end;

signature S31 = 
sig
  datatype ('b, 'c, 'a) t = D
end;

signature S32 = 
sig
  datatype ('b, 'c, 'a) t = D and ('z, 'y, 'x) s = E
end;

