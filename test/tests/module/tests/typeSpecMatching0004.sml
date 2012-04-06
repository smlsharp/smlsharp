(*
matching of type specification.
error case.
mismatch in equality of type parameters.
<ul>
  <li>declaration in structure
    <ul>
      <li>type declaration</li>
      <li>datatype declaration</li>
    </ul>
  </li>
  <li>the number of parameter type variables
    <ul>
      <li>1</li>
    </ul>
  </li>
  <li>constraint
    <ul>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature S11 = sig type 'a t end;
signature S12 = sig type ''a t end;

structure S11typeTrans : S11 = struct type ''a t = int end;
structure S11typeOpaque :> S11 = struct type ''a t = int end;

structure S12typeTrans : S12 = struct type 'a t = int end;
structure S12typeOpaque :> S12 = struct type 'a t = int end;

structure S11datatypeTrans : S11 = struct datatype ''a t = D of int end;
structure S11datatypeOpaque :> S11 = struct datatype ''a t = D of int end;

structure S12datatypeTrans : S12 = struct datatype 'a t = D of int end;
structure S12datatypeOpaque :> S12 = struct datatype 'a t = D of int end;
