fun f x = x + 1
functor F(S : sig end) = struct fun g x = f x end
structure S = F(struct end);
