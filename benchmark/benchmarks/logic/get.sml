(* get.sml *)

structure Get = 
struct
  local
    open Term Trail Unify
  in
	fun get_structure (t, c, n) sc =
	    let
		fun newrefs 0 = nil
		  | newrefs n = REF(ref(NONE))::newrefs(n-1)

		fun gs (REF(r)) =
		    let
			val ts = newrefs n
		    in
			(bind(r, STR(c, ts));
			 sc ts)
		    end
		  | gs (STR(f,args)) =
		    if (c = f)
			then sc (args)
		    else ()
		  | gs _ = raise BadArg "get_structure"
	    in
		gs (deref t)
	    end

	fun get_const (t, c) sc =
	   let
	      fun gs (REF(r)) =
		 (bind(r, CON c);
		  sc ())
		| gs (CON(f)) =
		 if (c = f) then
		    sc ()
		 else ()
		| gs _ = raise BadArg "get_const"
	   in
	      gs (deref t)
	   end

	fun get_integer (t, c) sc =
	   let
	      fun gs (REF(r)) =
		 (bind(r, INT c);
		  sc ())
		| gs (INT(f)) =
		 if (c = f) then
		    sc ()
		 else ()
		| gs _ = raise BadArg "get_integer"
	   in
	      gs (deref t)
	   end
  end (* local *)
end; (* Get *)

