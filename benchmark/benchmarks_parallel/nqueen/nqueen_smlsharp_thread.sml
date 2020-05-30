val args = CommandLine.arguments ()
val repeat = case args of s::_ => valOf (Int.fromString s) | _ => 10
val size = case args of _::s::_ => valOf (Int.fromString s) | _ => 14
val cutOff = case args of _::_::s::_ => valOf (Int.fromString s) | _ => 7

type board =
    {queens : word, limit : word,
     left : word, down : word, right : word, kill : word}

fun init width =
    {queens = width, limit = Word.<< (0w1, width),
     left = 0w0, down = 0w0, right = 0w0, kill = 0w0} : board

fun put ({queens, limit, left, down, right, kill}:board) bit : board =
    let
val _ = fn x => put x (* dummy for uncurrying optimization *)
      val left = Word.>> (Word.orb (left, bit), 0w1)
      val down = Word.orb (down, bit)
      val right = Word.<< (Word.orb (right, bit), 0w1)
      val kill = Word.orb (Word.orb (left, down), right)
    in
      {queens = queens - 0w1, limit = limit,
       left = left, down = down, right = right, kill = kill}
    end

fun ssum (board as {limit, kill, ...}) bit =
    if bit >= limit then 0
    else if Word.andb (kill, bit) = 0w0
    then solve (put board bit) + ssum board (Word.<< (bit, 0w1))
    else ssum board (Word.<< (bit, 0w1))

and psum (board as {limit, kill, ...}) bit =
    if bit >= limit then 0
    else if Word.andb (kill, bit) = 0w0
    then let val k = Thread.create (fn () => solve (put board bit))
         in psum board (Word.<< (bit, 0w1)) + Thread.join k
         end
    else psum board (Word.<< (bit, 0w1))

and solve {queens = 0w0, ...} = 1
  | solve (board as {queens, ...} : board) =
    if queens <= Word.fromInt cutOff
    then ssum board 0w1
    else psum board 0w1

fun doit () = solve (init (Word.fromInt size))

fun rep 0 = ()
  | rep n =
    let val t1 = Time.now ()
        val r = doit ()
        val t2 = Time.now ()
        val d1 = Time.toReal t1
        val d2 = Time.toReal t2
    in (_import "printf" : (string,...(int,real)) -> int)
         (" - {result: %d, time: %.6f}\n", r, d2 - d1);
       rep (n - 1)
    end

val _ = (_import "printf" : (string,...(string,int,int)) -> int)
          (" bench: nqueen_smlsharp_%s\n size: %d\n cutoff: %d\n results:\n",
           Thread.threadtype, size, cutOff)
val r = rep repeat
