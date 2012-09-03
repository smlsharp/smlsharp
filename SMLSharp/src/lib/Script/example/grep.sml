(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

val pattern = hd argv;
val file = case tl argv of [] => stdIn | name :: _ => fopen name "r";
app
  (fn line => (if line =~ pattern then print line else ()))
  (readlines file (SOME "\n"));


