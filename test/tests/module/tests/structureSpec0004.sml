(*
"where type" sigexp in a inner structure specification.

<ul>
  <li>left type constructor
    <ul>
      <li>declared by type spec</li>
      <li>declared by datatype spec</li>
    </ul>
  </li>
  <li>right type constructor
    <ul>
      <li>declared by type spec</li>
      <li>declared by datatype spec</li>
    </ul>
  </li>
  <li>left and right type constructors have same name
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
</ul>
*)
signature S111 =
sig
  type t
  structure S : sig type s end
    where type s = t
end;

signature S112 =
sig
  type t
  structure S : sig type t end
    where type t = t
end;

signature S121 =
sig
  datatype dt = D
  structure S : sig type t end where type t = dt
end;

signature S122 =
sig
  datatype t = D
  structure S : sig type t end where type t = t
end;

signature S211 =
sig
  type t
  structure S : sig datatype dt = D end where type dt = t
end;

signature S212 =
sig
  type t
  structure S : sig datatype t = D end where type t = t
end;

signature S221 =
sig
  datatype s = D
  structure S : sig datatype t = E end where type t = s
end;

signature S222 =
sig
  datatype t = D
  structure S : sig datatype t = E end where type t = t
end;

