(*
datatype replication specification

<ul>
  <li>location of declaration of the replicated datatype
    <ul>
      <li>global</li>
      <li>in a structure</li>
    </ul>
  </li>
</ul>
*)
datatype dt1 = D
signature S1 = 
sig
  datatype t = datatype dt1
end;

structure S2 =
struct
  datatype dt = D
end;
signature S2 = 
sig
  datatype t = datatype S2.dt
end;
