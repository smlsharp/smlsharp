structure Basics = struct
    exception FindIndex
(*
    fun foldr' f g [x] = g x
     | foldr' f g (h::t) = f(g h,foldr' f g t)
*)
    fun numberList L =
	let fun f n nil = nil
	      | f n (h::t) = (h,n)::(f (n+1) t)
	in f 0 L
	end
    fun findIndex s nil = raise FindIndex
      | findIndex s (h::t) = if h = s then 0 else 1 + (findIndex s t)
    fun IEnvToISet m = IEnv.foldli (fn (i,_,s) => ISet.add(s,i)) ISet.empty m
    fun SEnvToSSet m = SEnv.foldli (fn (i,_,s) => SSet.add(s,i)) SSet.empty m
end
