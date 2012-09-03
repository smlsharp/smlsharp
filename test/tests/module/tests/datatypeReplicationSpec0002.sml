(*
datatype replication specification

<ul>
  <li>the number of type parameter of the replicated datatype
    <ul>
      <li>1</li>
      <li>2</li>
    </ul>
  </li>
</ul>
*)
datatype 'a dt1 = D of 'a
signature S1 = 
sig
  datatype t = datatype dt1
end;

datatype ('b, 'a) dt2 = D of 'a * 'b
signature S2 = 
sig
  datatype t = datatype dt2
end;
