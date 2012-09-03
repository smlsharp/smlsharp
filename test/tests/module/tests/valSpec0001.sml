(*
multiplicity of value specification

<ul>
  <li>the number of names in a specification
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of val specifications in a signature
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
signature S11 = 
sig
  val x : int
end;

signature S12 = 
sig
  val x : int
  val y : string
end;

signature S21 = 
sig
  val x : int and y : bool * string
end;

signature S22 = 
sig
  val x : int and y : bool * string
  val v : int -> int and w : {x : int, y : int list}
end;
