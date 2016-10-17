(*
 * native parallel matrix multiplication
 *
 * This is continuation-passing-style version.
 * This program allocates one closure for each iteration.
 *)

type pthread_t = unit ptr  (* ToDo: system dependent *)

val pthread_create =
    _import "pthread_create"
    : (pthread_t ref, unit ptr, unit ptr -> unit ptr, unit ptr) -> int
val pthread_join =
    _import "pthread_join"
    : (pthread_t, unit ptr ref) -> int

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

val numThreads =
    case Option.map Int.fromString (OS.Process.getEnv "NTHREADS") of
      SOME (SOME n) => n
    | _ => 1

val DIM = 3 * 5 * 7 * 8  (* dividable by 1-8 *)
val matrix1 = Array.array (DIM * DIM, 1.2345678)
val matrix2 = Array.array (DIM * DIM, 1.2345678)
val result = Array.array (DIM * DIM, 0.0)

fun sub a i j : real =
    Array.sub (a, i * DIM + j)
fun update a i j (v : real) =
    Array.update (a, i * DIM + j, v)

(*
   for (i = start; i < last; i++) {
     for (j = 0; j < DIM; j++) {
       double z = 0.0;
       for (k = 0; k < DIM; k++)
         z += matrix1[i,k] * matrix2[k,j];
       result[i,j] = z;
     }
   }
*)

local
  fun loop3 i j k =
      if k < DIM
      then loop3 i j (k+1) + sub matrix1 i k * sub matrix2 k j
      else 0.0
  fun loop2 i j =
      if j < DIM
      then (update result i j (loop3 i j 0); loop2 i (j + 1))
      else ()
  fun loop1 i last =
      if i < last then (loop2 i 0; loop1 (i+1) last) else ()
in
fun calc_rec start last = loop1 start last
end

local
  fun loop3 i j k z =
      if k < DIM
      then loop3 i j (k+1) (z + sub matrix1 i k * sub matrix2 k j)
      else update result i j z
  fun loop2 i j =
      if j < DIM
      then (loop3 i j 0 0.0; loop2 i (j + 1))
      else ()
  fun loop1 i last =
      if i < last then (loop2 i 0; loop1 (i+1) last) else ()
in
fun calc_tail start last = loop1 start last
end

local
  fun loop3 (i, j, k, z, K) =
      if k < DIM
      then loop3 (i, j, k+1, z + sub matrix1 i k * sub matrix2 k j, K)
      else K z : unit
  fun loop2 (i, j, K) =
      if j < DIM
      then loop3 (i, j, 0, 0.0,
                  fn z => (update result i j z; loop2 (i, j+1, K)))
      else K ()
  fun loop1 i last =
      if i < last then loop2 (i, 0, fn _ => loop1 (i+1) last) else ()
in
fun calc_cps start last = loop1 start last
end

fun task s l = fn () => calc_cps s l

fun main () =
    let
      val d = Int.quot (DIM, numThreads)
      val m = Int.rem (DIM, numThreads)
      val widths =
          List.tabulate (numThreads, fn i => if i < m then d + 1 else d)
      fun start (w1::w2::t) = spawn (task w1 (w1+w2)) :: start ((w1+w2)::t)
        | start _ = nil
      val threads = start widths
      val _ = task 0 (hd widths) ()
    in
      app join threads
    end

val _ = main ()
