(*
matching of sharing specification.

<ul>
  <li>the number of strid connected
    <ul>
      <li>3</li>
    </ul>
  </li>
  <li>the number of type names common among the connected structures
    <ul>
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

signature S32 = 
sig
  structure T1 : sig type t1 datatype t2 = D val x : t2 end
  structure T2 : sig type t1 datatype t2 = D val x : t2 end
  structure T3 : sig type t1 datatype t2 = D val x : t2 end
  sharing T1 = T2 = T3
  val x : T1.t2 * T2.t2 * T3.t2
end;

structure S32 =
struct
  structure T1 = struct type t1 = int datatype t2 = D val x = D end
  structure T2 =
  struct type t1 = int datatype t2 = datatype T1.t2 val x = D end
  structure T3 =
  struct type t1 = int datatype t2 = datatype T1.t2 val x = D end
  val x = (T1.x, T2.x, T3.x)
end;

structure S32Trans = S32 : S32;
val (xTrans1, xTrans2, xTrans3) = S32Trans.x

structure S32Opaque = S32 :> S32;
val (xOpaque1, xOpaque2, xOpaque3) = S32Opaque.x
