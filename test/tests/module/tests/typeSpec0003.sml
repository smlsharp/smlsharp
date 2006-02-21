(*
derived form of type specification:
<pre>
  type tyvarseq tycon = ty
</pre>

<ul>
  <li>type name in the type expression
    <ul>
      <li>globally defined type name</li>
      <li>type name specified in the same signature</li>
      <li>type name specified in an inner structure in the same signature</li>
    </ul>
  <li>
</ul>
*)
datatype dt = D;
signature S1 =
sig
  type t1 = dt
end;

signature S2 =
sig
  type t1
  type t2 = t1 * string
end;

signature S3 =
sig
  structure S : sig type t1 end
  type t2 = S.t1 * string
end;
