(*
sigexp included by "include" specification.

<ul>
  <li>included signature exp.
    <ul>
      <li>basic signature exp.</li>
      <li>ID of top level signature</li>
      <li>ID of inner signature declared in the same signature</li>
      <li>"where type" signature exp</li>
    </ul>
  </li>
</ul>
*)
signature S1 =
sig
  type s
  include sig type t datatype dt = D of t val x : s * t * dt end
  val y : dt * t 
end;

signature S2Top =
sig type t datatype dt = D of t val x : t * dt end;
signature S2 = sig include S2Top val y : dt * t end;

(* This should be error because "include" accepts only top level signature. *)
signature S3 =
sig
  structure S3Inner :
  sig type t datatype dt = D of t val x : t * dt end
  include S3Inner
  val y : dt * t
end;

signature S4 =
sig
  type s
  include
    sig type t datatype dt = D of t val x : s * t * dt end where type t = s
  val y : dt * t 
end;
