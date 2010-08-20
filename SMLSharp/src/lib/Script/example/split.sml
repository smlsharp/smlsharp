(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

val (src, dest) = case argv of src :: dest :: _ => (src, dest);
val lines = 4; (* split into 10-line pieces. (not 9) *)
val count = ref 0;
fun destName () = dest ^ "." ^ itoa (!count) before count := !count + 1;
val (_, file) =
    foldl
    (fn (line, (ls, file)) => 
        (
          fputs file line;
          if 0 = ls
          then (fclose file; (lines, fopen (destName()) "w"))
          else (ls - 1, file)
        ))
    (lines, fopen (destName()) "w")
    (readlines (fopen src "r") (SOME "\n"));
fclose file;
