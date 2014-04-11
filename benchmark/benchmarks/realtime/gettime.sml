val cgettime = _import "cgettime" : int array -> unit
val A = Array.array(2,0)
fun gettime () =
    let
      val _ = cgettime A
    in
      {sec=Array.sub(A,0), nsec=Array.sub(A,1)}
    end

fun difftime ({sec=s1, nsec=n1}, {sec=s2, nsec=n2}) =
    let
      val s = s2 - s1
      val n = n2 - n1
    in 
      if n < 0
      then {sec = s - 1, nsec = n + 1000000000}
      else {sec = s, nsec = n}
    end

fun timestr {sec, nsec} =
    Int.toString sec ^ "." ^ StringCvt.padLeft #"0" 9 (Int.toString nsec)
