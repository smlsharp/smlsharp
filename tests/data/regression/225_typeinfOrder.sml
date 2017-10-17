fn x => (x 1; x true);
fn x => let val {a=x,b=y} = {a = x 1, b = x = x} in (x,y) end;
fn x => let val y = 1 in x 1; x = x  end;
fn x => {a = x 1, b = x = x};
fn x => let val _ = x 1 and _ = x = x in 1 end;
fn x => let val rec f = fn () => x 1 and g = fn () => x = x in 1 end;
(* 2012-7-27 ohori:
  The inference should be done from left to right so 
  that the error should be reported at x true. 

(interactive):1.10-1.12 Error:
  (type inference 007) operator and operand don't agree
  operator domain: bool
  operand: 'F::{int,
                SMLSharp.IntInf.int,
                ('D::{int, int option}, 'E) SMLSharp.SQL.value}

(interactive):2.34-2.34 Error:
  (type inference 008) operator is not a function: ''C

(interactive):3.26-3.26 Error:
  (type inference 008) operator is not a function: ''Q

# (interactive):1.14-1.14 Error:
  (type inference 008) operator is not a function: ''C

(interactive):2.21-2.25 Error:
  (type inference 019) operator and operand don't agree
  operator domain: ''Q * ''Q
  operand: ('P::{int,
                 SMLSharp.IntInf.int,
                 ('K::{int, int option}, 'L) SMLSharp.SQL.value}
              -> 'O)
           * ('P::{int,
                   SMLSharp.IntInf.int,
                   ('K::{int, int option}, 'L) SMLSharp.SQL.value}
                -> 'O)

*)

(* 2012-7-27 ohori:
Fixed by 4348:f2e56be3bf3a - 4358:eea5c794057b.
*)
