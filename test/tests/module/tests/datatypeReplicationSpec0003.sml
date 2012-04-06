(*
name resolution of replicated datatype in a datatype replication specification

<ul>
  <li>preceding datatype specification that specifies the same name with the
    replicated datatype
    <ul>
      <li>yes</li>
    </ul>
  </li>
</ul>
*)
datatype dt1 = D
signature S1 = 
sig
  datatype dt1 = E
  datatype t = datatype dt1
end;

