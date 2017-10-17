signature A  = sig type f type g  end
(* 2012-8-4 ohori
 Signature prining problem:
# signature A = sig type f type g end;
signature A =
  sig
    type f type g
  end
*)

(* 2012-8-4 ohori 
  Fixed by 4366:92f02415aed6
*)

