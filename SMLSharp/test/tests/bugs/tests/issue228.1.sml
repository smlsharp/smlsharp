(** val rec declaration **)

val rec f = fn x => x
and f = fn x => g x 
and g = fn x => f x;

(* bound in a typed pattern *)
val rec f = fn x => x
and f : int -> int = fn x => g x 
and g = fn x => f x;

(* duplication of two names *)
val rec f = fn x => x
and g = fn x => f x
and f = fn x => g x 
and g = fn x => f x;


(** fun declaration **)

(* mutual reference *)
fun f x = g x
and g x = f x
and f x = f x;

(* separated by VALREC optimizer. *)
fun f x = x
and f x = g x
and g x = f x;

(* separated by VALREC optimizer. *)
fun f x = g x
and g x = f x
and f x = x;

fun f x = g x
and g x = f x
and f x = g x
and g x = f x;
