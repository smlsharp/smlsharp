(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

val file = case argv of [] => stdIn | name :: _ => fopen name "r";
val (ls, ws, cs) =
    foldl
        (fn (line, (ls, ws, cs)) =>
            (
              ls + 1,
              ws + length (tokens "[ \t]" line),
              cs + (size line)
            ))
        (0, 0, 0)
        (readlines file (SOME "\n"));
print (itoa ls ^ " " ^ itoa ws ^ " " ^ itoa cs ^ "\n");
