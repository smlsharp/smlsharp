val args = CommandLine.arguments ()
val valOf = Option.valOf
val repeat = case args of s::_ => valOf (Int.fromString s) | _ => 10
val size = case args of _::s::_ => valOf (Int.fromString s) | _ => 14
val cutOff = case args of _::_::s::_ => valOf (Int.fromString s) | _ => 7

type board =
    Word64.word * Word64.word * Word64.word
    * Word64.word * Word64.word * Word64.word
    (* queens * limit * left * down * right * kill *)

fun init width =
    (width, Word64.lsh (1, width), 0, 0, 0, 0) : board

fun put ((queens, limit, left, down, right, kill):board) bit : board =
    let
      val left = Word64.rsh (Word64.orb (left, bit), 1)
      val down = Word64.orb (down, bit)
      val right = Word64.lsh (Word64.orb (right, bit), 1)
      val kill = Word64.orb (Word64.orb (left, down), right)
    in
      (queens - 1, limit, left, down, right, kill)
    end

fun ssum (board : board) bit =
    case board of (_, limit, _, _, _, kill) =>
    if bit >= limit then 0
    else if Word64.andb (kill, bit) = 0
    then solve (put board bit) + ssum board (Word64.lsh (bit, 1))
    else ssum board (Word64.lsh (bit, 1))

and psum (board : board) bit =
    case board of (_, limit, _, _, _, kill) =>
    if bit >= limit then 0
    else if Word64.andb (kill, bit) = 0
    then let val (k, n) = (| solve (put board bit),
                             psum board (Word64.lsh (bit, 1)) |)
         in k + n
         end
    else psum board (Word64.lsh (bit, 1))

and solve (board : board) =
    case board of (queens, _, _, _, _, _) =>
    if queens = 0 then 1
    else if queens <= Word64.fromInt cutOff
    then ssum board 1
    else psum board 1

fun doit () = solve (init (Word64.fromInt size))

fun rep 0 = ()
  | rep n =
    let val (r, t) = Time.timeToEval doit
        (* val _ = print (Int.toString r ^ "\n") *)
    in print (" - {result: " ^ Int.toString r ^ ", time: "
              ^ Time.toString t ^ "}\n");
       rep (n - 1)
    end

val _ = print (" bench: nqueen_manticore_ptuple\n size: "
               ^ Int.toString size ^ "\n cutoff: " ^ Int.toString cutOff
               ^ "\n results:\n")
val _ = rep repeat
