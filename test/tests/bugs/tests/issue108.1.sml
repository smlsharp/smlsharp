signature S0 = sig type t end;
structure S0typeTrans : S0 = struct type 'a t = int * 'a end;