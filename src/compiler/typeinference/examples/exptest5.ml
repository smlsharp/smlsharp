fn () =>
let
  val x = fn x => (x,x)
  val x = fn y => x (x y)
  val x = fn y => x (x y)
  val x = fn y => x (x y)
  val x = fn y => x (x y)
  val x = fn y => x y
in
(#1 (#1 (#1(#1 (#1 (#1 (#1 (#1 
(#1 (#1 (#1(#1 (#1 (#1 (#1 (#1 
(x 1)
))))))))
))))))))
end
;
