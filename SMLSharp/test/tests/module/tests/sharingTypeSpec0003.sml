(*
locations of declarations of tyCons connected by "sharing type" specification.

<ul>
  <li>the left hand side tyCon in a "sharing type"
    <ul>
      <li>delcared at the same level with "sharing type"</li>
      <li>declared in inner nested structure</li>
      <li>declared in inner double-nested structure</li>
    </ul>
  </li>
  <li>the right hand side tyCon in a "sharing type"
    <ul>
      <li>delcared at the same level with "sharing type"</li>
      <li>declared in inner nested structure, same with the left</li>
      <li>declared in inner nested structure, different to the left</li>
      <li>declared in inner double-nested structure, same with the left</li>
      <li>declared in inner double-nested structure, different to the left</li>
    </ul>
  </li>
</ul>
*)
signature S11 =
sig
  type s
  type t
  sharing type t = s
end;

(* skip S12 *)

signature S13 =
sig
  type s
  structure T : sig type t end
  sharing type s = T.t
end;

(* skip S14 *)

signature S15 =
sig
  type s
  structure T : sig structure T : sig type t end end
  sharing type s = T.T.t
end;

(********************)

signature S21 =
sig
  structure S : sig type s end
  type t
  sharing type S.s = t
end;

signature S22 =
sig
  structure S : sig type s type t end
  sharing type S.s = S.t
end;

signature S23 =
sig
  structure S : sig type s end
  structure T : sig type t end
  sharing type S.s = T.t
end;

(* skip S24 *)

signature S25 =
sig
  structure S : sig type s end
  structure T : sig structure T : sig type t end end
  sharing type S.s = T.T.t
end;

(********************)

signature S31 =
sig
  structure S : sig structure S : sig type s end end
  type t
  sharing type S.S.s = t
end;

(* skip S32 *)

signature S33 =
sig
  structure S : sig structure S : sig type s end end
  structure T : sig type t end
  sharing type S.S.s = T.t
end;

signature S34 =
sig
  structure S : sig structure S : sig type s type t end end
  sharing type S.S.s = S.S.t
end;

signature S35 =
sig
  structure S : sig structure S : sig type s type t end end
  structure T : sig structure T : sig type t end end
  sharing type S.S.s = T.T.t
end;

(********************)
