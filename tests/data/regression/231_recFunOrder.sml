fn x => let val rec f = fn () => x 1 and g = fn () => x = x in 1 end;
fn x => let fun f () = x 1 and g () = x = x in 1 end;
fn x => let fun f () = (x 1; g()) and g () = (x = x; f x) in 1 end;
fn x => let val rec f = fn () => (x 1; g()) and g = fn () => (x = x; f x) in 1 end;
fn x => let val rec f = fn () => x = x and g = fn () => x 1 in 1 end;
fn x => let fun f () = x = x and g () = x 1 in 1 end;
fn x => let fun f () = (x = x; g()) and g () = (x x; f x) in 1 end;
fn x => let val rec f = fn () => (x = x; g()) and g = fn () => (x 1; f x) in 1 end;

(* 2012-8-4 ohori compiler/util/main/SCCFun.sml:
  SCC returns 
   * the non-connected forests in reversed order
   * elements in a connected componets in reversed order
  The strightforwardly coding the original SCC algorithm 
  results in this; i.e. the original scc algorithm visits 
  the G^T in the decreasing order of the finished time in G.
  So when we use scc in fundecls, we do the followng.
  * We make the reference ege (instead of presedence edge)
      f -> g iff fun f x = ... g  
    so that  f-componet comes earlier than g-componet in the result of
    ssc.
    This is consistent of the original order of occurrences.
  * We then take the reversal of the reversal of ssc.
    The inner reversal is necessary since the scc make a list 
    of elements in each scc-componet in reverse order ot their
    "discovery time".
*)
(* 2012-8-4 ohori
   Fixed by 4369:a93a16990a4b
 *)
