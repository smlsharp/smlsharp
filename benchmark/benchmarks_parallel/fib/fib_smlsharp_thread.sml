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
    else let val t = Thread.create (fn () => pfib (n - 2))
         in pfib (n - 1) + Thread.join t
         end

fun doit () = pfib size

fun rep 0 = ()
  | rep n =
    let val t1 = Time.now ()
        val r = doit ()
        val t2 = Time.now ()
        (* val _ = print (Int.toString r ^ "\n") *)
        val d1 = Time.toReal t1
        val d2 = Time.toReal t2
    in (_import "printf" : (string,...(int,real)) -> int)
         (" - {result: %d, time: %.6f}\n", r, d2 - d1);
       rep (n - 1)
    end

val _ = (_import "printf" : (string,...(string,int,int)) -> int)
          (" bench: fib_smlsharp_%s\n size: %d\n cutoff: %d\n results:\n",
           Thread.threadtype, size, cutOff)
val _ = rep repeat
