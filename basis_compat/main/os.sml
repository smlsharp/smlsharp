structure OS : OS =
struct
  open Orig_OS

  structure Path : OS_PATH =
  struct
    open Orig_OS.Path
    val mkAbsolute = 
        fn (path, dir) => mkAbsolute {path = path, relativeTo = dir}
    val mkRelative = 
        fn (path, dir) => mkRelative {path = path, relativeTo = dir}
  end

  structure FileSys : OS_FILE_SYS =
  struct
    open Orig_OS.FileSys
    val readDir = fn name =>
        case readDir name of
          SOME x => x
        | NONE => ""
  end
end
