val args = CommandLine.arguments ()
val repeat = case args of s::_ => valOf (Int.fromString s) | _ => 10
val size = case args of _::s::_ => valOf (Int.fromString s) | _ => 40
val cutOff = case args of _::_::s::_ => valOf (Int.fromString s) | _ => 10

fun fib 0 = 0
  | fib 1 = 1
  | fib n = fib (n - 1) + fib (n - 2)

fun pfib n =
    if n <= cutOff
    then fib n
    else op + (ForkJoin.par (fn _ => pfib (n - 1), fn _ => pfib (n - 2)))

fun doit () = pfib size

fun rep 0 = ()
  | rep n =
    let val t1 = Time.now ()
        val r = doit ()
        val t2 = Time.now ()
        (* val _ = print (Int.toString r ^ "\n") *)
        val d1 = Time.toReal t1
        val d2 = Time.toReal t2
    in print (" - {result: " ^ Int.toString r ^ ", time: "
              ^ Real.toString (d2 - d1) ^ "}\n");
       rep (n - 1)
    end

val _ = print (" bench: fib_maple_par\n size: "
               ^ Int.toString size ^ "\n cutoff: " ^ Int.toString cutOff
               ^ "\n results:\n")
val _ = rep repeat
