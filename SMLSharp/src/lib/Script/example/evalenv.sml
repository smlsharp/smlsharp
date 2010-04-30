(* substitute environment reference. *)
val file = case argv of [] => stdIn | name :: _ => fopen name "r";
print
    (global_replace
	 "\\${?([a-zA-Z_]+)}?"
	 (fn [_, name] => env name)
	 (fgets file NONE));
