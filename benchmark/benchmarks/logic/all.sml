structure Term = 
struct
  datatype 'a option = SOME of 'a | NONE
	
  datatype term
      = STR of string * term list
    | INT of int
    | CON of string
    | REF of term option ref
	
  exception BadArg of string
end;

structure Trail = 
struct
  local
      open Term
      val global_trail = ref (nil : term option ref list)
      val trail_counter = ref 0
  in
      fun unwind_trail (0, tr) = tr
	| unwind_trail (n, r::tr) =
	  ( r := NONE ; unwind_trail (n-1, tr) )
	| unwind_trail (_, nil) =
	  raise BadArg "unwind_trail"

      fun reset_trail () = ( global_trail := nil )

      fun trail func =
	  let 
	      val tc0 = !trail_counter
	  in
	      ( func () ;
	       global_trail := 
	         unwind_trail (!trail_counter-tc0, !global_trail) ;
	       trail_counter := tc0 )
	  end
	
      fun bind (r, t) =
	  ( r := SOME t ;
	   global_trail := r::(!global_trail) ;
	   trail_counter := !trail_counter+1 )
  end (* local *)
end; (* Trail *)	

structure Unify =
struct
  local
    open Term Trail
    fun same_ref (r, REF(r')) = (r = r')
      | same_ref _ = false

    fun occurs_check r t =
	let
	    fun oc (STR(_,ts)) = ocs ts
	      | oc (REF(r')) = 
		(case !r' of
		     SOME(s) => oc s
		   | _ => r <> r')
	      | oc (CON _) = true
	      | oc (INT _) = true
	    and ocs nil = true
	      | ocs (t::ts) = oc t andalso ocs ts
	in
	    oc t
	end
    fun deref (t as (REF(x))) = 
	(case !x of 
	     SOME(s) => deref s
	   | _ => t)
      | deref t = t
    fun unify' (REF(r), t) sc = unify_REF (r,t) sc
      | unify' (s, REF(r)) sc = unify_REF (r,s) sc
      | unify' (STR(f,ts), STR(g,ss)) sc =
	if (f = g)
	    then unifys (ts,ss) sc
	else ()
      | unify' (CON(f), CON(g)) sc =
	if (f = g) then
	    sc ()
	else
	    ()
      | unify' (INT(f), INT(g)) sc =
	if (f = g) then
	    sc ()
	else
	    ()
      | unify' (_, _) sc = ()
    and unifys (nil, nil) sc = sc ()
      | unifys (t::ts, s::ss) sc =
	unify' (deref(t), deref(s))
	(fn () => unifys (ts, ss) sc)
      | unifys _ sc = ()
    and unify_REF (r, t) sc =
	if same_ref (r, t)
	    then sc ()
	else if occurs_check r t
		 then ( bind(r, t) ; sc () )
	     else ()
  in
    val deref = deref
    fun unify (s, t) = unify' (deref(s), deref(t))
  end (* local *)
end; (* Unify *)	 

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
			  val name = "X" ^ (makestring_int (!next_made_up_variable_num))
		      in
			  (*
			   * We wrap the references with the REF constructor
			   * so that the form of list entries that we add
			   * matches the form of the list we are given to
			   * start with.
			   *)
			  variable_names := (name, REF(r)) :: !variable_names;
			  inc next_made_up_variable_num;
			  name
		      end
	  end
  end (* local *)
end; (* Name *)

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
	  | makestring (INT(i)) = makestring_int i
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

structure Data =
struct
  local
    open Term Trail Unify Makestring
    val cons_s = "cons"
    val x_s = "x"
    val nil_s = "nil"
    val o_s = "o"
    val s_s = "s"
    val CON_o_s = CON(o_s)
    val CON_nil_s = CON(nil_s)
    val CON_x_s = CON(x_s)
  in
      fun exists sc = sc (REF(ref(NONE)))

fun move_horiz (T_1, T_2) sc = 
(
trail (fn () => 
(
trail (fn () => 
(
trail (fn () => 
(
trail (fn () => 
(
trail (fn () => 
(
trail (fn () => 
(
trail (fn () => 
(
trail (fn () => 
(
trail (fn () => 
(
trail (fn () => 
(
trail (fn () => 
exists (fn T => 
exists (fn TT => 
unify (T_1, STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, T])])]), TT])) (fn () => 
unify (T_2, STR(cons_s, [STR(cons_s, [CON_o_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, T])])]), TT])) (fn () => 
sc ())))))
;
exists (fn P1 => 
exists (fn P5 => 
exists (fn TT => 
unify (T_1, STR(cons_s, [STR(cons_s, [P1, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, STR(cons_s, [P5, CON_nil_s])])])])]), TT])) (fn () => 
unify (T_2, STR(cons_s, [STR(cons_s, [P1, STR(cons_s, [CON_o_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, STR(cons_s, [P5, CON_nil_s])])])])]), TT])) (fn () => 
sc ())))))
))
;
exists (fn P1 => 
exists (fn P2 => 
exists (fn TT => 
unify (T_1, STR(cons_s, [STR(cons_s, [P1, STR(cons_s, [P2, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, CON_nil_s])])])])]), TT])) (fn () => 
unify (T_2, STR(cons_s, [STR(cons_s, [P1, STR(cons_s, [P2, STR(cons_s, [CON_o_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, CON_nil_s])])])])]), TT])) (fn () => 
sc ())))))
))
;
exists (fn L1 => 
exists (fn P4 => 
exists (fn TT => 
unify (T_1, STR(cons_s, [L1, STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, STR(cons_s, [P4, CON_nil_s])])])]), TT])])) (fn () => 
unify (T_2, STR(cons_s, [L1, STR(cons_s, [STR(cons_s, [CON_o_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, STR(cons_s, [P4, CON_nil_s])])])]), TT])])) (fn () => 
sc ())))))
))
;
exists (fn L1 => 
exists (fn P1 => 
exists (fn TT => 
unify (T_1, STR(cons_s, [L1, STR(cons_s, [STR(cons_s, [P1, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, CON_nil_s])])])]), TT])])) (fn () => 
unify (T_2, STR(cons_s, [L1, STR(cons_s, [STR(cons_s, [P1, STR(cons_s, [CON_o_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, CON_nil_s])])])]), TT])])) (fn () => 
sc ())))))
))
;
exists (fn L1 => 
exists (fn L2 => 
exists (fn TT => 
unify (T_1, STR(cons_s, [L1, STR(cons_s, [L2, STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, CON_nil_s])])]), TT])])])) (fn () => 
unify (T_2, STR(cons_s, [L1, STR(cons_s, [L2, STR(cons_s, [STR(cons_s, [CON_o_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, CON_nil_s])])]), TT])])])) (fn () => 
sc ())))))
))
;
exists (fn T => 
exists (fn TT => 
unify (T_1, STR(cons_s, [STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, T])])]), TT])) (fn () => 
unify (T_2, STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_o_s, T])])]), TT])) (fn () => 
sc ()))))
))
;
exists (fn P1 => 
exists (fn P5 => 
exists (fn TT => 
unify (T_1, STR(cons_s, [STR(cons_s, [P1, STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [P5, CON_nil_s])])])])]), TT])) (fn () => 
unify (T_2, STR(cons_s, [STR(cons_s, [P1, STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_o_s, STR(cons_s, [P5, CON_nil_s])])])])]), TT])) (fn () => 
sc ())))))
))
;
exists (fn P1 => 
exists (fn P2 => 
exists (fn TT => 
unify (T_1, STR(cons_s, [STR(cons_s, [P1, STR(cons_s, [P2, STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, CON_nil_s])])])])]), TT])) (fn () => 
unify (T_2, STR(cons_s, [STR(cons_s, [P1, STR(cons_s, [P2, STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_o_s, CON_nil_s])])])])]), TT])) (fn () => 
sc ())))))
))
;
exists (fn L1 => 
exists (fn P4 => 
exists (fn TT => 
unify (T_1, STR(cons_s, [L1, STR(cons_s, [STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [P4, CON_nil_s])])])]), TT])])) (fn () => 
unify (T_2, STR(cons_s, [L1, STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_o_s, STR(cons_s, [P4, CON_nil_s])])])]), TT])])) (fn () => 
sc ())))))
))
;
exists (fn L1 => 
exists (fn P1 => 
exists (fn TT => 
unify (T_1, STR(cons_s, [L1, STR(cons_s, [STR(cons_s, [P1, STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, CON_nil_s])])])]), TT])])) (fn () => 
unify (T_2, STR(cons_s, [L1, STR(cons_s, [STR(cons_s, [P1, STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_o_s, CON_nil_s])])])]), TT])])) (fn () => 
sc ())))))
))
;
exists (fn L1 => 
exists (fn L2 => 
exists (fn TT => 
unify (T_1, STR(cons_s, [L1, STR(cons_s, [L2, STR(cons_s, [STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, CON_nil_s])])]), TT])])])) (fn () => 
unify (T_2, STR(cons_s, [L1, STR(cons_s, [L2, STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_o_s, CON_nil_s])])]), TT])])])) (fn () => 
sc ())))))
)
  | move_horiz _ _ = ()

