signature P = sig datatype t = D end;
signature Q = sig type t val f : t end;
signature S = sig structure P : P structure Q : Q sharing type P.t = Q.t end

functor F(S : S) = struct type t = S.P.t val f = S.Q.f end : Q;
