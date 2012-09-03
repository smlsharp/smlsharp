(* (C) 1999 Lucent Technologies, Bell Laboratories *)

structure SMLofNJ : SML_OF_NJ =
  struct
    open SMLofNJ
    val exportML = Export.exportML
    val exportFn = Export.exportFn
    structure Cont = Cont
    structure IntervalTimer = IntervalTimer
    structure Internals = Internals
    structure SysInfo = SysInfo
    structure Weak = Weak
  end
