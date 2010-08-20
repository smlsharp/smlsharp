(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

(* strip HTML tag. *)
val file = case argv of [] => stdIn | name :: _ => fopen name "r";
app (print o (global_subst "<[^>]*>" "")) (readlines file (SOME "\n"));
