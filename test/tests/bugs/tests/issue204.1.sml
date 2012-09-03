exception Domain;

fun fold (lst, folder, state) =
	let fun loop (lst, state) =
			case lst of
			[] => state
			| first::rest => loop (rest, folder (first, state))
	in loop (lst, state)
	end;

fun 'a foldOverSubsets (universe, eFolder, eState, folder, 
state: 'a) =
	let exception fini of 'a
	    fun f (first, rest, eState) (isinc, state) =
		    let val (newEState, newState) =
				eFolder (first,
					 isinc,
					 eState,
					 state,
					 fini)
		    in outer (rest, newEState, newState)
		    end handle fini state => state
	    and outer (universe, eState, state) =
			case universe of
			[] => folder (eState, state)
			| first::rest =>
			    let val f = f (first, rest, eState)
			    in f (false, f (true, state))
			    end
	    in outer (universe, eState, state)
	    end;
