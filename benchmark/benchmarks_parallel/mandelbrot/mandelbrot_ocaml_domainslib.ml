module T = Domainslib.Task

let num_domains = try int_of_string (Sys.getenv "NPROCS") with _ -> 1
let repeat = try int_of_string Sys.argv.(1) with _ -> 10
let size = try int_of_string Sys.argv.(2) with _ -> 2048
let cutOff = try int_of_string Sys.argv.(3) with _ -> 8
let pool = T.setup_pool ~num_domains:(num_domains - 1)

let x_base = -2.0
let y_base = 1.25
let side = 2.5
let maxCount = 1024
let delta = side /. float size
let image = Bytes.make (size * size) '0'

let rec loopV i x y w h iterations =
    if i >= h
    then iterations
    else
      let c_im = y_base -. delta *. float (i + y) in
      let rec loopH j iterations =
          if j >= w
          then iterations
          else
            let c_re = x_base +. delta *. float (j + x) in
            let rec loopP count z_re z_im =
                if count < maxCount then
                  let z_re_sq = z_re *. z_re in
                  let z_im_sq = z_im *. z_im in
                  if z_re_sq +. z_im_sq > 4.0
                  then (Bytes.set image ((j + x) + (i + y) * size) '1';
                        count)
                  else loopP (count + 1)
                             (z_re_sq -. z_im_sq +. c_re)
                             (2.0 *. z_re *. z_im +. c_im)
                else count in
            let count = loopP 0 c_re c_im in
            loopH (j+1) (iterations + count) in
      let iterations = loopH 0 iterations in
      loopV (i+1) x y w h iterations

let rec mandelbrot x y w h =
    if w <= cutOff && h <= cutOff
    then loopV 0 x y w h 0
    else if w >= h
    then let w2 = w / 2 in
         let t = T.async pool (fun _ -> mandelbrot (x + w2) y (w - w2) h) in
         let a = mandelbrot x y w2 h in
         a + T.await pool t
    else let h2 = h / 2 in
         let t = T.async pool (fun _ -> mandelbrot x (y + h2) w (h - h2)) in
         let a = mandelbrot x y w h2 in
         a + T.await pool t

let doit () =
    mandelbrot 0 0 size size

let rec rep n =
    match n with
    | 0 -> ()
    | n ->
      let t1 = Unix.gettimeofday () in
      let r = doit () in
      let t2 = Unix.gettimeofday () in
(*
      Printf.eprintf "P1\n%d %d\n" size size;
      prerr_string (Bytes.to_string image);
*)
      Printf.printf " - {result: %d, time: %.6f}\n" r (t2 -. t1);
      rep (n - 1)

let _ = Printf.printf
          " bench: mandelbrot_ocaml_domainslib\n size: %d\n cutoff: %d\n results:\n"
          size
          cutOff
let _ = rep repeat
let _ = T.teardown_pool pool
