val x = Array.array(1,99);
val y = Array.sub(x,2) 
        handle
        Subscript => (print "1 ****\n"; 1) 
      | _ => (print "2 ****\n"; raise Subscript)

(*
2011-12-16 ohori
"2 ****" is printed.
*)

(*
2011-12-16 katsu

Fixed by changeset 69572f16179f and 81b07685f985.

Both AIGenerator and the native runtime did not follow the latest
changes of exception handling completely.

*)
