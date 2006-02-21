(*
derived form of functor binding.
<pre>
  funid(spec) : sigexp = ...
  funid(spec) :> sigexp = ...
</pre>

<ul>
  <li>specification in the parameter signature
    <ul>
      <li>type spec</li>
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
signature SType = sig type dt end;
structure PType = struct type t = real end;

functor FType(type t) = struct datatype dt = D of t end;
structure TType = FType(PType);
datatype dtType = DType of TType.dt;
val xType = TType.D(1.23);

functor FTypeTrans(type t) : SType = struct datatype dt = D of t end;
structure TTypeTrans = FTypeTrans(PType);
datatype dtTypeTrans = DTypeTrans of TTypeTrans.dt;
(*
val xTypeTrans = TTypeTrans.D(1.23);
*)

functor FTypeOpaq(type t) :> SType = struct datatype dt = D of t end;
structure TTypeOpaq = FTypeOpaq(PType);
datatype dtTypeOpaq = DTypeOpaq of TTypeOpaq.dt;
(*
val xTypeOpaq = TTypeOpaq.D(1.23);
*)
