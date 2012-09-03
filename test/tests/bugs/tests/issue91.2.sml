local datatype dt1 = D1 in datatype dt1 = datatype dt1 end;
val x1 = D1;

local datatype dt2 = D2 in datatype dt22 = datatype dt2 end;
val x2 = D2;

local datatype ('a, 'b) dt31 = D31 of 'a * 'b and 'c dt32 = D32 of 'c
in datatype dt = datatype dt31 end;
val x = D31(1, "abc");

local datatype ('a, 'b) dt41 = D41 of 'a * 'b and 'c dt42 = D42 of 'c
in datatype dt41 = datatype dt41 end;
val x = D41(1, "abc");