and rotate (T_1, T_2) sc = 
exists (fn P11 => 
exists (fn P12 => 
exists (fn P13 => 
exists (fn P14 => 
exists (fn P15 => 
exists (fn P21 => 
exists (fn P22 => 
exists (fn P23 => 
exists (fn P24 => 
exists (fn P31 => 
exists (fn P32 => 
exists (fn P33 => 
exists (fn P41 => 
exists (fn P42 => 
exists (fn P51 => 
unify (T_1, STR(cons_s, [STR(cons_s, [P11, STR(cons_s, [P12, STR(cons_s, [P13, STR(cons_s, [P14, STR(cons_s, [P15, CON_nil_s])])])])]), STR(cons_s, [STR(cons_s, [P21, STR(cons_s, [P22, STR(cons_s, [P23, STR(cons_s, [P24, CON_nil_s])])])]), STR(cons_s, [ST
R(cons_s, [P31, STR(cons_s, [P32, STR(cons_s, [P33, CON_nil_s])])]), STR(cons_s, [STR(cons_s, [P41, STR(cons_s, [P42, CON_nil_s])]), STR(cons_s, [STR(cons_s, [P51, CON_nil_s]), CON_nil_s])])])])])) (fn () => 
unify (T_2, STR(cons_s, [STR(cons_s, [P51, STR(cons_s, [P41, STR(cons_s, [P31, STR(cons_s, [P21, STR(cons_s, [P11, CON_nil_s])])])])]), STR(cons_s, [STR(cons_s, [P42, STR(cons_s, [P32, STR(cons_s, [P22, STR(cons_s, [P12, CON_nil_s])])])]), STR(cons_s, [ST
R(cons_s, [P33, STR(cons_s, [P23, STR(cons_s, [P13, CON_nil_s])])]), STR(cons_s, [STR(cons_s, [P24, STR(cons_s, [P14, CON_nil_s])]), STR(cons_s, [STR(cons_s, [P15, CON_nil_s]), CON_nil_s])])])])])) (fn () => 
sc ())))))))))))))))))
  | rotate _ _ = ()

