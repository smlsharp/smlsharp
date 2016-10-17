(**
 * @copyright (c) 2006, Tohoku University.
 *)
structure Gensym :  sig
    val gensym : unit -> string
    val initGensym : unit -> unit
    val makeGensym : char list -> ((unit -> string) * (unit -> unit))
  end
 = struct

  fun next n t = case t of nil => [0]
                           | (h::t) => if h = n then 0::(next n t)
                                       else (h+1)::t
  fun toString L s = implode (map (fn x => List.nth (L,x)) (rev s))
  fun makeGensym L = 
      let val seed = ref [0]
          fun next' t = next (length L - 1) t
          fun toString' s = toString L s
          fun gensym () = toString' (!seed) before seed := next' (!seed)
      in
           (gensym,fn () => seed := [0])
      end
  
     local  
        val seed = ref [(ord #"a")]
     in fun initGensym () = seed := [(ord #"a")]
        fun gensym() = 
           let fun inc nil = [(ord #"a")]
                 | inc (h::tail) =  if h = (ord #"z") then
                                       (ord #"a")::(inc tail)
                                    else (h+1)::tail
           in
               implode (map chr (rev (!seed)))
  	     before seed:=inc (!seed)
           end
     end
end
