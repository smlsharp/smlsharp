(*
eqtype check for type declared in a constrainted structure.

*)

signature SEq = sig eqtype t end;
signature SNonEq = sig type t end;

structure S1 = struct type t = int end;
structure S11 = S1 : SEq;
structure S12 = S11 : SNonEq;

structure S2 = struct type t = real end;
structure S21 = S2 : SNonEq;
structure S22 = S21 : SEq;

