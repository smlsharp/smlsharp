open Myth

val n = case Option.map Int.fromString (OS.Process.getEnv "SIZE") of
          SOME (SOME n) => n
        | _ => 1000000

fun rep 0 f = () | rep n f = (f () : unit; rep (n-1) f)

val b = Barrier.create (n + 1)

fun task (id:int) = (rep 10 (fn _ => (Barrier.wait b; ())); 0)

fun start id num =
    if num <= 0 then 0
    else if num <= 1 then task id
    else let
           val m = num div 2
           val n = num - m
           val t = Thread.create (fn () => start id m)
           val _ = start (id+m) n
         in
           Thread.join t
         end

fun doit () = let (* ------- *)

val t = Thread.create (fn () => start 0 n)
val _ = rep 10 (fn _ => (Barrier.wait b; ()))
val _ = Thread.join t

in () end (* ------- *)


fun rep 0 = ()
  | rep n =
    let val t = Time.now ()
        val () = doit ()
    in print (Time.fmt 6 (Time.- (Time.now (), t))); print "\n";
       rep (n - 1)
    end
val _ = rep 3
