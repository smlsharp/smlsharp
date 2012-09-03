(*
multiplicity of structure specification.

<ul>
  <li>the number of names in a specification
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
  <li>the number of structure specifications in a signature
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
signature S11 =
sig
  structure S : sig end
end;

signature S12 =
sig
  structure T : sig end
  structure S : sig end
end;

signature S21 =
sig
  structure T : sig end and S : sig end
end;

signature S22 =
sig
  structure S : sig end and T : sig end
  structure U : sig end and V : sig end
end;
