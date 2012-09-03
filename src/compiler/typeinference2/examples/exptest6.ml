fun id x = x;
fn () =>
let
  val x = fn x => (x,x)
  val x = x (x id)
  val x = x (x id)
  val x = x (x id)
  val x = x (x id)
  val x = x (x id)
in
(#1 (#1 (#1(#1 (#1 (#1 (#1 (#1 
(x 1)
))))))))
end
;
