signature S23 =
sig
  eqtype s
  datatype t = D of real
  sharing type s = t
end;

signature S21 =
sig
  eqtype s
  type t
  sharing type s = t
end;
