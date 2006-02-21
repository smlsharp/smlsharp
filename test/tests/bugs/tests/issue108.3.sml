signature S0 = sig type t end;
structure S0datatypeTrans : S0 = struct datatype 'a t = D of int * 'a end;
