val args = CommandLine.arguments ()
val repeat = case args of s::_ => valOf (Int.fromString s) | _ => 10
val size = case args of _::s::_ => valOf (Int.fromString s) | _ => 2048
val cutOff = case args of _::_::s::_ => valOf (Int.fromString s) | _ => 8

val x_base = ~2.0
val y_base = 1.25
val side = 2.5
val maxCount = 1024
val delta = side / (real size)
val image = Array.tabulate (size * size, fn _ => 0w0 : Word8.word)

fun loopV i x y w h iterations =
    if i >= h
    then iterations
    else
      let
        val c_im = y_base - delta * real (i + y)
        fun loopH j iterations =
            if j >= w
            then iterations
            else
              let
                val c_re = x_base + delta * real (j + x)
                fun loopP count z_re z_im =
                    if count < maxCount
                    then
                      let
                        val z_re_sq = z_re * z_re
                        val z_im_sq = z_im * z_im
                      in
                        if z_re_sq + z_im_sq > 4.0
                        then (Array.update
                                (image, (j + x) + (i + y) * size, 0w1);
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
         in op + (ForkJoin.par
                    (fn _ => mandelbrot x y w2 h,
                     fn _ => mandelbrot (x + w2) y (w - w2) h))
         end
    else let val h2 = h div 2
         in op + (ForkJoin.par
                    (fn _ => mandelbrot x y w h2,
                     fn _ => mandelbrot x (y + h2) w (h - h2)))
         end

fun doit () =
    mandelbrot 0 0 size size

fun rep 0 = ()
  | rep n =
    let val t1 = Time.now ()
        val r = doit ()
        val t2 = Time.now ()
(*
        val _ =
            (TextIO.output
               (TextIO.stdErr,
                "P1\n" ^ Int.toString size ^ " " ^ Int.toString size ^ "\n");
             Word8Array.app
               (fn x => TextIO.output (TextIO.stdErr, Word8.toString x))
               image)
*)
        val d1 = Time.toReal t1
        val d2 = Time.toReal t2
    in print (" - {result: " ^ Int.toString r ^ ", time: "
              ^ Real.toString (d2 - d1) ^ "}\n");
       rep (n - 1)
    end

val _ = print (" bench: mandelbrot_maple_par\n size: "
               ^ Int.toString size ^ "\n cutoff: " ^ Int.toString cutOff
               ^ "\n results:\n")
val _ = rep repeat
