signature SDatatype = sig structure S : sig datatype dt = D end end;
structure SDatatypeOpaque :> SDatatype = 
struct structure S = struct datatype dt = D end end;

(*
2012-07-13 ymukade

structure SDatatypeOpaque 内の
datatype dt (SDatatypeOpaque.S) = D
(SDatatypeOpaque.S.dt) までプリントされない

signature SDatatype =
  sig
    structure S : sig
      datatype dt = D
    end
  end
structure SDatatypeOpaque =
  struct
    structure S =
      struct
        datatype dt (SDatatypeOpaque.S) = D
      end
  end
*)


(*
2012-07-19 ohori
Fixed by 4321:e8fef45e043f
*)
