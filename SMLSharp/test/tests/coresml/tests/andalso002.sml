(*
left associative of andalso.

<ul>
  <li>the number of repeated of andalso
    <ul>
      <li>2</li>
      <li>3</li>
    </ul>
  </li>
</ul>
 *)
val v1 = (print "1"; true)
         andalso (print "2"; true)
         andalso (print "3"; true);

val v2 = (print "1"; true)
         andalso (print "2"; true)
         andalso (print "3"; true)
         andalso (print "4"; true);
