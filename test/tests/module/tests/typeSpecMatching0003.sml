(*
matching of type specification.
error case.
mismatch in arity.
<ul>
  <li>declaration in structure
    <ul>
      <li>type declaration</li>
      <li>datatype declaration</li>
    </ul>
  </li>
  <li>the number of parameter type variables
    <ul>
      <li>0</li>
      <li>1</li>
      <li>2</li>
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
signature S0 = sig type t end;
signature S1 = sig type 'a t end;
signature S2 = sig type ('a, 'b) t end;

structure S0typeTrans : S0 = struct type 'a t = int * 'a end;
structure S0typeOpaque :> S0 = struct type 'a t = int * 'a end;

structure S1typeTrans : S1 = struct type t = int end;
structure S1typeOpaque :> S1 = struct type t = int end;

structure S2typeTrans : S2 = struct type ('a, 'b, 'c) t = int end;
structure S2typeOpaque :> S2 = struct type ('a, 'b, 'c) t = int end;

structure S0datatypeTrans : S0 = struct datatype 'a t = D of int * 'a end;
structure S0datatypeOpaque :> S0 = struct datatype 'a t = D of int * 'a end;

structure S1datatypeTrans : S1 = struct datatype t = D of int end;
structure S1datatypeOpaque :> S1 = struct datatype t = D of int end;

structure S2datatypeTrans : S2 = struct datatype 'a t = D of int * 'a end;
structure S2datatypeOpaque :> S2 = struct datatype 'a t = D of int * 'a end;
