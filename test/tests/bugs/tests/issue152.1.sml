signature S23 =
sig
  eqtype s
  datatype t = D of real
  sharing type s = t
end;
structure S23 : S23 = struct datatype t = D of real type s = t end;

