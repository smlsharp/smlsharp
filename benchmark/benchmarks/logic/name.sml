(* name.sml *)

structure Name = 
struct
  local
      open Term 
      (* some support code for remembering variable names for printing *)
  in
      val variable_names = ref (nil : (string * term) list)
      val next_made_up_variable_num = ref 0
      fun name_of_var r =
	  let
	      fun find_name nil = NONE
		| find_name ((name, REF(r')) :: rest) =
		  if r = r' then
		      SOME name
		  else
		      find_name rest
		| find_name (_ :: rest) =
		  (* this term is not a variable *)
		  find_name rest
	  in
	      case find_name (!variable_names)
		  of SOME name => name
		| NONE =>
		      let
			  val name = "X" ^ (Int.toString (!next_made_up_variable_num))
		      in
			  (*
			   * We wrap the references with the REF constructor
			   * so that the form of list entries that we add
			   * matches the form of the list we are given to
			   * start with.
			   *)
			  variable_names := (name, REF(r)) :: !variable_names;
			  next_made_up_variable_num := !next_made_up_variable_num+1;
			  name
		      end
	  end
  end (* local *)
end; (* Name *)

