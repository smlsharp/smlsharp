module T = Domainslib.Task

let num_domains = try int_of_string (Sys.getenv "NPROCS") with _ -> 1
let repeat = try int_of_string Sys.argv.(1) with _ -> 10
let size = try int_of_string Sys.argv.(2) with _ -> 14
let cutOff = try int_of_string Sys.argv.(3) with _ -> 7
let pool = T.setup_pool ~num_domains:(num_domains - 1)

type board =
    {queens : int; limit : int;
     left : int; down : int; right : int; kill : int}

let init width =
    {queens = width; limit = 1 lsl width;
     left = 0; down = 0; right = 0; kill = 0}

let put board bit =
    let left = (board.left lor bit) lsr 1 in
    let down = board.down lor bit in
    let right = (board.right lor bit) lsl 1 in
    let kill = left lor down lor right in
    {queens = board.queens - 1; limit = board.limit;
     left = left; down = down; right = right; kill = kill}

let rec ssum board bit =
    if bit >= board.limit then 0
    else if board.kill land bit = 0
    then solve (put board bit) + ssum board (bit lsl 1)
    else ssum board (bit lsl 1)

and psum board bit =
    if bit >= board.limit then 0
    else if board.kill land bit = 0
    then let k = T.async pool (fun _ -> solve (put board bit)) in
         let a = psum board (bit lsl 1) in
         a + T.await pool k
    else psum board (bit lsl 1)

and solve board =
    if board.queens = 0 then 1
    else if board.queens <= cutOff
    then ssum board 1
    else psum board 1

let doit () = solve (init size)

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
          " bench: nqueen_ocaml_domainslib\n size: %d\n cutoff: %d\n results:\n"
          size
          cutOff
let _ = rep repeat
let _ = T.teardown_pool pool
