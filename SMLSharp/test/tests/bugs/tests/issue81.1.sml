structure S = struct fun f () = () end
structure S = struct fun f x = if x = 0 then S.f () else f (x - 1) end;
S.f 1;
