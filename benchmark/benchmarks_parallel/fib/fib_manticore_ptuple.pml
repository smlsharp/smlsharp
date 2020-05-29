val args = CommandLine.arguments ()
val valOf = Option.valOf
val repeat = case args of s::_ => valOf (Int.fromString s) | _ => 10
val size = case args of _::s::_ => valOf (Int.fromString s) | _ => 40
val cutOff = case args of _::_::s::_ => valOf (Int.fromString s) | _ => 10

fun fib n = if n <= 1 then n else fib (n - 1) + fib (n - 2)

fun pfib n =
    if n <= cutOff then fib n
    else let val (r1, r2) = (| pfib (n - 1), pfib (n - 2) |)
         in r1 + r2
         end

fun doit () = pfib size

fun rep 0 = ()
  | rep n =
    let val (r, t) = Time.timeToEval doit
    in print (" - {result: " ^ Int.toString r ^ ", time: "
              ^ Time.toString t ^ "}\n");
       rep (n - 1)
    end

val _ = print (" bench: fib_manticore_ptuple\n size: "
               ^ Int.toString size ^ "\n cutoff: " ^ Int.toString cutOff
               ^ "\n results:\n")
val _ = rep repeat
