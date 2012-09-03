(*
derived form of "where type".

<ul>
  <li>the number of clauses connected by "and".
    <ul>
      <li>3</li>
    </ul>
  </li>
  <li>duplication of the left side type name
    <ul>
      <li>no</li>
      <li>yes</li>
    </ul>
  </li>
</ul>
*)
signature S3n = 
sig
  type t1
  type t2
  type t3
end
    where type t1 = int
      and type t2 = string 
      and type t3 = bool;

type s1 = int;
type s2 = int;
type s3 = string;
signature S3y = 
sig
  type t1
  type s2
end
    where type t1 = s1
      and type t1 = s2
      and type s2 = s3;
