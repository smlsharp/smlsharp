signature SDatatype = sig structure S : sig datatype dt = D end end;
structure SDatatypeTrans : SDatatype = 
struct structure S = struct datatype dt = D end end;
