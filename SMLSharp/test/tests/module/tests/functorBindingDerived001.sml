(*
derived form of functor binding.
<pre>
  funid(strid : sigexp) : sigexp = ...
  funid(strid : sigexp) :> sigexp = ...
</pre>

<ul>
  <li>constraint
    <ul>
      <li>transparent</li>
      <li>opaque</li>
    </ul>
  </li>
</ul>
*)
signature PSIG =
sig
  type t
  eqtype et
  datatype ('a, 'b) dt = D | E of 'a * 'b
  val x : (t, et) dt
  exception F
  structure S : sig val f : bool -> (t, et) dt end
end;
structure PSTR = 
struct
  type t = real
  type et = string
  datatype ('a, 'b) dt = D | E of 'a * 'b
  val x = E(1.23, "a")
  exception F
  structure S = struct fun f true = D | f false = raise F end
end;

signature FSIG =
sig
  type s
  eqtype es
  datatype ('a, 'b) ds = D | E of 'a * 'b
  val x : (s, es) ds
  exception F
  structure S : sig val f : bool -> (s, es) ds end
end;

functor FTrans(S : PSIG) : FSIG = 
struct
  type s = S.t
  type es = S.et
  datatype ds = datatype S.dt
  val x = S.x
  exception F = S.F
  structure S = S.S
end;
structure TTrans = FTrans(PSTR);
val xTrans = TTrans.x;
val yTrans = TTrans.S.f false handle TTrans.F => TTrans.x;

functor FOpaq(S : PSIG) :> FSIG = 
struct
  type s = S.t
  type es = S.et
  datatype ds = datatype S.dt
  val x = S.x
  exception F = S.F
  structure S = S.S
end;
structure TOpaq = FOpaq(PSTR);
val xOpaq = TOpaq.x;
val yOpaq = TOpaq.S.f false handle TOpaq.F => TOpaq.x;
