fun ('a#reify) pp (x:'a) = 
    (TextIO.print (ReifiedTerm.reifiedTermToString (ReifyTerm.toReifiedTerm x));
     TextIO.print  "\n")
fun ('a#reify) typeOf (x:'a) = _reifyTy('a)
