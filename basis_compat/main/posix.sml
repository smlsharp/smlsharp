structure Posix : POSIX =
struct
  open Orig_Posix

  structure IO : POSIX_IO =
  struct
    open Orig_Posix.IO
    val readArr = fn (fd, {buf, i, sz}) =>
        readArr (fd, Word8ArraySlice.slice (buf, i, sz))
    val writeVec = fn (fd, {buf, i, sz}) =>
        writeVec (fd, Word8VectorSlice.slice (buf, i, sz))
    val writeArr = fn (fd, {buf, i, sz}) =>
        writeArr (fd, Word8ArraySlice.slice (buf, i, sz))
    structure FLock =
    struct
      open Orig_Posix.IO.FLock
      val flock = fn {l_len, l_pid, l_start, l_type, l_whence} =>
          flock {len = l_len, pid = l_pid, start = l_start,
                 ltype = l_type, whence = l_whence }
    end
  end
end
