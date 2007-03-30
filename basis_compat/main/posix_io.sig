signature POSIX_IO =
  sig
    eqtype file_desc
    eqtype pid
    val pipe : unit -> {infd:file_desc, outfd:file_desc}
    val dup : file_desc -> file_desc
    val dup2 : {new:file_desc, old:file_desc} -> unit
    val close : file_desc -> unit
    val readVec : file_desc * int -> Word8Vector.vector
    val readArr : file_desc * {buf:Word8Array.array, i:int, sz:int option}
                  -> int
    val writeVec : file_desc * {buf:Word8Vector.vector, i:int, sz:int option}
                   -> int
    val writeArr : file_desc * {buf:Word8Array.array, i:int, sz:int option}
                   -> int
    datatype whence = SEEK_CUR | SEEK_END | SEEK_SET
    structure FD :
      sig
        eqtype flags
        val toWord : flags -> Word32.word
        val fromWord : Word32.word -> flags
        val flags : flags list -> flags
        val allSet : flags * flags -> bool
        val anySet : flags * flags -> bool
        val cloexec : flags
      end
    structure O :
      sig
        eqtype flags
        val toWord : flags -> Word32.word
        val fromWord : Word32.word -> flags
        val flags : flags list -> flags
        val allSet : flags * flags -> bool
        val anySet : flags * flags -> bool
        val append : flags
        val dsync : flags
        val nonblock : flags
        val rsync : flags
        val sync : flags
      end
    datatype open_mode = O_RDONLY | O_RDWR | O_WRONLY
    val dupfd : {base:file_desc, old:file_desc} -> file_desc
    val getfd : file_desc -> FD.flags
    val setfd : file_desc * FD.flags -> unit
    val getfl : file_desc -> O.flags * open_mode
    val setfl : file_desc * O.flags -> unit
    datatype lock_type = F_RDLCK | F_UNLCK | F_WRLCK
    structure FLock :
      sig
        type flock
        val flock : {l_len:int, l_pid:pid option, l_start:int,
                     l_type:lock_type, l_whence:whence}
                    -> flock
        val ltype : flock -> lock_type
        val whence : flock -> whence
        val start : flock -> int
        val len : flock -> int
        val pid : flock -> pid option
      end
    val getlk : file_desc * FLock.flock -> FLock.flock
    val setlk : file_desc * FLock.flock -> FLock.flock
    val setlkw : file_desc * FLock.flock -> FLock.flock
    val lseek : file_desc * int * whence -> int
    val fsync : file_desc -> unit
  end
