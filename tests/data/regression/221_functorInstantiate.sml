functor FFF(S : sig datatype foo = A of int end) =
  struct
     datatype hoge = B of S.foo
  end
structure P1 = struct datatype foo = A of int end
structure A1 = FFF(P1)
structure P2 = struct datatype foo = A of int end
structure A2 = FFF(P2);
A1.B (P1.A 1);
A2.B (P2.A 2);

(* 2012-7-22 ohori. This causes a type error;
  S.foo of A1.B is instantiated to P2.foo.
> > > > > > > FFF
structure A1 =
  struct
    datatype hoge (t548) = B of P2.foo
  end
structure A2 =
  struct
    datatype hoge (t551) = B of P2.foo
  end
structure P1 =
  struct
    datatype foo (t546) = A of int
  end
structure P2 =
  struct
    datatype foo (t549) = A of int
  end
# (interactive):9.1-9.12 Error:
  (type inference 016) operator and operand don't agree
  operator domain: P2.foo
  operand: P1.foo
# val it = _ : hoge
# 
*)

(* 2012-7-24 ohori. Fixed 
*)
