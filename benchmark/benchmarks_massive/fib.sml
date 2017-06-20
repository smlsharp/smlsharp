fun fib cutOff 0 = 0
  | fib cutOff 1 = 1
  | fib cutOff n =
    if n < cutOff
    then fib cutOff (n - 1) + fib cutOff (n - 2)
    else
    let
      val t2 = Myth.Thread.create (fn () => fib cutOff (n - 2))
    in
      fib cutOff (n - 1) + Myth.Thread.join t2
    end

fun doit () = let (* ------- *)

val n = fib 10 40

in () end (* ------- *)

fun rep 0 = ()
  | rep n =
    let val t = Time.now ()
        val () = doit ()
    in print (Time.fmt 6 (Time.- (Time.now (), t))); print "\n";
       rep (n - 1)
    end
val _ = rep 3
