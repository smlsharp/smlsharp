structure Main =
struct
  val puts = _import "puts" : string -> unit
  val write = _import "write" : (int, string, int) -> int
  fun puts s = let val s = s ^ "\n" in write (1, s, size s); () end
(*
  val reserve = _import "sml_heap_set_reservation" : word -> ()
*)
  fun reserve _ = ()

  val ndisturb =
      case Option.map Int.fromString (OS.Process.getEnv "NDISTURB") of
        SOME (SOME n) => n
      | _ => 0
  val rsv =
      case Option.map Int.fromString (OS.Process.getEnv "NRESERVE") of
        SOME (SOME n) => Word.fromInt n
      | _ => 0w0


  fun bench f =
      let
        val t1 = gettime ()
        val () = f ()
        val t2 = gettime ()
        val t = difftime (t1, t2)
      in
        puts (timestr t)
      end

  fun repeat 0 f = ()
    | repeat n f = (f () : unit; repeat (n - 1) f)

  val finish = ref false

  fun repeatUntilFinish cnt f =
      if !finish then cnt else (f () : unit; repeatUntilFinish (cnt+1) f)

  fun launch title f =
      let
        val _ = puts (title ^ " is started")
        val n = repeatUntilFinish 0 f
        val _ = puts (title ^ " is repeated " ^ Int.toString n)
      in 
        _NULL
      end

  fun startDisturb title =
      [
        Pthread.create (fn _ => launch (title ^ "-c_g") CountGraphs.doit),
        Pthread.create (fn _ => launch (title ^ "-gcbench") GCBench.doit)
      ]

  fun realtimeThread () =
      (
        repeat 100 (fn _ => (bench FFT.doit));
        finish := true
      )

  fun doit () =
      let
        val _ = reserve rsv
        val disturbers =
            List.concat
              (List.tabulate (ndisturb, fn i => startDisturb (Int.toString i)))
      in
        realtimeThread ();
        map Pthread.join disturbers;
        puts "finished\n"
      end

end
