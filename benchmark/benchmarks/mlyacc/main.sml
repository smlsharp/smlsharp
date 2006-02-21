(* main.sml
 *)

structure Main =
  struct
    val s = "../benchmarks/mlyacc/" (* relative path from 'bin' dir. *)
(*
    val s = OS.FileSys.getDir()
*)
    fun doit() = ParseGen.parseGen(s^"/DATA/ml.grm")
    fun testit _ = ParseGen.parseGen(s^"/DATA/ml.grm")
  end
