signature DFA = 
    sig

	exception SyntaxNotHandled
	
	type dfa

	val build : RegExpSyntax.syntax -> dfa
	val buildPattern : RegExpSyntax.syntax list -> dfa
	val move : dfa -> int * char -> int option
	val accepting : dfa -> int -> int option
	val canStart : dfa -> char -> bool

    end
