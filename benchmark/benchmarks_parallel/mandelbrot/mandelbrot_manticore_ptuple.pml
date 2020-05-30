val args = CommandLine.arguments ()
val valOf = Option.valOf
val repeat = case args of s::_ => valOf (Int.fromString s) | _ => 10
val size = case args of _::s::_ => valOf (Int.fromString s) | _ => 2048
val cutOff = case args of _::_::s::_ => valOf (Int.fromString s) | _ => 8

val x_base = ~2.0
val y_base = 1.25
val side = 2.5
val maxCount = 1024
val delta = side / (Double.fromInt size)
val image = Array.tabulate (size, fn _ => Array.tabulate (size, fn _ => 0))

fun loopV i x y w h iterations =
    if i >= h
    then iterations
    else
      let
        val c_im = y_base - delta * Double.fromInt (i + y)
        fun loopH j iterations =
            if j >= w
            then iterations
            else
              let
                val c_re = x_base + delta * Double.fromInt (j + x)
                fun loopP count z_re z_im =
                    if count < maxCount
                    then
                      let
                        val z_re_sq = z_re * z_re
                        val z_im_sq = z_im * z_im
                      in
                        if z_re_sq + z_im_sq > 4.0
                        then (Array.update (Array.sub (image, i + y), j + x, 1);
                              count)
                        else loopP (count + 1)
                                   (z_re_sq - z_im_sq + c_re)
                                   (2.0 * z_re * z_im + c_im)
                      end
                    else count
                val count = loopP 0 c_re c_im
              in
                loopH (j+1) (iterations + count)
              end
        val iterations = loopH 0 iterations
      in
        loopV (i+1) x y w h iterations
      end

fun mandelbrot x y w h =
    if w <= cutOff andalso h <= cutOff
    then loopV 0 x y w h 0
    else if w >= h
    then let val w2 = w div 2
             val (r, t) = (| mandelbrot x y w2 h, 
                             mandelbrot (x + w2) y (w - w2) h |)
         in r + t
         end
    else let val h2 = h div 2
             val (r, t) = (| mandelbrot x y w h2,
                             mandelbrot x (y + h2) w (h - h2) |)
         in r + t
         end

fun doit () =
    mandelbrot 0 0 size size

fun rep 0 = ()
  | rep n =
    let
      val (r, t) = Time.timeToEval doit
    in
(*
       print ("P1\n" ^ Int.toString size ^ " " ^ Int.toString size ^ "\n");
       Array.app (Array.app (fn x => print (Int.toString x))) image;
*)
       print (" - {result: " ^ Int.toString r ^ ", time: "
              ^ Time.toString t ^ "}\n");
       rep (n - 1)
    end

val _ = print (" bench: mandelbrot_manticore_ptuple\n size: "
               ^ Int.toString size ^ "\n cutoff: " ^ Int.toString cutOff
               ^ "\n results:\n")
val _ = rep repeat
