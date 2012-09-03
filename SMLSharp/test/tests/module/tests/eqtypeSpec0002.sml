(*
arity of eqtype specification

<ul>
  <li>the number of parameter types of a eqtype description
    <ul>
      <li>1</li>
      <li>2</li>
      <li>3</li>
    </ul>
  </li>
  <li>the number of description in a eqtype specification
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
signature S11 = 
sig
  eqtype 'a t
end;

signature S21 = 
sig
  eqtype ('a, 'b) t
end;

signature S31 = 
sig
  eqtype ('c, 'b, 'a) t
end;

signature S32 = 
sig
  eqtype ('ac, 'ab, 'a) t and ('a, 'ab, 'aa) s
end;
