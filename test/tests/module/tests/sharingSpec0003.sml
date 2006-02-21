(*
locations of declarations of structures connected by "sharing" specification.

<ul>
  <li>the left hand side structure in a "sharing"
    <ul>
      <li>delcared at the same level with "sharing"</li>
      <li>declared in inner nested structure</li>
    </ul>
  </li>
  <li>the right hand side tyCon in a "sharing"
    <ul>
      <li>delcared at the same level with "sharing"</li>
      <li>declared in inner nested structure, same with the left</li>
      <li>declared in inner nested structure, different to the left</li>
    </ul>
  </li>
</ul>
*)
signature S11 =
sig
  structure S : sig type t end
  structure T : sig type t end
  sharing T = S
end;

(* skip S12 *)

signature S13 =
sig
  structure S : sig type t end
  structure T : sig structure T : sig type t end end
  sharing S = T.T
end;

(********************)

signature S21 =
sig
  structure S : sig structure S : sig type t end end
  structure T : sig type t end
  sharing S.S = T
end;

signature S22 =
sig
  structure S
    : sig
        structure S : sig type t end
        structure T : sig type t end
      end
  sharing S.S = S.T
end;

signature S23 =
sig
  structure S : sig structure S : sig type t end end
  structure T : sig structure T : sig type t end end
  sharing S.S = T.T
end;

(********************)
