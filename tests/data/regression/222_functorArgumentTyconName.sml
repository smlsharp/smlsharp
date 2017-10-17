functor FFF(S : sig datatype foo = A of int end) =
  struct
     datatype hoge = B of S.foo
  end
structure P = struct datatype foo = A of int end;
structure A = FFF(P);
A.B;


(* 2012-7-22 ohori.
The tycon name originated from the functor argument is
not printed properly.
> > > > FFF
structure P =
  struct
    datatype foo = A of int
  end
# structure A =
  struct
    datatype hoge = B of P.foo
  end
# val it = fn : P.foo -> hoge
# 
The hoge should be A.hoge.
*)

(* 2012-7-24 ohori. Fixed 
*)
