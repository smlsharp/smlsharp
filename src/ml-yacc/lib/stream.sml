(* ML-Yacc Parser Generator (c) 1989 Andrew W. Appel, David R. Tarditi *)

(* Stream: a structure implementing a lazy stream.  The signature STREAM
   is found in base.sig *)

functor StreamFun(A: sig type tok end) :> STREAM where type tok = A.tok =
struct
   type tok = A.tok
   datatype str = EVAL of tok * str ref | UNEVAL of (unit->tok)

   type stream = str ref

   fun get(ref(EVAL t)) = t
     | get(s as ref(UNEVAL f)) = 
	    let val t = (f(), ref(UNEVAL f)) in s := EVAL t; t end

   fun streamify f = ref(UNEVAL f)
   fun cons(a,s) = ref(EVAL(a,s))
end;
