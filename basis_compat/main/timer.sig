signature TIMER =
  sig
    type cpu_timer
    type real_timer
    val totalCPUTimer : unit -> cpu_timer
    val startCPUTimer : unit -> cpu_timer
    val checkCPUTimer : cpu_timer
                        -> {gc:Time.time, sys:Time.time, usr:Time.time}
    val totalRealTimer : unit -> real_timer
    val startRealTimer : unit -> real_timer
    val checkRealTimer : real_timer -> Time.time
  end
