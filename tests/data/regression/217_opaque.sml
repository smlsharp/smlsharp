signature S = 
sig
  structure T1 : sig datatype dt = D end
  structure T2 : sig datatype dt = D end
  sharing T1 = T2
end;

structure S =
struct
  structure T1 = struct datatype dt = D end
  structure T2 = struct datatype dt = datatype T1.dt end
end;

structure SOpaque = S :> S

(*
2012-07-09 endom

structureにopaqueでsignatureを適用させると、型が本来展開されるべき形に展開されない。例えば、
structure SOpaque =
  struct
    structure T1 =
      struct
        datatype dt (SOpaque.T2) = D
      end
    structure T2 =
      struct
        datatype dt (SOpaque.T2) = D
      end
  end
ではなく
structure SOpaque =
  struct
    structure T1 =
      struct
        datatype dt (SOpaque.T1) = D
      end
    structure T2 =
      struct
        datatype dt (SOpaque.T1) = D
      end
  end
と出力されるはずである。
*)

(*
2012-07-19 ohori.
Let us consider this not a bug.
*)
