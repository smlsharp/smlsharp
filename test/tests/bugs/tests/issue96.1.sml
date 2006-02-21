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
