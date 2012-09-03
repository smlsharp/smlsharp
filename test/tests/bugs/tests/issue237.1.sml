(* OK -- monotype and in structure *)
structure S = 
struct
  datatype dt1 = D1
  and dt2 = D2
end;

(* OK -- polytype and toplevel *)
datatype dt1 = D1
and 'a dt2 = D2

(* NG -- polytype and in structure *)
structure S = 
struct
  datatype dt1 = D1
  and 'a dt2 = D2
end;

