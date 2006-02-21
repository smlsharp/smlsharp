let
   val f = fn x => ref x
in
   f 3 ; f true
end;
