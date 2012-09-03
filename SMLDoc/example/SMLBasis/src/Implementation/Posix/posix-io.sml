(* posix-io.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * Structure for POSIX 1003.1 primitive I/O operations
 *
 *)

local
    structure SysWord = SysWordImp
    structure Int = IntImp
in
structure POSIX_IO =
  struct

    structure FS = POSIX_FileSys

    structure OM : sig 
                      datatype open_mode = O_RDONLY | O_WRONLY | O_RDWR 
                    end = FS
    open OM

    type word = SysWord.word
    type s_int = SysInt.int

    val ++ = SysWord.orb
    val & = SysWord.andb
    infix ++ &

    fun cfun x = CInterface.c_function "POSIX-IO" x
    val osval : string -> s_int = cfun "osval"
    val w_osval = SysWord.fromInt o osval
    fun fail (fct,msg) = raise Fail ("POSIX_IO."^fct^": "^msg)

    type file_desc = FS.file_desc
    type pid = POSIX_Process.pid
    
    val pipe' : unit -> s_int * s_int = cfun "pipe"
    fun pipe () = let
          val (ifd, ofd) = pipe' ()
          in
            {infd = FS.fd ifd, outfd = FS.fd ofd}
          end

    val dup' : s_int -> s_int = cfun "dup"
    val dup2' : s_int * s_int -> unit = cfun "dup2"
    fun dup fd = FS.fd(dup' (FS.intOf fd))
    fun dup2 {old, new} = dup2'(FS.intOf old, FS.intOf new)

    val close' : s_int -> unit = cfun "close"
    fun close fd = close' (FS.intOf fd)

    val read' : int * int -> Word8Vector.vector = cfun "read"
    val readbuf' : int * Word8Array.array * int * int -> int = cfun "readbuf"
    fun readArr (fd, {buf, i, sz=NONE}) = let
          val alen = Word8Array.length buf
          in
            if 0 <= i andalso i <= alen
              then readbuf'(FS.intOf fd, buf, alen - i, i)
              else raise Subscript
          end
      | readArr (fd, {buf, i, sz=SOME sz}) = let
          val alen = Word8Array.length buf
          in
            if 0 <= i andalso 0 <= sz andalso i + sz <= alen
              then readbuf'(FS.intOf fd, buf, sz, i)
              else raise Subscript
          end
    fun readVec (fd,cnt) = 
          if cnt < 0 then raise Subscript else read'(FS.intOf fd, cnt)

    val writevec' : (int * Word8Vector.vector * int * int) -> int = cfun "writebuf"
    val writearr' : (int * Word8Array.array * int * int) -> int = cfun "writebuf"
    fun writeArr (fd,{buf, i, sz=NONE}) = let
          val alen = Word8Array.length buf
          in
            if 0 <= i andalso i <= alen
              then writearr'(FS.intOf fd, buf, alen-i, i)
              else raise Subscript
          end
      | writeArr (fd,{buf, i, sz=SOME sz}) = let
          val alen = Word8Array.length buf
          in
            if 0 <= i andalso 0 <= sz andalso i + sz <= alen
              then writearr'(FS.intOf fd, buf, sz, i)
              else raise Subscript
          end
    
    fun writeVec (fd,{buf, i, sz=NONE}) = let
          val vlen = Word8Vector.length buf
          in
            if 0 <= i andalso i <= vlen
              then writevec'(FS.intOf fd, buf, vlen-i, i)
              else raise Subscript
          end
      | writeVec (fd,{buf, i, sz=SOME sz}) = let
          val vlen = Word8Vector.length buf
          in
            if 0 <= i andalso 0 <= sz andalso i + sz <= vlen
              then writevec'(FS.intOf fd, buf, sz, i)
              else raise Subscript
          end
    
    datatype whence = SEEK_SET | SEEK_CUR | SEEK_END
    val seek_set = osval "SEEK_SET"
    val seek_cur = osval "SEEK_CUR"
    val seek_end = osval "SEEK_END"
    fun whToWord SEEK_SET = seek_set
      | whToWord SEEK_CUR = seek_cur
      | whToWord SEEK_END = seek_end
    fun whFromWord wh =
          if wh = seek_set then SEEK_SET
          else if wh = seek_cur then SEEK_CUR
          else if wh = seek_end then SEEK_END
          else fail ("whFromWord","unknown whence "^(Int.toString wh))
    
    structure FD =
      struct
        datatype flags = FDF of word

        fun fromWord w = FDF w
        fun toWord (FDF w) = w

        fun flags ms = FDF(List.foldl (fn (FDF m,acc) => m ++ acc) 0w0 ms)
        fun anySet (FDF m, FDF m') = (m & m') <> 0w0
        fun allSet (FDF m, FDF m') = (m & m') = m

        val cloexec = FDF(w_osval "cloexec")
      end

    structure O =
      struct
        datatype flags = FS of word

        fun fromWord w = FS w
        fun toWord (FS w) = w

        fun flags ms = FS(List.foldl (fn (FS m,acc) => m ++ acc) 0w0 ms)
        fun anySet (FS m, FS m') = (m & m') <> 0w0
        fun allSet (FS m, FS m') = (m & m') = m

        val append   = FS(w_osval "append")
        val dsync    = FS(w_osval "dsync")
        val nonblock = FS(w_osval "nonblock")
        val rsync    = FS(w_osval "rsync")
        val sync     = FS(w_osval "sync")
      end

    val fcntl_d   : s_int * s_int -> s_int = cfun "fcntl_d"
    val fcntl_gfd : s_int -> word = cfun "fcntl_gfd"
    val fcntl_sfd : (s_int * word) -> unit = cfun "fcntl_sfd"
    val fcntl_gfl : s_int -> (word * word) = cfun "fcntl_gfl"
    val fcntl_sfl : (s_int * word) -> unit = cfun "fcntl_sfl"
    fun dupfd {old, base} = FS.fd (fcntl_d (FS.intOf old, FS.intOf base))
    fun getfd fd = FD.FDF (fcntl_gfd (FS.intOf fd))
    fun setfd (fd, FD.FDF fl) = fcntl_sfd(FS.intOf fd, fl)
    fun getfl fd = let
          val (sts, omode) = fcntl_gfl (FS.intOf fd)
          in
            (O.FS sts, FS.omodeFromWord omode)
          end
    fun setfl (fd, O.FS sts) = fcntl_sfl (FS.intOf fd, sts)

    datatype lock_type = F_RDLCK | F_WRLCK | F_UNLCK

    structure FLock =
      struct
        datatype flock = FLOCK of {
             l_type : lock_type,
             l_whence : whence,
             l_start : Position.int,
             l_len : Position.int,
             l_pid : pid option
           }

        fun flock fv = FLOCK fv
        fun ltype (FLOCK{l_type,...}) = l_type
        fun whence (FLOCK{l_whence,...}) = l_whence
        fun start (FLOCK{l_start,...}) = l_start
        fun len (FLOCK{l_len,...}) = l_len
        fun pid (FLOCK{l_pid,...}) = l_pid
      end

    type flock_rep = s_int * s_int * Position.int * Position.int * s_int

    val fcntl_l : s_int * s_int * flock_rep -> flock_rep = cfun "fcntl_l"
    val f_getlk = osval "F_GETLK"
    val f_setlk = osval "F_SETLK"
    val f_setlkw = osval "F_SETLKW"
    val f_rdlck = osval "F_RDLCK"
    val f_wrlck = osval "F_WRLCK"
    val f_unlck = osval "F_UNLCK"

    fun flockToRep (FLock.FLOCK{l_type,l_whence,l_start,l_len,...}) = let
          fun ltypeOf F_RDLCK = f_rdlck
            | ltypeOf F_WRLCK = f_wrlck
            | ltypeOf F_UNLCK = f_unlck
          in
            (ltypeOf l_type,whToWord l_whence, l_start, l_len, 0)
          end
    fun flockFromRep (usepid,(ltype,whence,start,len,pid)) = let
          fun ltypeOf ltype = 
                if ltype = f_rdlck then F_RDLCK
                else if ltype = f_wrlck then F_WRLCK
                else if ltype = f_unlck then F_UNLCK
                else fail ("flockFromRep","unknown lock type "^(Int.toString ltype))
          in
            FLock.FLOCK { 
              l_type = ltypeOf ltype,
              l_whence = whFromWord whence,
              l_start = start,
              l_len = len,
              l_pid = if usepid then SOME(POSIX_Process.PID pid) else NONE
            }
          end

    fun getlk (fd, flock) =
          flockFromRep(true,fcntl_l(FS.intOf fd,f_getlk,flockToRep flock))
    fun setlk (fd, flock) =
          flockFromRep(false,fcntl_l(FS.intOf fd,f_setlk,flockToRep flock))
    fun setlkw (fd, flock) =
          flockFromRep(false,fcntl_l(FS.intOf fd,f_setlkw,flockToRep flock))

    val lseek' : s_int * Position.int * s_int -> Position.int = cfun "lseek"
    fun lseek (fd,offset,whence) = lseek'(FS.intOf fd,offset, whToWord whence)

    val fsync' : s_int -> unit = cfun "fsync"
    fun fsync fd = fsync' (FS.intOf fd)

  end (* structure POSIX_IO *)
end

