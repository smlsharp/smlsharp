(*
derived form of functor binding.
<pre>
  funid(spec) : sigexp = ...
  funid(spec) :> sigexp = ...
</pre>

<ul>
  <li>specification in the parameter signature
    <ul>
      <li>val spec</li>
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
signature SVal = sig val y : int end;
structure PVal = struct val x = 2 end;

functor FVal(val x : int) = struct val y = x end;
structure TVal = FVal(PVal);
val xVal = TVal.y;

functor FValTrans(val x : int) : SVal = struct val y = x end;
structure TValTrans = FValTrans(PVal);
val xValTrans = TValTrans.y;

functor FValOpaq(val x : int) :> SVal = struct val y = x end;
structure TValOpaq = FValOpaq(PVal);
val xValOpaq = TValOpaq.y;

