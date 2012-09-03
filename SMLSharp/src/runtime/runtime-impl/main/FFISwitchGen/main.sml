structure Main =
struct
  fun main (_, args) =
      let
        val (arg1, arg2) =
            case args of
              w::x::y::z => (OS.FileSys.chDir w; (x, y))
            | x::y::z => (x, y)
            | _ => raise Fail "too few arguments"
      in
        case (Int.fromString arg1, Int.fromString arg2) of
          (SOME m, SOME n) => (FFISwitchGen.main m n; OS.Process.success)
        | _ => raise Fail "invalid number"
      end
end
