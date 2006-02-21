(*
recursive reference between bindings in the same val rec declaration.
rule 26

<p>
The test cases are numbered according to references between bindings.
References are indicated by bits.
Bindings are ordered sequentially.
Assume n bindings B1, ..., Bn in this order.
A (n-1) bits indicate references from each binding to others.
The most significant bit indicates a reference to B2 from B1, B1 from
others.
For example, assume 3 bindings B1, B2, B3.
For B1, 10 indicates a reference to B2 and no reference to B3.
For B2, 11 indicates two references to B1 and B3.
For B3, 01 indicates no reference to B1 and a reference to B2.
Then, concatnate three of 3 bits, 231 (= 10-11-01) indicates the references
between these bindings. And
  - B1 -><- B2 -><- B3 -
means the same state of references.
</p>
<ul>
  <li>the number of bindings
    <ul>
      <li>1</li>
      <li>2</li>
      <li>3</li>
    </ul>
  </li>
  <li>dependency between bindings
    (ToDo : enumerate cases.)
  </li>
  <li>types of bindings
    <ul>
      <li>monotype</li>
    </ul>
  </li>
</ul>
 *)
val rec v01 = fn x => if 0 = x then 1 else v01 (x - 1);
val w0 = v01 1;

(* v011 <- v012 *)
val rec v011 = fn x => if 0 = x then 1 else v011 (x - 1)
and v012 = fn x => if 0 = x then 1 else v011 (x - 1);
val w01 = (v011 2, v012 2);

(* v101 -> v102 *)
val rec v101 = fn x => if 0 = x then 1 else v102 (x - 1)
and v102 = fn x => if 0 = x then 1 else v102 (x - 1);
val w10 = (v101 2, v102 2);

(* v111 -><- v112 *)
val rec v111 = fn x => if 0 = x then 1 else v112 (x - 1)
and v112 = fn x => if 0 = x then 1 else v111 (x - 1);
val w11 = (v111 2, v112 2);

(* v001 - v002 *)
val rec v001 = fn x => if 0 = x then 1 else v001 (x - 1)
and v002 = fn x => if 0 = x then 1 else v002 (x - 1);
val w00 = (v001 2, v002 2);

(* 333: <- v3331 -><- v3332 -><- v3333 -> *)
val 
rec v3331 = fn x => case x of 0 => 1 | 1 => v3332 (x - 1) | _ => v3333 (x - 1)
and v3332 = fn x => case x of 0 => 1 | 1 => v3331 (x - 1) | _ => v3333 (x - 1)
and v3333 = fn x => case x of 0 => 1 | 1 => v3331 (x - 1) | _ => v3332 (x - 1)
val w333 = (v3331 3, v3332 3, v3333 3);

(* 120: - v1201 -><- v1202 - v1203 - *)
val 
rec v1201 = fn x => case x of 0 => 1 | 1 => v1202 (x - 1) | _ => v1201 (x - 1)
and v1202 = fn x => case x of 0 => 1 | 1 => v1201 (x - 1) | _ => v1202 (x - 1)
and v1203 = fn x => case x of 0 => 1 | 1 => v1203 (x - 1) | _ => v1203 (x - 1)
val w120 = (v1201 3, v1202 3, v1203 3);

(* 201: <- v2011 - v2012 - v2013 -> *)
val 
rec v2011 = fn x => case x of 0 => 1 | 1 => v2011 (x - 1) | _ => v2013 (x - 1)
and v2012 = fn x => case x of 0 => 1 | 1 => v2012 (x - 1) | _ => v2012 (x - 1)
and v2013 = fn x => case x of 0 => 1 | 1 => v2011 (x - 1) | _ => v2013 (x - 1)
val w201 = (v2011 3, v2012 3, v2013 3);

(* 012: - v0121 - v0122 -><- v0123 - *)
val 
rec v0121 = fn x => case x of 0 => 1 | 1 => v0121 (x - 1) | _ => v0121 (x - 1)
and v0122 = fn x => case x of 0 => 1 | 1 => v0122 (x - 1) | _ => v0123 (x - 1)
and v0123 = fn x => case x of 0 => 1 | 1 => v0123 (x - 1) | _ => v0122 (x - 1)
val w012 = (v0121 3, v0122 3, v0123 3);

(* 000: - v0001 - v0002 - v0003 - *)
val 
rec v0001 = fn x => case x of 0 => 1 | 1 => v0001 (x - 1) | _ => v0001 (x - 1)
and v0002 = fn x => case x of 0 => 1 | 1 => v0002 (x - 1) | _ => v0002 (x - 1)
and v0003 = fn x => case x of 0 => 1 | 1 => v0003 (x - 1) | _ => v0003 (x - 1)
val w000 = (v0001 3, v0002 3, v0003 3);

(* ToDo : more test cases should be written for three bindings. *)
