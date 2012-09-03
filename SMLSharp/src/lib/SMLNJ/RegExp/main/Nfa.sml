structure Nfa : NFA = 
    struct 

	exception SyntaxNotHandled

	datatype move = Move of int * char option * int

	fun compareCharOption (NONE,NONE) = EQUAL
	  | compareCharOption (NONE,SOME (c)) = LESS
	  | compareCharOption (SOME(c),NONE) = GREATER
	  | compareCharOption (SOME(c),SOME(c')) = Char.compare (c,c')

	structure S = RegExpSyntax
	structure IntSet = 
	    ListSetFn (struct 
			   type ord_key = int 
			   val compare = Int.compare 
		       end)
	structure Int2Set = 
	    ListSetFn (struct
			   type ord_key = int * int
			   fun compare ((i1,i2),(j1,j2)) = 
			       case (Int.compare (i1,j1))
				 of EQUAL => Int.compare (i2,j2)
				  | v => v
		       end)
	structure MoveSet = 
	    ListSetFn (struct 
			   type ord_key = move 
			   fun compare (Move (i,c,j),Move (i',c',j')) =
			       (case (Int.compare (i,i'))
				    of EQUAL => 
					(case (compareCharOption (c,c')) 
					     of EQUAL => Int.compare (j,j')
					      | v => v)
				     | v => v)
		       end)
	structure CharSet = 
	    ListSetFn (struct
			   type ord_key = char
			   val compare = Char.compare
		       end)

	structure I = IntSet
	structure I2 = Int2Set
	structure M = MoveSet
	structure C = CharSet
	    
	(* create sets from lists *)
	fun iList l = I.addList (I.empty,l)
	fun mList l = M.addList (M.empty,l)

	datatype nfa = Nfa of {states : I.set,
			       moves : M.set,
			       accepting : I2.set}

	fun print (Nfa {states,moves,accepting}) = 
	    let val pr = TextIO.print
		val prI = TextIO.print o Int.toString
		val prI2 = TextIO.print o (fn (i1,i2) => (Int.toString i1))
		val prC = TextIO.print o Char.toString
	    in
		pr ("States: 0 -> ");
		prI (I.numItems (states)-1);
		pr "\nAccepting:";
		I2.app (fn k => (pr " "; prI2 k)) accepting;
		pr "\nMoves\n";
		M.app (fn (Move (i,NONE,d)) => (pr " ";
						prI i;
						pr " --@--> ";
						prI d;
						pr "\n")
	                | (Move (i,SOME c,d)) => (pr " ";
						  prI i;
						  pr " --";
						  prC c;
						  pr "--> ";
						  prI d;
						  pr "\n")) moves
	    end

	fun nullAccept n = Nfa {states=iList [0,1], moves=M.add (M.empty, Move (0,NONE,1)),
			        accepting=I2.singleton (1,n)}
	fun nullRefuse n = Nfa {states=iList [0,1], moves=M.empty,
				accepting=I2.singleton (1,n)}

	fun renumber n st = n + st
	fun renumberMove n (Move (s,c,s')) = Move (renumber n s, c, renumber n s')
 	fun renumberAcc n (st,n') = (n+st,n')

	fun build' n (S.Group e) = build' n e
	  | build' n (S.Alt l) = 
	      foldr (fn (Nfa {states=s1,
			      moves=m1,...},
			 Nfa {states=s2,
			      moves=m2,...}) => 
		     let val k1 = I.numItems s1
			 val k2 = I.numItems s2
			 val s1' = I.map (renumber 1) s1
			 val s2' = I.map (renumber (k1+1)) s2
			 val m1' = M.map (renumberMove 1) m1
			 val m2' = M.map (renumberMove (k1+1)) m2
		     in
			 Nfa {states=I.addList (I.union (s1',s2'),
						[0,k1+k2+1]),
			      moves=M.addList (M.union (m1',m2'),
					       [Move (0,NONE,1),
						Move (0,NONE,k1+1),
						Move (k1,NONE,k1+k2+1),
						Move (k1+k2,NONE,k1+k2+1)]),
			      accepting=I2.singleton (k1+k2+1,n)}
		     end)
	            (nullRefuse n) (map (build' n) l)
	  | build' n (S.Concat l) = 
	      foldr (fn (Nfa {states=s1,moves=m1,...},
			 Nfa {states=s2,moves=m2,accepting}) =>
		     let val k = I.numItems s1 - 1
			 val s2' = I.map (renumber k) s2
			 val m2' = M.map (renumberMove k) m2
			 val accepting' = I2.map (renumberAcc k) accepting
		     in
			 Nfa {states=I.union (s1,s2'),
			      moves=M.union (m1,m2'),
			      accepting=accepting'}
		     end)
	            (nullAccept n) (map (build' n) l)
	  | build' n (S.Interval (e,n1,n2)) = raise SyntaxNotHandled
	  | build' n (S.Option e) = build' n (S.Alt [S.Concat [], e])
	  | build' n (S.Plus e) = 
	      let val (Nfa {states,moves,...}) = build' n e
		  val m = I.numItems states
	      in
		  Nfa {states=I.add (states,m),
		       moves=M.addList (moves, [Move (m-1,NONE,m),
						Move (m-1,NONE,0)]),
		       accepting=I2.singleton (m,n)}
	      end
	  | build' n (S.Star e) = build' n (S.Alt [S.Concat [], S.Plus e])
          | build' n (S.MatchSet s) = 
	      if (S.CharSet.isEmpty s) then nullAccept (n)
	      else
		  let val moves = S.CharSet.foldl (fn (c,moveSet) => M.add (moveSet,Move (0,SOME c,1)))
		                                  M.empty s
		  in
		      Nfa {states=iList [0,1],
			   moves=moves,
			   accepting=I2.singleton (1,n)}
		  end
	  | build' n (S.NonmatchSet s) = 
	      let val moves = S.CharSet.foldl (fn (c,moveSet) => M.add (moveSet,Move (0,SOME c,1)))
		                              M.empty (S.CharSet.difference (S.allChars,s))
	      in
		  Nfa {states=iList [0,1],
		       moves=moves,
		       accepting=I2.singleton (1,n)}
	      end
	  | build' n (S.Char c) = Nfa {states=iList [0,1],
				       moves=M.singleton (Move (0,SOME c,1)),
				       accepting=I2.singleton (1,n)}
	  | build' n (S.Begin) = raise SyntaxNotHandled
	  | build' n (S.End) = raise SyntaxNotHandled


	fun build (r,n) = let val (Nfa {states,moves,accepting}) = build' n r
			  (* Clean up the nfa to remove epsilon moves.
			   * A simple way to do this:
			   * 1. states={0}, moves={}
			   * 2. for every s in states,
			   * 3.   compute closure(s)
			   * 4.   for any move (i,c,o) with i in closure (s)
			   * 5.       add move (0,c,o) to moves
			   * 6.       add state o to states
			   * 7. repeat until no modifications to states and moves
			   *)
			  in
			      Nfa {states=states, moves=moves, accepting=accepting}
			  end

	fun buildPattern rs = 
	    let fun loop ([],_) = []
		  | loop (r::rs,n) = (build (r,n))::(loop (rs,n+1))
		val rs' = loop (rs,0)
		val renums = foldr (fn (Nfa {states,...},acc) => 1::(map (fn k=>k+I.numItems states) 
								     acc)) [] rs'
		val news = ListPair.map (fn (Nfa {states,moves,accepting},renum) =>
					      let val newStates=I.map (renumber renum) states
						  val newMoves=M.map (renumberMove renum) moves
						  val newAcc=I2.map (renumberAcc renum) accepting
					      in
						  Nfa{states=newStates,
						      moves=newMoves,
						      accepting=newAcc}
					      end) (rs',renums)
		val (states,moves,accepting) = foldl (fn (Nfa{states,moves,accepting},(accS,accM,accA))=>
						      (I.union (states,accS),
						       M.union (moves,accM),
						       I2.union (accepting,accA)))
		                                     (I.singleton 0,
						      M.addList (M.empty,
								 map (fn k => Move (0,NONE,k)) renums),
						      I2.empty) news
	    in
		Nfa {states=states,moves=moves,accepting=accepting}
		
	    end		
		      
	fun accepting (Nfa {accepting,...}) state = 
	    let val item = I2.find (fn (i,_) => (i=state)) accepting
	    in
		case item
		  of NONE => NONE
		   | SOME (s,n) => SOME (n)
	    end

	(* Compute possible next states from orig with character c *)
	fun oneMove (Nfa {moves,...}) (orig,char) = 
	      M.foldr (fn (Move (_,NONE,_),set) => set
	                | (Move (or,SOME c,d),set) => 
		             if (c=char) andalso (or=orig) 
				 then I.add (set,d)
			     else set)
	              I.empty moves

	fun closure (Nfa {moves,...}) origSet =
	    let fun addState (Move (orig,NONE,dest),(b,states)) =
		      if (I.member (states,orig) andalso
			  not (I.member (states,dest)))
			  then (true,I.add (states,dest))
		      else (b,states)
		  | addState (_,bs) = bs
		fun loop (states) = 
		    let val (modified,new) = M.foldr addState
			                             (false,states) moves
		    in
			if modified
			    then loop (new) 
			else new 
		    end
	    in
		loop (origSet)
	    end
	
	fun move nfa =
	    let val closure = closure nfa
		val oneMove = oneMove nfa
	    in
		closure o oneMove
	    end

	fun start nfa = closure nfa (I.singleton 0)

	fun chars (Nfa{moves,...}) state = let
	      fun f (Move(s1, SOME c, s2), s) =
		      if (s1 = state) then C.add(s, c) else s
		| f (_, s) = s
	      in
		C.listItems (M.foldl f C.empty moves)
	      end

    end

