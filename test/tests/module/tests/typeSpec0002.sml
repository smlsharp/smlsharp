(*
arity of type specification

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
  type 'a t
end;

signature S21 = 
sig
  type ('a, 'b) t
end;

signature S31 = 
sig
  type ('c, 'b, 'a) t
end;

signature S32 = 
sig
  type ('ac, 'ab, 'a) t and ('a, 'ab, 'aa) s
end;
