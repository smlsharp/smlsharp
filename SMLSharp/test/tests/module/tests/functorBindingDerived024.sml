(*
derived form of functor binding.
<pre>
  funid(spec) : sigexp = ...
  funid(spec) :> sigexp = ...
</pre>

<ul>
  <li>specification in the parameter signature
    <ul>
      <li>eqtype spec</li>
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
signature SEqType = sig type dt end;
structure PEqType = struct type t = string end;

functor FEqType(eqtype t) = struct datatype dt = D of t end;
structure TEqType = FEqType(PEqType);
datatype dtEqType = DEqType of TEqType.dt;
val xEqType = TEqType.D "abc";

functor FEqTypeTrans(eqtype t) : SEqType = struct datatype dt = D of t end;
structure TEqTypeTrans = FEqTypeTrans(PEqType);
datatype dtEqTypeTrans = DEqTypeTrans of TEqTypeTrans.dt;
(*
val xEqTypeTrans = TEqTypeTrans.D "abc";
*)

functor FEqTypeOpaq(eqtype t) :> SEqType = struct datatype dt = D of t end;
structure TEqTypeOpaq = FEqTypeOpaq(PEqType);
datatype dtEqTypeOpaq = DEqTypeOpaq of TEqTypeOpaq.dt;
(*
val xEqTypeOpaq = TEqTypeOpaq.D "abc";
*)
