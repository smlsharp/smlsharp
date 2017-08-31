val _ = case Date.fmt "%c" (Date.fromTimeUniv Time.zeroTime) of
          "Thu Jan  1 00:00:00 1970" => () 
        | _ => raise Fail "Unexpected"

(*
2014-08-04 Sasaki

This code raises Fail exception unexpectedly since the assertion fails.

The value of Date.fmt "%c" (Date.fromTimeUniv Time.zeroTime) is
"Thu Jan  1 09:00:00 1970"
*)
