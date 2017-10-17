val s = #sign (Real.toDecimal 0.0);
val _ = case s of false => () | _ => raise Fail "ng"

(*
2013-01-25 ohori 
符号はfalseが正しい．
*)

