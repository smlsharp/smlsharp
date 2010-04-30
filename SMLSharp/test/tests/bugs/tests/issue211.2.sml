functor F () : sig val x : unit end = struct val x = () end
structure P = struct end;

structure S1 = F(P) structure S2 = F(P);
