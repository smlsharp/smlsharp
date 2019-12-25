val size = case Option.map Int.fromString (OS.Process.getEnv "SIZE") of
             SOME (SOME n) => n
           | _ => 2048

val rand_r = _import "rand_r" : word ref -> word

type graph = {incomingFrom : int list array, numOutgoing : int array}

fun initGraph numNodes =
    let
      val lock = Array.tabulate (numNodes, fn _ => Myth.Mutex.create ())
      val numOutgoing = Array.array (numNodes, 0)
      fun inc (a, i) = Array.update (a, i, Array.sub (a, i) + 1)
      fun genAdj r i 0 z = z
        | genAdj r i j z =
          if Word.mod (rand_r r, 0w256) > 0w85
          then genAdj r i (j - 1) z
          else (Myth.Mutex.lock (Array.sub (lock, j-1));
                inc (numOutgoing, j-1);
                Myth.Mutex.unlock (Array.sub (lock, j-1));
                genAdj r i (j - 1) ((j-1)::z))
      val incomingFrom =
          _foreach i in Array.array (numNodes, nil)
          with _
          do genAdj (ref (Word.fromInt i)) i numNodes nil
          while false
          end
    in
      {incomingFrom = incomingFrom, numOutgoing = numOutgoing}
    end

fun pageRank ({incomingFrom, numOutgoing}:graph) =
    let
      val size = Array.length incomingFrom
      val scores = Array.array (size, 1.0 / real size)
      val incomingFrom = fn i => Array.sub (incomingFrom, i)
      val numOutgoing = fn i => Array.sub (numOutgoing, i)
      fun sum X nil z = z
        | sum X (h::t) z = sum X t (z + X h / real (numOutgoing h))
      val count = ref 0
    in
      _foreach i in scores
      with {value, newValue, size}
      do (if i = 0 then count := !count + 1 else ();
          0.15 / real size + 0.85 * sum value (incomingFrom i) 0.0)
      while !count < 30 (*Real.abs (newValue i - value i) > epsilon*)
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
val _ = Array.appi (fn (i,{adj,...}) => app (fn j => print (Int.toString i ^ " -> " ^ Int.toString j ^ "\n")) adj)
*)
(*
val _ = Array.appi (fn (i,adj) => app (fn j => print (Int.toString i ^ " <- " ^ Int.toString j ^ "\n")) adj) (#incomingFrom graph)
*)

val a = pageRank graph
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
