(* makestring.sml *)

structure Makestring =
struct
  local
    open Term Name
  in
	fun makestring (STR(f,nil)) = f
	  | makestring (STR(f,ts)) = f ^ "(" ^ makestring_s ts ^ ")"
	  | makestring (REF(r)) = 
	    (case !r of 
		 SOME t => makestring t
	       | _ => name_of_var r)
	  | makestring (CON(f)) = f
	  | makestring (INT(i)) = Int.toString i
	and makestring_s nil = raise BadArg "makestring_s" (* can't happen *)
	  | makestring_s (t::nil) = makestring t
	  | makestring_s (t::ts) = makestring t ^ "," ^ makestring_s ts

	(* print substitution, represented as list of variable/term pairs *)
	fun makestrings l =
	    let
		fun ms [] = ".\n"
		  | ms ((s, t) :: rest) =
		    "\n" ^ s ^ " = " ^ (makestring t) ^ (ms rest)
	    in
		variable_names := l;
		next_made_up_variable_num := 0;
		ms l
	    end
  end (* local *)
end; (* Makestring *)

