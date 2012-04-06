(*
recursive reference between bindings in the same val rec declaration.
rule 26

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
      <li>polytype</li>
    </ul>
  </li>
</ul>
 *)
val rec v01 = fn (x, y) => if 0 = x then 1 else v01 (x - 1, y);
val w0 = v01 (1, true);

(* v011 <- v012 *)
val rec v011 = fn (x, y) => if 0 = x then 1 else v011 (x - 1, y)
and v012 = fn (x, y) => if 0 = x then 1 else v011 (x - 1, y);
val w01 = (v011 (2, true), v012 (2, "foo"));

(* v101 -> v102 *)
val rec v101 = fn (x, y) => if 0 = x then 1 else v102 (x - 1, y)
and v102 = fn (x, y) => if 0 = x then 1 else v102 (x - 1, y);
val w10 = (v101 (2, true), v102 (2, "foo"));

(* v111 -><- v112 *)
val rec v111 = fn (x, y) => if 0 = x then 1 else v112 (x - 1, y)
and v112 = fn (x, y) => if 0 = x then 1 else v111 (x - 1, y);
val w11 = (v111 (2, true), v112 (2, "foo"));

(* v001 - v002 *)
val rec v001 = fn (x, y) => if 0 = x then 1 else v001 (x - 1, y)
and v002 = fn (x, y) => if 0 = x then 1 else v002 (x - 1, y);
val w00 = (v001 (2, true), v002 (2, "foo"));

(* 333: <- v3331 -><- v3332 -><- v3333 -> *)
val 
rec v3331 = fn (x, y) => case x of 0 => 1 | 1 => v3332 (x - 1, y) | _ => v3333 (x - 1, y)
and v3332 = fn (x, y) => case x of 0 => 1 | 1 => v3331 (x - 1, y) | _ => v3333 (x - 1, y)
and v3333 = fn (x, y) => case x of 0 => 1 | 1 => v3331 (x - 1, y) | _ => v3332 (x - 1, y)
val w333 = (v3331 (3, true), v3332 (3, "foo"), v3333 (3, 1.23));

(* 120: - v1201 -><- v1202 - v1203 - *)
val 
rec v1201 = fn (x, y) => case x of 0 => 1 | 1 => v1202 (x - 1, y) | _ => v1201 (x - 1, y)
and v1202 = fn (x, y) => case x of 0 => 1 | 1 => v1201 (x - 1, y) | _ => v1202 (x - 1, y)
and v1203 = fn (x, y) => case x of 0 => 1 | 1 => v1203 (x - 1, y) | _ => v1203 (x - 1, y)
val w120 = (v1201 (3, true), v1202 (3, "foo"), v1203 (3, 1.23));

(* 201: <- v2011 - v2012 - v2013 -> *)
val 
rec v2011 = fn (x, y) => case x of 0 => 1 | 1 => v2011 (x - 1, y) | _ => v2013 (x - 1, y)
and v2012 = fn (x, y) => case x of 0 => 1 | 1 => v2012 (x - 1, y) | _ => v2012 (x - 1, y)
and v2013 = fn (x, y) => case x of 0 => 1 | 1 => v2011 (x - 1, y) | _ => v2013 (x - 1, y)
val w201 = (v2011 (3, true), v2012 (3, "foo"), v2013 (3, 1.23));

(* 012: - v0121 - v0122 -><- v0123 - *)
val 
rec v0121 = fn (x, y) => case x of 0 => 1 | 1 => v0121 (x - 1, y) | _ => v0121 (x - 1, y)
and v0122 = fn (x, y) => case x of 0 => 1 | 1 => v0122 (x - 1, y) | _ => v0123 (x - 1, y)
and v0123 = fn (x, y) => case x of 0 => 1 | 1 => v0123 (x - 1, y) | _ => v0122 (x - 1, y)
val w012 = (v0121 (3, true), v0122 (3, "foo"), v0123 (3, 1.23));

(* 000: - v0001 - v0002 - v0003 - *)
val 
rec v0001 = fn (x, y) => case x of 0 => 1 | 1 => v0001 (x - 1, y) | _ => v0001 (x - 1, y)
and v0002 = fn (x, y) => case x of 0 => 1 | 1 => v0002 (x - 1, y) | _ => v0002 (x - 1, y)
and v0003 = fn (x, y) => case x of 0 => 1 | 1 => v0003 (x - 1, y) | _ => v0003 (x - 1, y)
val w000 = (v0001 (3, true), v0002 (3, "foo"), v0003 (3, 1.23));

(* ToDo : more test cases should be written for three bindings. *)
