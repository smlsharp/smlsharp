(*
matching of derived form of type specification:
<pre>
  type tyvarseq tycon = ty
   and ...
   and tyvarseq tycon = ty
</pre>

<ul>
  <li>relation between type names in a type specifcation
    <ul>
      <li>no relation</li>
      <li>successor refers to predecessor</li>
      <li>predecessor refers to successor</li>
    </ul>
  <li>
</ul>
*)
signature S1 =
sig
  type 'a t1 = int * 'a
  and ('a, 'b) t2 = string * 'a * 'b
  val x : string t1 * (real, bool) t2
end;
structure S1 =
struct
  type 'a t1 = int * 'a
  and ('a, 'b) t2 = string * 'a * 'b
  val x = ((1, "x"), ("a", 1.23, true))
end;
structure S1Trans = S1 : S1;
val (x1Trans1 : string S1Trans.t1, x1Trans2 : (real, bool) S1Trans.t2) =
    S1Trans.x;
structure S1Opaque = S1 : S1;
val (x1Opaque1 : string S1Opaque.t1, x1Opaque2 : (real, bool) S1Opaque.t2) =
    S1Opaque.x;

(********************)

signature S2 =
sig
  type 'a t1 = int * 'a
  and ('a, 'b) t2 = bool t1 * string * 'a * 'b
  val x : string t1 * (real, bool) t2
end;
structure S2 =
struct
  type 'a t1 = int * 'a
  type ('a, 'b) t2 = bool t1 * string * 'a * 'b
  val x = ((1, "x"), ((2, false), "a", 1.23, true))
end;
structure S2Trans = S2 : S2;
val (x2Trans1 : string S2Trans.t1, x2Trans2 : (real, bool) S2Trans.t2) =
    S2Trans.x;
structure S2Opaque = S2 : S2;
val (x2Opaque1 : string S2Opaque.t1, x2Opaque2 : (real, bool) S2Opaque.t2) =
    S2Opaque.x;

signature S3 =
sig
  type 'a t1 = ('a, 'a) t2 * int
  and ('a, 'b) t2 = string * 'a * 'b
end;
