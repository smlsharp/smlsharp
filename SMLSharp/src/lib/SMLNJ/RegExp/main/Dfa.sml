
structure Dfa : DFA = 
    struct

	exception SyntaxNotHandled

	datatype move = Move of int * char option * int

	fun compareCharOption (NONE,NONE) = EQUAL
	  | compareCharOption (NONE,SOME (c)) = LESS
	  | compareCharOption (SOME(c),NONE) = GREATER
	  | compareCharOption (SOME(c),SOME(c')) = Char.compare (c,c')

	structure N = Nfa
	structure IntSet = N.IntSet
	structure IntSetSet = 
	    ListSetFn (struct
			   type ord_key = IntSet.set
			   val compare = IntSet.compare
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

        structure IS = IntSetSet
        structure I = IntSet
	structure I2 = Int2Set
        structure M = MoveSet
	structure C = CharSet
	structure A2 = Array2
	structure A = Array
	structure Map = ListMapFn (struct
				       type ord_key = IntSet.set
				       val compare = IntSet.compare
				   end)
	    
        (* create sets from lists *)
        fun iList l = I.addList (I.empty,l)
	fun mList l = M.addList (M.empty,l)

	datatype dfa = Dfa of {states : I.set,
			       moves : M.set,
			       accepting : I2.set,
			       table : int option A2.array,
			       accTable : (int option) A.array,
			       startTable : bool A.array}

	fun print (Dfa {states,moves,accepting,...}) = 
	    let val pr = TextIO.print
		val prI = TextIO.print o Int.toString
		val prI2 = TextIO.print o (fn (i1,i2) => Int.toString i1)
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


	fun move' moves (i,c) = 
	    (case (M.find (fn (Move (s1,SOME c',s2)) =>
			   (s1=i andalso c=c'))
		   moves)
	       of NONE => NONE
		| SOME (Move (s1,SOME c',s2)) => SOME s2)
(*	fun move (Dfa {moves,...}) (i,c) = move' moves (i,c) *)
	fun move (Dfa {table,...}) (i,c) = A2.sub (table,i,ord(c)-ord(Char.minChar))

	fun accepting' accepting i = I2.foldr (fn ((s,n),NONE) => if (s=i) 
								      then SOME(n)
								  else NONE
                                                | ((s,n),SOME(n')) => if (s=i)
									  then SOME(n)
								      else SOME(n'))
	                                      NONE accepting
(*	fun accepting (Dfa {accepting,...}) i = accepting' accepting i *)
	fun accepting (Dfa {accTable,...}) i = A.sub (accTable,i)

	fun canStart (Dfa {startTable,...}) c = A.sub (startTable,ord(c))

	fun build' nfa = 
	    let val move = N.move nfa
		val accepting = N.accepting nfa
		val start = N.start nfa
		val chars = N.chars nfa
		fun getAllChars (ps) = 
		    I.foldl
		    (fn (s,cs) => C.addList (cs,chars s))
		    C.empty ps
		val initChars = getAllChars (start)
		fun getAllStates (ps,c) = 
		    I.foldl
		    (fn (s,ss) => I.union (ss,move (s,c)))
		    I.empty ps
		fun loop ([],set,moves) = (set,moves)
		  | loop (x::xs,set,moves) = 
		    let val cl = getAllChars (x)
			val (nstack,sdu,ml) = 
			    C.foldl
			    (fn (c,(ns,sd,ml)) =>
			     let val u = getAllStates (x,c)
			     in
				 if (not (IS.member (set,u))
				     andalso (not (IS.member (sd,u))))
				     then (u::ns,
					   IS.add (sd,u),
					   (x,c,u)::ml)
				 else (ns,sd,(x,c,u)::ml)
			     end) ([],IS.empty,[]) cl
		    in
			loop (nstack@xs,IS.union(set,sdu),ml@moves)
		    end
		val (sSet,mList) = loop ([start],IS.singleton (start), [])
		val num = ref 1
		fun new () = let val n = !num
			     in
				 num := n+1 ; n
			     end
		val sMap = Map.insert (Map.empty, start, 0)
		val sSet' = IS.delete (sSet,start)
		val sMap = IS.foldl (fn (is,map) => Map.insert (map,is,new ()))
		                    sMap sSet'
		val states = I.addList (I.empty,List.tabulate(!num,fn x => x))
		val moves = M.addList (M.empty,
				       map (fn (is1,c,is2) =>
					    Move (valOf (Map.find (sMap,is1)),
						  SOME c,
						  valOf (Map.find (sMap,is2))))
				           mList)
		(* Given a set of accepting states, look for a given state,
		 * with the minimal corresponding pattern number
		 *)
		fun minPattern accSet = let val l = map (valOf o accepting) (I.listItems accSet)
					    fun loop ([],min) = min
					      | loop (n::ns,min) = 
						           if (n<min) then loop (ns,n)
							   else loop (ns,min)
					in
					    loop (tl(l),hd(l))
					end
		val accept = IS.foldl (fn (is,cis) =>
				       let val items = I.filter (fn k => 
								 case (accepting k)
								     of SOME _ => true
								      | NONE => false) is
				       in
					   if (I.isEmpty items) 
					       then cis
					   else 
					       I2.add (cis,(valOf (Map.find (sMap,is)),
							    minPattern items))
				       end) I2.empty sSet
		val table = A2.tabulate A2.RowMajor (!num, 
					 ord(Char.maxChar)-ord(Char.minChar)+1,
					 fn (s,c) => move' moves (s,chr(c+ord(Char.minChar))))
		val accTable = A.tabulate (!num, 
					   fn (s) => accepting' accept s)
		val startTable = A.tabulate (ord(Char.maxChar)-
					     ord(Char.minChar)+1,
					     fn (c) => C.member (initChars,
								 chr(c+ord(Char.minChar))))
	    in
		Dfa {states=states,moves=moves,accepting=accept,
		     table=table,accTable=accTable,startTable=startTable}
	    end
	
	fun build r = build' (N.build (r,0))
		  
	fun buildPattern rs = build' (N.buildPattern rs)


    end
