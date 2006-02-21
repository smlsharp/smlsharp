(*
precedence of andalso and orelse

<ul>
  <li>order of conjunctions/disjunctions
    <ul>
      <li>andalso - orelse - andalso</li>
      <li>orelse - andalso - orelse</li>
    </ul>
  </li>
</ul>
 *)
val v11 = (print "1"; true)
         andalso (print "2"; true)
         orelse (print "3"; true)
         andalso (print "4"; true);
val v12 = ((print "1"; true) andalso (print "2"; true))
          orelse ((print "3"; true) andalso (print "4"; true));
val v13 = (print "1"; true)
         andalso ((print "2"; true) orelse (print "3"; true))
         andalso (print "4"; true);

val v21 = (print "1"; true)
         orelse (print "2"; true)
         andalso (print "3"; true)
         orelse (print "4"; true);
val v22 = ((print "1"; true) orelse (print "2"; true))
         andalso ((print "3"; true) orelse (print "4"; true));
val v23 = (print "1"; true)
         orelse ((print "2"; true) andalso (print "3"; true))
         orelse (print "4"; true);
