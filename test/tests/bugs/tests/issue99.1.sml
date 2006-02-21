signature S31 =
sig
  datatype s = D of real
  type t
  sharing type s = t
end;
structure S31 : S31 = 
struct datatype s = D of real datatype t = datatype s end;
