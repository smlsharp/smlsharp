(**
 * nqueen_opt.sml - record-unboxed version of a parallel N-queen solver
 * @copyright (C) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure Thread :> sig
  type t
  val join : t -> int
  val spawn : (unit -> int) -> t
end =
struct

  type pthread_t = unit ptr   (* ToDo: system dependent *)

  val pthread_create =
      _import "pthread_create"
      : (pthread_t ref, unit ptr, unit ptr -> unit ptr, unit ptr) -> int
  val pthread_join =
      _import "pthread_join"
      : __attribute__((suspend)) (pthread_t, unit ptr ref) -> int

  type t = pthread_t * int ref

  fun spawn f =
      let
        val ret = ref (Pointer.NULL ())
        val r = ref 0
        val err = pthread_create (ret, Pointer.NULL (),
                                  fn _ => (r := f (); Pointer.NULL ()),
                                  Pointer.NULL ())
        val ref t = ret
      in
        if err = 0 then () else raise Fail "pthread_create"; (t, r) : t
      end

  fun join ((t, r):t) =
      (pthread_join (t, ref (Pointer.NULL ())); !r)

end

structure Mutex :> sig
  type t
  val new : unit -> t
  val lock : t -> unit
  val unlock : t -> unit
end =
struct

  type t = Word8Array.array

  val sizeof_pthread_mutex_t = 256  (* ToDo: system dependent *)
  val pthread_mutex_init =
      _import "pthread_mutex_init"
      : (t, unit ptr) -> int
  val pthread_mutex_lock =
      _import "pthread_mutex_lock"
      : __attribute__((suspend)) t -> int
  val pthread_mutex_unlock =
      _import "pthread_mutex_unlock"
      : t -> int

  fun new () =
      let
        val m = Word8Array.array (sizeof_pthread_mutex_t, 0w0)
        val err = pthread_mutex_init (m, Pointer.NULL ())
      in
        if err = 0 then m else raise Fail "pthread_mutex_init"
      end

  fun lock m =
      if pthread_mutex_lock m = 0
      then ()
      else raise Fail "pthread_mutex_lock"

  fun unlock m =
      if pthread_mutex_unlock m = 0
      then ()
      else raise Fail "pthread_mutex_unlock"

end

structure NQueen =
struct

  type board = {width: word, queens: word, left: word, down: word, right: word}

  fun init width =
      {width = width, queens = width, left = 0w0, down = 0w0, right = 0w0}
      : board

  val tasks = ref nil : board list ref
  val tasksMutex = Mutex.new ()

  fun getTask () =
      (Mutex.lock tasksMutex;
       case !tasks of
         nil => (Mutex.unlock tasksMutex; NONE)
       | h::t => (tasks := t; Mutex.unlock tasksMutex; SOME h))

  fun genTask z nil = z
    | genTask z ((board as {width, queens, left, down, right}) :: t) =
      genTask
        (genTask' board z width (Word.orb (Word.orb (left, down), right)) 0w1)
        t
  and genTask' board z 0w0 bits mask = z
    | genTask' (board as {width, queens, left, down, right}) z i bits mask =
      genTask' board
               (if Word.andb (bits, mask) = 0w0
                then {width = width,
                      queens = queens - 0w1,
                      left = Word.>> (Word.orb (left, mask), 0w1),
                      down = Word.orb (down, mask),
                      right = Word.<< (Word.orb (right, mask), 0w1)}
                     :: z
                else z)
               (i - 0w1)
               bits
               (mask + mask)

  fun initTasks minNumTasks tasks =
      if length tasks >= minNumTasks
      then tasks
      else initTasks minNumTasks (genTask nil tasks)

  fun solve width 0w0 left down right = 1
    | solve width queens left down right =
      solve' width queens left down right
             0
             width
             (Word.orb (Word.orb (left, down), right))
             0w1
  and solve' width queens left down right z 0w0 bits mask = z
    | solve' width queens left down right z i bits mask =
      solve' width queens left down right
             (if Word.andb (bits, mask) = 0w0
              then solve width
                         (queens - 0w1)
                         (Word.>> (Word.orb (left, mask), 0w1))
                         (Word.orb (down, mask))
                         (Word.<< (Word.orb (right, mask), 0w1))
                    + z
              else z)
             (i - 0w1)
             bits
             (mask + mask)

  fun solveTasks z =
      case getTask () of
        NONE => z
      | SOME {width, queens, left, down, right} =>
        solveTasks (z + solve width queens left down right)

  fun solvePara () =
      solveTasks 0

  fun nqueenPara numThreads width =
      let
        val _ = tasks := initTasks 20 [init width]
        fun start 0 = nil
          | start n = Thread.spawn solvePara :: start (n - 1)
        fun finish nil = 0
          | finish (h::t) = Thread.join h + finish t
        val threads = start (numThreads - 1)
      in
        solvePara () + finish threads
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
        val width =
            case Option.map (StringCvt.scanString (Word.scan StringCvt.DEC))
                            (OS.Process.getEnv "WIDTH") of
              SOME (SOME n) => n
            | _ => 0w14
      in
        NQueen.nqueenPara nthreads width
      end
  fun doit () = (run (); ())
  fun testit out = TextIO.output (out, Int.toString (run ()))
end
