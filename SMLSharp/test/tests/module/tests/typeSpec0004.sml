(*
derived form of type specification:
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
end;

signature S2 =
sig
  type 'a t1 = int * 'a
  and ('a, 'b) t2 = bool t1 * string * 'a * 'b
end;

signature S3 =
sig
  type 'a t1 = ('a, 'a) t2 * int
  and ('a, 'b) t2 = string * 'a * 'b
end;
