signature PSIG = sig type t end;
signature FSIG = sig type s end;
functor FTrans(S : PSIG) : FSIG = struct type s = S.t end;
