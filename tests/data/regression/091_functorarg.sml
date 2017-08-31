functor F (
  structure S : sig val x : int end
  structure T : sig val y : word end
) =
struct
end

structure A = F (
structure S = struct val x = 1 end
structure T = struct val y = 0w1 end
);

(*
2011-08-30 katsu

This causes an unexpected type error.

091_functorarg.sml:8.15-11.1 Error:
  (type inference 007) operator and operand don't agree
  operator domain: word(t1[]), int(t0[])
  operand: int(t0[]), word(t1[])
*)
