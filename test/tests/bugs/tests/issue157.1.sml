signature PSIG = sig datatype dt = D end;

functor FTrans(S : PSIG) = struct datatype ds = datatype S.dt end;
