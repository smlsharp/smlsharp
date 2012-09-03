(* poll.sml
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *)

structure Poll : POLL = 
  struct
    exception BadPollFreq

    val defaultHandler = fn k => k

    val _ = Assembly.pollHandler := defaultHandler
    val handlerValid = ref false

    val pollEvent = Assembly.pollEvent
    val pollFreq = Assembly.pollFreq

    fun setHandler NONE = (
	  Assembly.pollHandler := defaultHandler;
	  handlerValid := false)
      | setHandler (SOME h) = (
	  Assembly.pollHandler := h;
	  handlerValid := true)

    fun inqHandler () = if !handlerValid then SOME (!Assembly.pollHandler)
			  else NONE

    fun setFreq NONE = pollFreq := 0
      | setFreq (SOME x) = if x <= 0 then raise BadPollFreq
			     else pollFreq := x

    fun inqFreq () = let val x = !pollFreq
		       in
			   if x = 0 then NONE
			   else SOME x
		       end
  end (* structure Poll *)

