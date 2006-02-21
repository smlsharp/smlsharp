(*
derived form of functor binding.
<pre>
  funid(spec) : sigexp = ...
  funid(spec) :> sigexp = ...
</pre>

<ul>
  <li>specification in the parameter signature
    <ul>
      <li>empty</li>
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
(********************)
signature SEmpty = sig end;
structure PEmpty = struct end;

functor FEmpty() = struct end;
structure TEmpty = FEmpty(PEmpty);

functor FEmptyTrans() : SEmpty = struct end;
structure TEmptyTrans = FEmptyTrans(PEmpty);

functor FEmptyOpaq() :> SEmpty = struct end;
structure TEmptyOpaq = FEmptyOpaq(PEmpty);

