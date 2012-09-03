functor FStructure (S : sig structure T : sig datatype dt = D end end) =
struct structure T = S.T end;
structure TStructure = FStructure(structure T = struct datatype dt = D end);
structure SStructure = TStructure.T;
