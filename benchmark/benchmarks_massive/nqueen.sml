(**
 * nqueen.sml - a parallel N-queen solver
 * @copyright (C) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure NQueen =
struct

  type board =
      {limit : word, left : word, down : word, right : word, kill : word}

  fun init width =
      {limit = Word.<< (0w1, width),
       left = 0w0, down = 0w0, right = 0w0, kill = 0w0} : board

  fun put ({limit, left, down, right, kill}:board) bit : board =
      let
val _ = fn () => put (raise Match) bit
        val left = Word.>> (Word.orb (left, bit), 0w1)
        val down = Word.orb (down, bit)
        val right = Word.<< (Word.orb (right, bit), 0w1)
        val kill = Word.orb (Word.orb (left, down), right)
      in
        {limit = limit, left = left, down = down, right = right, kill = kill}
      end

  fun nextBoards board =
      let
        fun loop (board as {limit, kill, ...} : board) bit =
            if bit >= limit then nil
            else if Word.andb (kill, bit) = 0w0
            then put board bit :: loop board (bit * 0w2)
            else loop board (bit * 0w2)
      in
        loop board 0w1
      end

  fun sum f nil = 0
    | sum f (h::t) = f (h:board) + sum f t

  fun psum f nil = 0
    | psum f (h::t) =
      let
        val k = Myth.Thread.create (fn () => f (h:board))
      in
        psum f t + Myth.Thread.join k
      end

  fun solve cutOff 0w0 board = 1
    | solve cutOff queens board =
      if queens <= cutOff
      then sum (fn x => solve cutOff (queens - 0w1) x) (nextBoards board)
      else psum (fn x => solve cutOff (queens - 0w1) x) (nextBoards board)

  fun nqueen {cutOff, width} =
      solve cutOff width (init width)

end

structure Main =
struct
  fun getEnv name =
      case OS.Process.getEnv name of
        NONE => NONE
      | SOME s => StringCvt.scanString (Word.scan StringCvt.DEC) s
  fun run () =
      NQueen.nqueen {cutOff = getOpt (getEnv "CUTOFF", 0w8),
                     width = getOpt (getEnv "WIDTH", 0w14)}
  fun doit () = (run (); ())
  fun testit out = TextIO.output (out, Int.toString (run ()) ^ "\n")
end

(*
val _ = Main.testit TextIO.stdOut
val _ = Main.doit ()
*)
val doit = Main.doit


fun rep 0 = ()
  | rep n =
    let val t = Time.now ()
        val () = doit ()
    in print (Time.fmt 6 (Time.- (Time.now (), t))); print "\n";
       rep (n - 1)
    end
val _ = rep 3
