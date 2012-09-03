(*
multiple nested structure specification.

<ul>
  <li>the level of nesting
    <ul>
      <li>2</li>
    </ul>
  </li>
  <li>contents of structures
    <ul>
      <li>empty</li>
      <li>inner refers outer</li>
      <li>outer refers inner</li>
      <li>both refer each other</li>
    </ul>
  </li>
</ul>
*)
signature S11 =
sig
  structure S 
  : sig
      structure S : sig end
    end
end;

signature S12 =
sig
  structure S 
  : sig
      type t
      datatype dt = D
      structure S : sig val x : t val y : dt end
    end
end;

signature S13 =
sig
  structure S 
  : sig
      structure S : sig type t datatype dt = D end
      val x : S.t
      val y : S.dt
    end
end;

signature S14 =
sig
  structure S 
  : sig
      datatype dt1 = D
      type t1
      structure S : sig type t datatype dt = D of dt1 * t1 end
      val x : S.t
      val y : S.dt
    end
end;
