signature TIME =
  sig
    eqtype time (*= Orig_Time.time*)
    exception Time
    val zeroTime : time
    val fromReal : real -> time
    val toReal : time -> real
    val toSeconds : time -> Int32.int
    val fromSeconds : Int32.int -> time
    val toMilliseconds : time -> Int32.int
    val fromMilliseconds : Int32.int -> time
    val toMicroseconds : time -> Int32.int
    val fromMicroseconds : Int32.int -> time
    val + : time * time -> time
    val - : time * time -> time
    val compare : time * time -> order
    val < : time * time -> bool
    val <= : time * time -> bool
    val > : time * time -> bool
    val >= : time * time -> bool
    val now : unit -> time
    val toString : time -> string
    val fromString : string -> time option
    val fmt : int -> time -> string
    val scan : (char,'a) StringCvt.reader -> (time,'a) StringCvt.reader
  end
