val size = case Option.map Int.fromString (OS.Process.getEnv "SIZE") of
             SOME (SOME n) => n
           | _ => 2048

val rand_r = _import "rand_r" : word ref -> word
fun randReal r = real (Word.toIntX (rand_r r)) / real (Word.toIntX (rand_r r))

type edge = {from:int, wait:real}
type graph = {incomingFrom : edge list array}

fun initGraph numNodes =
    let
      fun genAdj r i 0 z = z
        | genAdj r i j z =
          if Word.mod (rand_r r, 0w256) > 0w85
          then genAdj r i (j - 1) z
          else genAdj r i (j - 1) ({from = j - 1, wait = randReal r} :: z)
      val incomingFrom =
          _foreach i in Array.array (numNodes, nil)
          with _
          do genAdj (ref (Word.fromInt i)) i numNodes nil
          while false
          end
    in
      {incomingFrom = incomingFrom}
    end

fun shortest ({incomingFrom} : graph) =
    let
      val size = Array.length incomingFrom
      val incomingFrom = fn i => Array.sub (incomingFrom, i)
      fun min X nil z = z
        | min X ({from,wait}::t) z = min X t (Real.min (z, X from + wait))
      val count = ref 0
    in
      _foreach i in Array.array (size, 1.0 / 0.0)
      with {value, newValue, ...}
      do (if i = 0 then count := !count + 1 else ();
          if i = 0 then 0.0 else min value (incomingFrom i) (value i))
      while newValue i < value i
      end
    end



fun doit () = let (* ------- *)

(*
val t1 = Time.now()
*)
val graph = initGraph size
(*
val t2 = Time.now()
*)

(*
val _ = Array.appi
          (fn (i,edges) =>
              List.app
                (fn {from,wait} =>
                    print (Int.toString i ^ "<-(" ^ Real.toString wait ^ ")-" ^ Int.toString from ^ "\n"))
                edges)
          (#incomingFrom graph)
*)

val a = shortest graph
(*
val t3 = Time.now()
val _ = (print (Time.fmt 6 (Time.- (t2,t1))); print " *\n")
val _ = (print (Time.fmt 6 (Time.- (t3,t2))); print " *\n")
*)

(*
val _ = Array.appi (fn (i,x) => print (Int.toString i ^ " : " ^ Real.toString x ^ "\n")) a
*)

in () end (* ------- *)


fun rep 0 = ()
  | rep n =
    let val t = Time.now ()
        val () = doit ()
    in print (Time.fmt 6 (Time.- (Time.now (), t))); print "\n";
       rep (n - 1)
    end
val _ = rep 3
