structure Pthread =
struct
  type pthread_t = unit ptr  (* ToDo: system dependent *)
  val pthread_create =
      _import "pthread_create"
      : __attribute__((suspend))
        (pthread_t ref, unit ptr, unit ptr -> unit ptr, unit ptr) -> int
  val pthread_join =
      _import "pthread_join"
      : __attribute__((suspend))
        (pthread_t, unit ptr ref) -> int
  fun spawn f =
      let
        val t = ref _NULL
        val r = ref 0
        val e = pthread_create (t, _NULL, fn _ => (r := f (); _NULL), _NULL)
      in
        if e = 0 then (!t, r) else raise Fail "spawn"
      end
  fun join (t, r) =
      (pthread_join (t, ref _NULL); !r)
end

val TIMES = 3 * 5 * 7 * 8  (* dividable by 1-8 *)

structure FibRepeat =
struct

  fun fib 0 = 1
    | fib 1 = 1
    | fib n = fib (n - 1) + fib (n - 2)

  fun repeat 0 m = 0
    | repeat n m = fib m + repeat (n - 1) m

  fun task n m = fn () => repeat n m

  fun start nthreads times n =
      let
        val d = Int.quot (times, nthreads)
        val m = Int.rem (times, nthreads)
        val cnts = List.tabulate (nthreads, fn i => if i < m then d + 1 else d)
        val threads = map (fn i => Pthread.spawn (task i n)) (tl cnts)
        val r = task (hd cnts) n ()
      in
        foldl (fn (t,z) => Pthread.join t + z) r threads
      end

end

structure Main =
struct
  fun run () =
      let
        val nthreads =
            case Option.map Int.fromString (OS.Process.getEnv "NTHREADS") of
              SOME (SOME n) => n
            | _ => 1
        val fibn =
            case Option.map (StringCvt.scanString (Word.scan StringCvt.DEC))
                            (OS.Process.getEnv "FIBN") of
              SOME (SOME n) => Word.toInt n
            | _ => 30
      in
        FibRepeat.start nthreads TIMES fibn
      end
(*
  fun doit () = (run (); ())
*)
  fun testit out = TextIO.output (out, Int.toString (run ()) ^ "\n")
  fun doit () = testit TextIO.stdOut
end
