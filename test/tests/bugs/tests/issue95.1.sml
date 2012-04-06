signature S13 =
sig
  structure S 
  : sig
      structure S : sig type t datatype dt = D end
      val x : S.t
      val y : S.dt
    end
end;
