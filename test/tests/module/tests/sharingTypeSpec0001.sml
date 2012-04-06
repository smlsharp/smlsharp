(*
multiple "sharing type" specification.

<ul>
  <li>the number of tyCons in a "sharing type"
    <ul>
      <li>2</li>
      <li>3</li>
    </ul>
  </li>
</ul>
*)
signature S2 = 
sig
  type t
  type s
  sharing type s = t
end;

signature S3 = 
sig
  type s
  type t
  type u
  sharing type u = t = s
end;

