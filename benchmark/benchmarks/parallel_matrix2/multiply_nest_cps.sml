(*
 * native parallel matrix multiplication
 *
 * This is continuation-passing-style version.
 * This program allocates one closure for each iteration.
 * A matrix is represented by a nested array.
 *)

local

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
        val r = ref _NULL
        val e = pthread_create (r, _NULL, fn _ => (f () : unit; _NULL), _NULL)
        val ref t = r
      in
        if e = 0 then t else raise Fail "spawn"
      end

  fun join th =
      (pthread_join (th, ref _NULL); ())

  val getenv = _import "getenv" : string -> unit ptr
  val atoi = _import "atoi" : unit ptr -> int
  val numThreads = getenv "NTHREADS"
  val numThreads = if numThreads = _NULL then 1 else atoi numThreads

  val DIM = 3 * 5 * 7 * 8  (* dividable by 1-8 *)

  fun allocMatrix init =
      let
        val row = Array.array (DIM, init)
        val matrix = Array.array (DIM, row)
        fun loop i =
            if i < DIM
            then let val row = Array.array (DIM, init)
                 in Array.update (matrix, i, row);
                    loop (i + 1) end
            else ()
      in
        loop 1;
        matrix
      end

  val matrix1 = allocMatrix 1.2345678
  val matrix2 = allocMatrix 1.2345678
  val result = allocMatrix 0.0

  fun sub (a, i, j) : real =
      Array.sub (Array.sub (a, i), j)
  fun update (a, i, j, v : real) =
      Array.update (Array.sub (a, i), j, v)

  fun calc start () =
      let
        val last = start + DIM div numThreads
        fun loop3 (i, j, k, z, K) =
            if k < DIM
            then loop3 (i, j, k+1, z + sub (matrix1,i,k) * sub (matrix2,k,j), K)
            else K () : unit
        and loop2 (i, j, K) =
            if j < DIM
            then loop3 (i, j, 0, 0.0, fn _ => loop2 (i, j+1, K))
            else K () : unit
        and loop1 i =
            if i < last then loop2 (i, 0, fn _ => loop1 (i+1)) else ()
      in
        loop1 start
      end

  fun main () =
      let
        fun start i =
            if i < numThreads
            then spawn (calc (i * (DIM div numThreads))) :: start (i+1)
            else nil
        fun joinAll nil = ()
          | joinAll (h::t) = (join h; joinAll t)
        val threads = start 1
        val () = calc 0 ()
      in
        joinAll threads
      end

in

val x = main ()

end
