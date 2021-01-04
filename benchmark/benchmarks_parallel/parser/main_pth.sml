val args = CommandLine.arguments ()
val nthreads = case args of s::_ => valOf (Int.fromString s) | _ => 1

val incr = _import "incr" : () -> int

fun get () =
    let
      val n = incr ()
    in
      if n >= Vector.length files
      then NONE
      else SOME (Vector.sub (files, n))
    end

fun task a =
    case get () of
      NONE => a
    | SOME s => (parse s; task (a + 1))

fun spawn n =
    let
      val a = n div 2
      val b = n - a - 1
      val t1 =
          if a > 0
          then SOME (Pthread.Thread.create (fn _ => spawn a))
          else NONE
      val t2 =
          if b > 0
          then SOME (Pthread.Thread.create (fn _ => spawn b))
          else NONE
      val m = task 0
      val r1 = case t1 of SOME t => Pthread.Thread.join t | NONE => 0
      val r2 = case t2 of SOME t => Pthread.Thread.join t | NONE => 0
    in
      r1 + r2 + m
    end

fun main () =
    print (Int.toString (spawn nthreads))

val _ = main ()
