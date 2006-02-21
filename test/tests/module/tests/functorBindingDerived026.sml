(*
derived form of functor binding.
<pre>
  funid(spec) : sigexp = ...
  funid(spec) :> sigexp = ...
</pre>

<ul>
  <li>specification in the parameter signature
    <ul>
      <li>datatype replication spec</li>
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
datatype dtDatatypeRep = DDatatypeRep;
signature SDatatypeRep = 
sig datatype et = D of dtDatatypeRep datatype ft = datatype dtDatatypeRep end;
structure PDatatypeRep = struct datatype dt = datatype dtDatatypeRep end;

functor FDatatypeRep(datatype dt = datatype dtDatatypeRep) =
struct datatype et = D of dt datatype ft = datatype dt end;
structure TDatatypeRep = FDatatypeRep(PDatatypeRep);
val xDatatypeRep = TDatatypeRep.D(DDatatypeRep);
val yDatatypeRep = TDatatypeRep.DDatatypeRep;

functor FDatatypeRepTrans(datatype dt = datatype dtDatatypeRep) 
        : SDatatypeRep =
struct datatype et = D of dt datatype ft = datatype dt end;
structure TDatatypeRepTrans = FDatatypeRepTrans(PDatatypeRep);
val xDatatypeRepTrans = TDatatypeRepTrans.D(DDatatypeRep);
val yDatatypeRepTrans = TDatatypeRepTrans.DDatatypeRep;

functor FDatatypeRepOpaq(datatype dt = datatype dtDatatypeRep) 
        :> SDatatypeRep =
struct datatype et = D of dt datatype ft = datatype dt end;
structure TDatatypeRepOpaq = FDatatypeRepOpaq(PDatatypeRep);
val xDatatypeRepOpaq = TDatatypeRepOpaq.D(DDatatypeRep);
val yDatatypeRepOpaq = TDatatypeRepOpaq.DDatatypeRep;
