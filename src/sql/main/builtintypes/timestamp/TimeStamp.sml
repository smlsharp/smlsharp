structure SMLSharp_SQL_TimeStamp =
struct
local
  type time_t = int
  type timeval = time_t array
  fun allocTimeval () : timeval = Array.array(2,0)
  val gettimeofday = _import "gettimeofday" : (timeval, unit ptr) -> int;
  val timeval_to_string = _import "timeval_to_string" : timeval -> char ptr
  val string_to_time_t = _import "string_to_time_t" : string -> time_t
in
  exception TIMESTAMP
  type timestamp = timeval
  val defaultTimestamp = Array.array(2,0)
  fun now () = 
      let
        val timeval = allocTimeval ()
        val _ = gettimeofday (timeval, Pointer.NULL ())
      in
        timeval
      end
  fun toString (timestamp:timestamp) =
      let
        val charPtr = timeval_to_string timestamp
      in
        Pointer.importString charPtr 
        ^ "."
        ^ Int.toString (Array.sub(timestamp, 1))
      end
  fun fromString string =
      let
        val stringList = 
            String.fields (fn c => case c of #"." => true | _ => false) string
        val (timeTString, usecString) =
            case stringList of
              [a, b] => (a,b)
            | _ => raise TIMESTAMP
        val time_t = string_to_time_t timeTString
        val usec = 
            case Int.fromString usecString of
              SOME usec => usec
            | NONE => 0
      in
        Array.fromList [time_t, usec]
      end

end
end
(*
val a = TimeStamp.now()
val b = TimeStamp.toString a
val _ = print (b ^ "\n")
val c = TimeStamp.fromString b
val d = TimeStamp.toString c
val _ = print (d ^ "\n")
*)
