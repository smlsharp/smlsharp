(*
 * The typed pattern calculus for the core
 * Patters are explicitly typde.
 * Copyright 2001
 * Atsushi Ohori 
 * JAIST, Ishikawa Japan. 
 *)
structure PLUtil = struct
local open PatternCalc
in
    fun freeVarsExp exp =
	case exp of
	    PLCONSTANT _ => SSet.empty
	  | PLVAR (name,_) => SSet.singleton name
          | PLTYPED (ex,_,_) => freeVarsExp ex
	  | PLAPP (ex1,ex2,_) => SSet.union (freeVarsExp ex1,freeVarsExp ex2)
	  | PLLET (decls,exps,_) =>
		let val (bounds,decfrees) = freeVarsDecs decls 
		in
		    foldr 
		    (fn (ex,s) =>
		        let val fs = freeVarsExp ex
                        in SSet.union(SSet.difference(fs,bounds),
				      s)
			end)
		    decfrees
		    exps
		end
	  | PLMONOLET (binds,exp) =>freeVarsExp (PLLET ([PDVAL1 (nil,
								  binds,(Absyn.nopos,Absyn.nopos))],
							 [exp],(Absyn.nopos,Absyn.nopos)))
	  | PLRECORD (fields,_) =>
               foldr
	         (fn ((_,ex),s) => SSet.union (freeVarsExp ex,s))
                 SSet.empty
                 fields
          | PLRAISE (ex,_) => freeVarsExp ex
	  | PLHANDLE (ex1,rules,_) =>
               SSet.union (freeVarsExp ex1,
			   foldr 
			     (fn (r,s) =>SSet.union (freeVarsRule r,s))
			     SSet.empty
			     rules)
	  | PLFN (rules,_) => 
	       foldr 
	       (fn (r,s) =>SSet.union (freeVarsRule r,s))
	       SSet.empty
	       rules
	  | PLCASE (ex,rules,_,_) => 
	       foldr 
	       (fn (r,s) =>SSet.union (freeVarsRule r,s))
	       (freeVarsExp ex)
	       rules
          | PLRECORD_SELECTOR _ => SSet.empty
          | PLSELECT (l,ex,_) => freeVarsExp ex
          | PLSEQ (exps,_) =>                
	       foldr
	         (fn (ex,s) => SSet.union (freeVarsExp ex,s))
                 SSet.empty
                 exps


    and freeVarsRule (pat,exp) =
	let val bounds = freeVarsPat pat
            val vars = freeVarsExp exp
	in
	    SSet.difference (vars,bounds)
	end
    and freeVarsPat pat =
        case pat of
	    PLPATWILD _  => SSet.empty
	  | PLPATID (name,_) => SSet.singleton name
	  | PLPATCONSTANT _ => SSet.empty
	  | PLPATCONSTRUCT (pat1,pat2,_) => SSet.union(freeVarsPat pat1,freeVarsPat pat2)
	  | PLPATRECORD (_,fields,_) => 
		foldr 
		(fn ((_,pat),s) => SSet.union (freeVarsPat pat,s))
		SSet.empty 
		fields
	  | PLPATLAYERED (name,_,pat,_) => SSet.union(SSet.singleton name,freeVarsPat pat)
	  | PLPATTYPED (pat,_,_) => freeVarsPat pat
   and freeVarsDec dec =
       case dec of
	   PDVAL1 (_,valbinds,_) =>
	       (foldr 
		(fn ((v,_),s) => SSet.add(s,v))
		SSet.empty
		valbinds,
		foldr 
		(fn ((_,exp),s) => SSet.union(freeVarsExp exp,s))
		SSet.empty
		valbinds)
	 | PDVAL (_,valbinds,_) =>
	       (foldr 
		(fn ((pat,_),s) => SSet.union(freeVarsPat pat,s))
		SSet.empty
		valbinds,
		foldr 
		(fn ((_,exp),s) => SSet.union(freeVarsExp exp,s))
		SSet.empty
		valbinds)
         | PDVALREC (_,recbinds,_) =>
	       let val bounds = foldr 
		   (fn ((_,exp),s) => SSet.union(freeVarsExp exp,s))
		   SSet.empty
		   recbinds
		   val frees = 
		       foldr 
		       (fn ((_,exp),s) => SSet.union(SSet.difference(freeVarsExp exp,bounds),s))
		       SSet.empty
		       recbinds
	       in
		   (bounds,frees)
	       end
	 | PDLOCALDEC (decls1,decls2,_) =>
	       let val (bounds1,frees1) = freeVarsDecs decls1
		   val (bounds2,frees2) = freeVarsDecs decls2
	       in
		   (bounds2,SSet.union(frees1,SSet.difference(frees2,bounds1)))
	       end
         | PDEMPTY => (SSet.empty,SSet.empty)
	 | PDTYPE _ => (SSet.empty,SSet.empty)
	 | PDDATATYPE _ => (SSet.empty,SSet.empty)
	 | PDREPLICATEDAT _ => (SSet.empty,SSet.empty)
	 | PDEXD _ => (SSet.empty,SSet.empty)
	 | PDEXREP _ => (SSet.empty,SSet.empty)
   and freeVarsDecs decls =   
       foldr 
       (fn (x,(bs,fs)) => 
	let val (bs',fs') = freeVarsDec x
	in
	    (SSet.union (bs,bs'),
	     SSet.union(SSet.difference (fs',bs),
			fs))
	end)
       (SSet.empty,SSet.empty)
       decls
end
end
