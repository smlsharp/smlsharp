(**
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)
structure Dictionary :> DICTIONARY =
struct

  datatype (''key, 'value) dict = Dict of (''key * 'value) list

  exception NotFound

  fun create () = Dict [];

  fun exists (Dict ls) name =
      List.exists (fn (n, v) => (n = name)) ls

  fun lookup (Dict ((n, v) :: others)) name =
      if n = name
      then v
      else lookup (Dict others) name
    | lookup (Dict []) name = raise NotFound;

  fun size (Dict ls) = List.length ls;

  fun isEmpty (Dict []) = true
    | isEmpty _ = false;

  fun update (Dict ts) name value =
      let
	fun inup checked ((n, v) :: others) =
	    if n = name then
	      (n, value) :: (checked @ others)
	    else
	      inup ((n, v) :: checked) others
	  | inup checked [] = (name, value) :: checked
      in
	Dict (inup [] ts)
      end;

  fun remove (Dict ts) name =
      let
        fun rm checked ((n, v) :: others) =
            if n = name
            then rm checked others
	    else rm ((n, v) :: checked) others
	  | rm checked [] = checked
      in
	Dict (rm [] ts)
      end

  fun aslist (Dict ls) = ls;

  fun keys (Dict ((n, _) :: others)) = n :: (keys (Dict others))
    | keys (Dict []) = [];

  fun items (Dict ((_, v) :: others)) = v::(items (Dict others))
    | items (Dict []) = [];

  fun mapkeys (Dict ls) f =
      Dict (map (fn (k, v) => (f k, v)) ls);

  fun mapitems (Dict ls) f =
      Dict (map (fn (k, v) => (k, f v)) ls);

end;
