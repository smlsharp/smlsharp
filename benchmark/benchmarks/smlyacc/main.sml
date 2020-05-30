(* main.sml
 *)

structure Main (*: BMARK*) =
  struct
    val s = OS.FileSys.getDir()
    fun doit() = ParseGen.parseGen(s^"/DATA/ml.grm"){p=NONE, s=false}
    fun testit _ = ParseGen.parseGen(s^"/DATA/ml.grm"){p=NONE, s=false}
  end
