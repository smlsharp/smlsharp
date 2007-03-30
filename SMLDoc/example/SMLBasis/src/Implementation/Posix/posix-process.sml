(* posix-process.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * Structure for POSIX 1003.1 process submodule
 *
 *)

local
    structure SysWord = SysWordImp
    structure Word8 = Word8Imp
    structure Time = TimeImp
    structure Int = IntImp
in
structure POSIX_Process =
  struct

    structure Sig = POSIX_Signal

    val ++ = SysWord.orb
    val & = SysWord.andb
    infix ++ &

    type word = SysWord.word
    type s_int = SysInt.int

    type signal = Sig.signal
    datatype pid = PID of s_int
    fun pidToWord (PID i) = SysWord.fromInt i
    fun wordToPid w = PID (SysWord.toInt w)
    
    fun cfun x = CInterface.c_function "POSIX-Process" x
    val osval : string -> s_int = cfun "osval"
    val w_osval = SysWord.fromInt o osval

    val sysconf : string -> SysWord.word =
          CInterface.c_function "POSIX-ProcEnv" "sysconf"

    val fork' : unit -> s_int = cfun "fork"
    fun fork () =
          case fork' () of
            0 => NONE
          | child_pid => SOME(PID child_pid)
    
    fun exec (x: string * string list) : 'a = cfun "exec" x
    fun exece (x: string * string list * string list) : 'a = cfun "exece" x
    fun execp (x: string * string list): 'a = cfun "execp" x

    datatype waitpid_arg
      = W_ANY_CHILD 
      | W_CHILD of pid 
      | W_SAME_GROUP
      | W_GROUP of pid
    
    datatype killpid_arg
      = K_PROC of pid
      | K_SAME_GROUP
      | K_GROUP of pid

    datatype exit_status
      = W_EXITED
      | W_EXITSTATUS of Word8.word
      | W_SIGNALED of signal
      | W_STOPPED of signal
    
      (* (pid',status,status_val) = waitpid' (pid,options)  *)
    val waitpid' : s_int * word -> s_int * s_int * s_int = cfun "waitpid"

    fun argToInt W_ANY_CHILD = ~1
      | argToInt (W_CHILD (PID pid)) = pid
      | argToInt (W_SAME_GROUP) = 0
      | argToInt (W_GROUP (PID pid)) = ~pid

      (* The exit status from wait is encoded as a pair of integers.
       * If the first integer is 0, the child exited normally, and
       * the second integer gives its exit value.
       * If the first integer is 1, the child exited due to an uncaught
       * signal, and the second integer gives the signal value.
       * Otherwise, the child is stopped and the second integer 
       * gives the signal value that caused the child to stop.
       *)
    fun mkExitStatus (0,0) = W_EXITED
      | mkExitStatus (0,v) = W_EXITSTATUS(Word8.fromInt v)
      | mkExitStatus (1,s) = W_SIGNALED (Sig.SIG s)
      | mkExitStatus (_,s) = W_STOPPED (Sig.SIG s)


    val wnohang = w_osval "WNOHANG"
    structure W =
      struct
        datatype flags = WF of word

        fun fromWord w = WF w
        fun toWord (WF w) = w

        fun flags ms = WF(List.foldl (fn (WF m,acc) => m ++ acc) 0w0 ms)
        fun anySet (WF m, WF m') = (m & m') <> 0w0
        fun allSet (WF m, WF m') = (m & m') = m

        fun orF (WF f,acc) = f ++ acc

        val untraced =
          WF(sysconf "JOB_CONTROL"; w_osval "WUNTRACED") handle _ => WF 0w0
      end

    fun waitpid (arg,flags) = let
          val (pid,status,sv) = waitpid'(argToInt arg, List.foldl W.orF 0w0 flags)
          in
            (PID pid, mkExitStatus(status,sv))
          end

    fun waitpid_nh (arg,flags) =
          case waitpid'(argToInt arg, List.foldl W.orF wnohang flags) of
            (0,_,_) => NONE
          | (pid,status,sv) => SOME(PID pid, mkExitStatus(status,sv))

    fun wait () = waitpid(W_ANY_CHILD,[])
    
    fun exit (x: Word8.word) : 'a = cfun "exit" x
    
    val kill' : s_int * s_int -> unit = cfun "kill"
    fun kill (K_PROC (PID pid),Sig.SIG s) = kill'(pid, s)
      | kill (K_SAME_GROUP,Sig.SIG s) = kill'(~1, s)
      | kill (K_GROUP (PID pid),Sig.SIG s) = kill'(~pid, s)
    
    local
      fun wrap f t =
	    Time.fromSeconds(Int.toLarge(f(Int.fromLarge(Time.toSeconds t))))
      val alarm' : int -> int = cfun "alarm"
      val sleep' : int -> int = cfun "sleep"
    in
    val alarm = wrap alarm'
    val sleep = wrap sleep'
    end

    val pause : unit -> unit = cfun "pause"


  end (* structure POSIX_Process *)
end

