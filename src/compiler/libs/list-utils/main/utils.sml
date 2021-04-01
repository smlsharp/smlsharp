(**
 * @copyright (C) 2021 SML# Development Team.
 * @author Atsushi Ohori
 *)
structure ListUtils =
struct
  fun split l n =
      let
        fun loop (nil, r, i) =
            (rev r, if i > 0 then NONE else SOME nil)
          | loop (h::l, r, i) =
            if i > 0 then loop (l, h::r, i - 1) else (rev r, SOME (h::l))
      in
        loop (l, nil, n)
      end
  fun prefixList L =
      foldl
      (fn (h, L) => [h] :: (map (fn x => h::x) L))
      nil
      (rev L)
      
  fun ('a) listEq (elemEq:'a * 'a -> bool) (L1,L2) =
      let
        fun eq (nil,nil) = true
          | eq (h::_, nil) = false
          | eq (nil, h::_) = false
          | eq (h1::tl1, h2::tl2) = 
            elemEq(h1, h2) andalso eq (tl1,tl2)
      in
        eq (L1,L2) 
      end

end
