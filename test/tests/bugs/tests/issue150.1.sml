signature SIG = 
sig structure S : sig datatype dt = D end end;
structure P = struct end;

functor FTrans(S : sig end) = 
struct structure S = struct datatype dt = D end end : SIG;
structure STrans = FTrans(P);

functor FOpaque(S : sig end) = 
struct structure S = struct datatype dt = D end end :> SIG;
structure SOpaque = FOpaque(P);