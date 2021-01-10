fun task i =
    (parse (Vector.sub (files, i)); 1)

fun spawn i n =
    if n <= 1 then task i else 
    let
      val a = n div 2
      val b = n - a
      val t1 = Myth.Thread.create (fn _ => spawn i a)
      val t2 = Myth.Thread.create (fn _ => spawn (i + a) b)
      val r1 = Myth.Thread.join t1
      val r2 = Myth.Thread.join t2
    in
      r1 + r2
    end

fun main () =
    print (Int.toString (spawn 0 (Vector.length files)))

val _ = main ()
