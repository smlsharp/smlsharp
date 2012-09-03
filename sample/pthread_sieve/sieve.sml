(**
 * sieve.sml
 *
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)

structure Sieve : sig

  val sieve : int -> unit

end =
struct

  fun stream max =
      let
        val out = MVar.new ()
        fun loop i =
            if i <= max
            then (MVar.put (out, SOME i); loop (i+1))
            else (MVar.put (out, NONE); Pointer.NULL () : unit ptr)
      in
        Pthread.create (fn _ => loop 2);
        out
      end

  fun filter f input =
      let
        val out = MVar.new ()
        fun loop () =
            case MVar.take input of
              NONE => (MVar.put (out, NONE); Pointer.NULL () : unit ptr)
            | SOME x => (if f x then MVar.put (out, SOME x) else (); loop ())
      in
        Pthread.create (fn _ => loop ());
        out
      end

  fun sieve max =
      let
        val input = stream max
        fun loop input =
            case MVar.take input of
              NONE => ()
            | SOME x =>
              (print (Int.toString x ^ "\n");
               loop (filter (fn y => y mod x <> 0) input))
      in
        loop input
      end

end
