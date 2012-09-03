(*
left associative of orelse

<ul>
  <li>the number of repeated of orelse
    <ul>
      <li>2</li>
      <li>3</li>
    </ul>
  </li>
</ul>
 *)
val v1 = (print "1"; false)
         orelse (print "2"; false)
         orelse (print "3"; false);

val v2 = (print "1"; false)
         orelse (print "2"; false)
         orelse (print "3"; false)
         orelse (print "4"; false);
