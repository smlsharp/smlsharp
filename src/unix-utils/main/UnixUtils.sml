structure UnixUtils =
struct
local
  structure F = OS.FileSys
in
  fun cd s = F.chDir s
  fun pwd () = F.getDir ()
  fun exit () = OS.Process.terminate OS.Process.success : unit
  fun ls dir = 
      if F.isDir dir then
        let
          val d = F.openDir dir
          fun printFileInDir s =
              let
                val path = dir ^ "/" ^ s
                val s = if F.isDir path then s ^ "/" else 
                        if F.access (path, [F.A_EXEC]) then s ^ "*" else s
              in
                print (s ^ "\n")
              end
          fun readDir () =
              let
                fun readList listRev =
                    let
                      val s = F.readDir d
                    in
                      case s of
                        NONE => listRev
                      | SOME s => readList (s::listRev)
                    end
                val listRev = readList nil
              in
                List.rev listRev
              end
          val _ = List.app printFileInDir (readDir ())
          val _ = F.closeDir d
        in
          ()
        end
      else
        let
          val s = if F.access (dir, [F.A_EXEC]) then dir ^ "*" else dir
        in
          (print s; print "\n")
        end
end
end
open UnixUtils
