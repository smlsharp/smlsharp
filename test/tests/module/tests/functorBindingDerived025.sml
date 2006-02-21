(*
derived form of functor binding.
<pre>
  funid(spec) : sigexp = ...
  funid(spec) :> sigexp = ...
</pre>

<ul>
  <li>specification in the parameter signature
    <ul>
      <li>datatype spec</li>
    </ul>
  </li>
  <li>constraint
    <ul>
      <li>none</li>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature SDatatype = sig type et type ft end;
structure PDatatype = struct datatype dt = D end;

functor FDatatype(datatype dt = D) = 
struct datatype et = E of dt datatype ft = datatype dt end;
structure TDatatype = FDatatype(PDatatype);
datatype dtDatatype = DDatatype of TDatatype.et;
val xDatatype = TDatatype.E(TDatatype.D);

functor FDatatypeTrans(datatype dt = D) : SDatatype = 
struct datatype et = E of dt datatype ft = datatype dt end;
structure TDatatypeTrans = FDatatypeTrans(PDatatype);
datatype dtDatatypeTrans = DDatatypeTrans of TDatatypeTrans.et;
(*
val xDatatypeTrans = TDatatypeTrans.E(TDatatypeTrans.D);
*)

functor FDatatypeOpaq(datatype dt = D) :> SDatatype = 
struct datatype et = E of dt datatype ft = datatype dt end;
structure TDatatypeOpaq = FDatatypeOpaq(PDatatype);
datatype dtDatatypeOpaq = DDatatypeOpaq of TDatatypeOpaq.et;
(*
val xDatatypeOpaq = TDatatypeOpaq.E(TDatatypeOpaq.D);
*)
