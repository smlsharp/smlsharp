structure S1 = struct type t = int val x = 1 end :> sig type t val x : t end;
structure S2 = struct type t = real val y = 1.1 end :> sig type t val y : t end;
val eqCheck = S1.x = S2.y; (* cause error *)

(*
2012-07-12 fukasawa

For users' convenience, not only type names but also structure names
should be printed in error messages.

The above code causes the following error message:

(interactive):3.15-3.25 Error:
  (type inference 019) operator and operand don't agree
  operator domain: t * t
  operand: t * t

but it should be:
  operand: S1.t * S2.t
*)

(*
2012-07-15 ohori
Fixed by 4309:6422c6afb889.

I made a global change in type name management.
The new policy is to ignore type alias and to print the path 
that was used when the type was created. This seems to be
the only uniform and reasonable policy.

For the above code: the following is printed.
# structure S1 = struct type t = int val x = 1 end : sig type t val x : t end;
structure S1 =
  struct
    type t = int
    val x = 1 : int
  end
# structure S2 = struct type t = real val y = 1.1 end : sig type t val y : t end;
structure S2 =
  struct
    type t = real
    val y = 1.1 : real
  end
# val eqCheck = S1.x = S2.y; (* cause error *)
(interactive):3.15-3.25 Error:
  (type inference 019) operator and operand don't agree
  operator domain: int * int
  operand: int * real
# 

If we chage the signature constraint to be opaque, the following
is printed:
# structure S1 = struct type t = int val x = 1 end :> sig type t val x : t end;
structure S1 =
  struct
    type t = <hidden>
    val x = _ : S1.t
  end
# structure S2 = struct type t = real val y = 1.1 end :> sig type t val y : t end;
structure S2 =
  struct
    type t = <hidden>
    val y = _ : S2.t
  end
# val eqCheck = S1.x = S2.y; (* cause error *)
(interactive):7.15-7.25 Error:
  (type inference 019) operator and operand don't agree
  operator domain: ''Q * ''Q
  operand: S1.t * S2.t
# 
*)
