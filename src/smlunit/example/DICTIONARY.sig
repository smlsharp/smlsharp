(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
signature DICTIONARY =
sig

  (***************************************************************************
   type descriptions
   ***************************************************************************)

  type (''key, 'value) dict

  (***************************************************************************
   exception descriptions
   ***************************************************************************)

  exception NotFound

  (***************************************************************************
   value descriptions
   ***************************************************************************)

  val create : unit -> (''a, 'b) dict

  val exists : (''a, 'b) dict -> ''a -> bool

  val lookup : (''a, 'b) dict -> ''a -> 'b

  val size : (''a, 'b) dict -> int

  val isEmpty : (''a, 'b) dict -> bool

  val update : (''a, 'b) dict -> ''a -> 'b -> (''a, 'b) dict

  val remove : (''a, 'b) dict -> ''a -> (''a, 'b) dict

  val aslist : (''a, 'b) dict -> (''a * 'b) list

  val keys : (''a, 'b) dict -> ''a list

  val items : (''a, 'b) dict -> 'b list

  val mapkeys : (''a, 'b) dict -> (''a -> ''c) -> (''c, 'b) dict

  val mapitems : (''a, 'b) dict -> ('b -> 'c) -> (''a, 'c) dict

end
