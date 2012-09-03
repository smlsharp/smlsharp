signature SIG =
sig
  structure SIG1 : sig type s end
  structure SIG2 : sig type t end
  sharing type SIG2.t = SIG1.s
end;
functor F(P : SIG) = struct end;

structure S =
struct
  structure SIG1 = struct type s = int end
  structure SIG2 = struct type t = int end
end;

(* OK *)
structure T = F(S);

(* OK *)
structure SOpaque :> SIG = S;
structure T = F(SOpaque);

(* NG *)
structure STrans : SIG = S;
structure T = F(STrans);