and move (T_1, T_2) sc = 
(
trail (fn () => 
(
trail (fn () => 
exists (fn X => 
exists (fn Y => 
unify (T_1, X) (fn () => 
unify (T_2, Y) (fn () => 
move_horiz (X, Y) sc)))))
;
exists (fn X => 
exists (fn X1 => 
exists (fn Y => 
exists (fn Y1 => 
unify (T_1, X) (fn () => 
unify (T_2, Y) (fn () => 
rotate (X, X1) (fn () => 
move_horiz (X1, Y1) (fn () => 
rotate (Y, Y1) sc))))))))
))
;
exists (fn X => 
exists (fn X1 => 
exists (fn Y => 
exists (fn Y1 => 
unify (T_1, X) (fn () => 
unify (T_2, Y) (fn () => 
rotate (X1, X) (fn () => 
move_horiz (X1, Y1) (fn () => 
rotate (Y1, Y) sc))))))))
)
  | move _ _ = ()

and solitaire (T_1, T_2, T_3) sc = 
(
trail (fn () => 
exists (fn X => 
unify (T_1, X) (fn () => 
unify (T_2, STR(cons_s, [X, CON_nil_s])) (fn () => 
unify (T_3, INT(0)) (fn () => 
sc ())))))
;
exists (fn N => 
exists (fn X => 
exists (fn Y => 
exists (fn Z => 
unify (T_1, X) (fn () => 
unify (T_2, STR(cons_s, [X, Z])) (fn () => 
unify (T_3, STR(s_s, [N])) (fn () => 
move (X, Y) (fn () => 
solitaire (Y, Z, N) sc))))))))
)
  | solitaire _ _ = ()

and solution1 (T_1) sc = 
exists (fn X => 
unify (T_1, X) (fn () => 
solitaire (STR(cons_s, [STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, CON_nil_s])])])])]), STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s,
 CON_nil_s])])])]), STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, CON_nil_s])])]), STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, CON_nil_s])]), STR(cons_s, [STR(cons_s, [CON_x_s, CON_nil_s]), CON_nil_s])])])])])
, X, STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [INT(0)])])])])])])])])])])])])])) sc))
  | solution1 _ _ = ()

and solution2 (T_1) sc = 
exists (fn X => 
unify (T_1, X) (fn () => 
solitaire (STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, CON_nil_s])])])])]), STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s,
 CON_nil_s])])])]), STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_o_s, STR(cons_s, [CON_x_s, CON_nil_s])])]), STR(cons_s, [STR(cons_s, [CON_x_s, STR(cons_s, [CON_x_s, CON_nil_s])]), STR(cons_s, [STR(cons_s, [CON_x_s, CON_nil_s]), CON_nil_s])])])])])
, X, STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [STR(s_s, [INT(0)])])])])])])])])])])])])])) sc))
  | solution2 _ _ = ()
  end (* local *)
end; (* Data *)

structure Main = 
struct
  local
    open Data
    exception Done
  in
    fun sol1 _ = exists(fn Z =>
			solution1 (Z) (fn () => (print "yes\n"; raise Done)))

    fun sol2 _ = exists(fn Z =>
			solution2 (Z) (fn () => (print "yes\n"; raise Done)))

    val _ = (sol2 ()) handle Done => ()
  end (* local *)
end; (* Main *)
