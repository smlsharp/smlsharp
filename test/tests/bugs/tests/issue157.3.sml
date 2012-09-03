signature SDatatype = sig type et type ft end;
functor FDatatypeTrans(datatype dt = D) : SDatatype = 
struct datatype et = E of dt datatype ft = datatype dt end;
