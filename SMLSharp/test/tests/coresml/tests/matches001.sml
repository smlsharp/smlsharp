(*
matches.
rule 13

<ul>
 <li>the number of rules
   <ul>
     <li>1</li>
     <li>2</li>
     <li>3</li>
   </ul>
 </li>
</ul>
 *)

val v1 = case 1 of 1 => 1;

val v21 = case 1 of 1 => 1 | 2 => 2;
val v22 = case 2 of 1 => 1 | 2 => 2;

val v31 = case 1 of 1 => 1 | 2 => 2 | 3 => 3;
val v32 = case 2 of 1 => 1 | 2 => 2 | 3 => 3;
val v33 = case 3 of 1 => 1 | 2 => 2 | 3 => 3;
