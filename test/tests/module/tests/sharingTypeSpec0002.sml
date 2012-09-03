(*
multiple nested "sharing type" specifications.

<ul>
  <li>the number of nested "sharing type" specifications
    <ul>
      <li>2</li>
      <li>3</li>
    </ul>
  </li>
</ul>
*)
signature S2 = 
sig
  type u
  type t
  type s
  sharing type s = t
  sharing type s = u
end;

signature S3 = 
sig
  type s
  type t
  type u
  type v
  sharing type u = t
  sharing type t = s
  sharing type s = v
end;
