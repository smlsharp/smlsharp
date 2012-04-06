signature S =
sig
   structure S : sig type s end
   structure T : sig type t end
   sharing type S.s = T.t
end;
