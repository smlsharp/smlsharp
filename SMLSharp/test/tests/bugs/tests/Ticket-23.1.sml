fun f x =
    let
      exception F of int
    in
      if x = 0
      then raise F 0
      else (f (x - 1)) handle F n => n
    end;
f 1;
