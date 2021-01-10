module T = Domainslib.Task

let num_domains = try int_of_string (Sys.getenv "NPROCS") with _ -> 1
let repeat = try int_of_string Sys.argv.(1) with _ -> 10
let size = try int_of_string Sys.argv.(2) with _ -> 40
let cutOff = try int_of_string Sys.argv.(3) with _ -> 10
let pool = T.setup_pool ~num_domains:(num_domains - 1)

let rec fib n =
    match n with
    | 0 -> 0
    | 1 -> 1
    | n -> fib (n - 1) + fib (n - 2)

let rec pfib n =
    if n <= cutOff
    then fib n
    else let t = T.async pool (fun _ -> pfib (n - 2)) in
         let a = pfib (n - 1) in
         a + T.await pool t

let doit () = pfib size

let rec rep n =
    match n with
    | 0 -> ()
    | n ->
      let t1 = Unix.gettimeofday () in
      let r = doit () in
      let t2 = Unix.gettimeofday () in
      Printf.printf " - {result: %d, time: %.6f}\n" r (t2 -. t1);
      rep (n - 1)

let _ = Printf.printf
          " bench: fib_ocaml_domainslib\n size: %d\n cutoff: %d\n results:\n"
          size
          cutOff
let _ = rep repeat
let _ = T.teardown_pool pool
