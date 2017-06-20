local open Myth  in
fun start id num =
    if num <= 1 then 0 
    else let val m = num div 2
             val n = num - m
             val t = Thread.create (fn () => start id m)
             val _ = start (id+m) n
         in Thread.join t end

fun doit n =
    let val t = Time.now ()
        val _ = start 0 n
    in print (Time.fmt 6 (Time.- (Time.now (), t))); print "\n"
    end
end
