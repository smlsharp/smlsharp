(**
 * OS.IO
 * @author UENO Katsuhiro
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, 2011, 2012, 2013, Tohoku University.
 *)

infix 6 + - ^
infixr 5 :: @
infix 4 = <> > >= < <=
val op + = SMLSharp_Builtin.Int.add_unsafe
val op - = SMLSharp_Builtin.Int.sub_unsafe
val op < = SMLSharp_Builtin.Int.lt
val op > = SMLSharp_Builtin.Int.gt
structure Word = SMLSharp_Builtin.Word
structure Array = SMLSharp_Builtin.Array

structure OS =
struct
  structure IO =
  struct
    exception Poll  (* define exception with print name "OS.IO.Poll" *)
  end
end

structure SMLSharp_OSIO =
struct

  type iodesc = int

  val hash = Word.fromInt

  fun compare (fd1:iodesc, fd2:iodesc) =
      if fd1 < fd2 then General.LESS
      else if fd1 > fd2 then General.GREATER
      else General.EQUAL

  val prim_stat =
      _import "prim_GenericOS_stat"
      : __attribute__((no_callback,suspend))
        (string, word array) -> int

  val prim_lstat =
      _import "prim_GenericOS_lstat"
      : __attribute__((no_callback,suspend))
        (string, word array) -> int

  val prim_fstat =
      _import "prim_GenericOS_fstat"
      : __attribute__((no_callback,suspend))
        (int, word array) -> int

  val S_IFMT =
      (_import "prim_const_S_IFMT"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_IFIFO =
      (_import "prim_const_S_IFIFO"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_IFCHR =
      (_import "prim_const_S_IFCHR"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_IFDIR =
      (_import "prim_const_S_IFDIR"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_IFBLK =
      (_import "prim_const_S_IFBLK"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_IFREG =
      (_import "prim_const_S_IFREG"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_IFLNK =
      (_import "prim_const_S_IFLNK"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_IFSOCK =
      (_import "prim_const_S_IFSOCK"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_ISUID =
      (_import "prim_const_S_ISUID"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_ISGID =
      (_import "prim_const_S_ISGID"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_ISVTX =
      (_import "prim_const_S_ISVTX"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_IRUSR =
      (_import "prim_const_S_IRUSR"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_IWUSR =
      (_import "prim_const_S_IWUSR"
       : __attribute__((pure,no_callback)) () -> word) ()
  val S_IXUSR =
      (_import "prim_const_S_IXUSR"
       : __attribute__((pure,no_callback)) () -> word) ()

  type stat =
      {dev: word, ino: word, mode: word, atime: word, mtime: word, size: word}

  fun toStat ary =
      {dev = Array.sub_unsafe (ary, 0),
       ino = Array.sub_unsafe (ary, 1),
       mode = Array.sub_unsafe (ary, 2),
       atime = Array.sub_unsafe (ary, 3),
       mtime = Array.sub_unsafe (ary, 4),
       size = Array.sub_unsafe (ary, 5)} : stat

  fun stat filename =
      let
        val ary = Array.alloc 6
        val err = prim_stat (filename, ary)
      in
        if err < 0 then raise SMLSharp_Runtime.OS_SysErr () else ();
        toStat ary
      end

  fun lstat filename =
      let
        val ary = Array.alloc 6
        val err = prim_lstat (filename, ary)
      in
        if err < 0 then raise SMLSharp_Runtime.OS_SysErr () else ();
        toStat ary
      end

  fun fstat fd =
      let
        val ary = Array.alloc 6
        val err = prim_fstat (fd, ary)
      in
        if err < 0 then raise SMLSharp_Runtime.OS_SysErr () else ();
        toStat ary
      end

  type iodesc_kind = word

  structure Kind =
  struct
    val file = S_IFREG
    val dir = S_IFDIR
    val symlink = S_IFLNK
    val tty = S_IFCHR
    val pipe = S_IFIFO
    val socket = S_IFSOCK
    val device = S_IFBLK
  end

  fun kind fd =
      Word.andb (#mode (fstat fd), S_IFMT)

  val prim_poll =
      _import "prim_GenericOS_poll"
      : __attribute__((no_callback,suspend))
        (int array, word array, int, int) -> int

  val SML_POLLIN = 0w1
  val SML_POLLOUT = 0w2
  val SML_POLLPRI = 0w4

  type poll_desc = int * word
  type poll_info = poll_desc

  (* ToDo: return NONE if fd does not support poll *)
  fun pollDesc (fd:iodesc) =
      SOME (fd, 0w0) : poll_desc option

  fun pollToIODesc ((fd, _):poll_desc) = fd:iodesc
  fun pollIn ((fd, ev):poll_desc) = (fd, Word.orb (ev, SML_POLLIN)):poll_desc
  fun pollOut ((fd, ev):poll_desc) = (fd, Word.orb (ev, SML_POLLOUT)):poll_desc
  fun pollPri ((fd, ev):poll_desc) = (fd, Word.orb (ev, SML_POLLPRI)):poll_desc
  fun isIn ((fd, ev):poll_info) = Word.andb (ev, Word.notb SML_POLLIN) <> 0w0
  fun isOut ((fd, ev):poll_info) = Word.andb (ev, Word.notb SML_POLLOUT) <> 0w0
  fun isPri ((fd, ev):poll_info) = Word.andb (ev, Word.notb SML_POLLPRI) <> 0w0
  fun infoToPollDesc (x:poll_info) = x:poll_desc

  exception Poll = OS.IO.Poll

  fun poll (descs, timeoutOpt) =
      let
        fun length (nil : poll_desc list, z) = z
          | length (h::t, z) = length (t, z + 1)
        val len = length (descs, 0)
        val fdary = Array.alloc len
        val evary = Array.alloc len
        fun write (i, nil) = ()
          | write (i, ((fd,ev):poll_desc)::t) =
            (Array.update_unsafe (fdary, i, fd);
             Array.update_unsafe (evary, i, ev);
             write (i + 1, t))
        val _ = write (0, descs)
        val (sec, usec) =
            case timeoutOpt of
              NONE => (~1, ~1)
            | SOME t =>
              let
                val t = Time.toMicroseconds t
              in
                if IntInf.sign t < 0
                then raise SMLSharp_Runtime.SysErr ("nagative timeout", NONE)
                else let val (sec, usec) = IntInf.divMod (t, 1000000)
                     in (IntInf.toInt sec, IntInf.toInt usec)
                     end
              end
        val err = prim_poll (fdary, evary, sec, usec)
        val _ = if err < 0 then raise SMLSharp_Runtime.OS_SysErr () else ()
        fun unzip (i, z) =
            if i < 0 then z
            else unzip (i - 1, (Array.sub_unsafe (fdary, i),
                                Array.sub_unsafe (evary, i)) :: z)
      in
        unzip (len, nil)
      end

  val SEEK_SET =
      _import "prim_const_SEEK_SET"
      : __attribute__((pure,no_callback)) () -> int
  val SEEK_CUR =
      _import "prim_const_SEEK_CUR"
      : __attribute__((pure,no_callback)) () -> int

  type file_desc = int
  val stdin = 0 : file_desc
  val stdout = 1 : file_desc
  val stderr = 2 : file_desc
  type whence = int
  val SEEK_SET = SEEK_SET () : whence
  val SEEK_CUR = SEEK_CUR () : whence

  structure ST =
  struct
    fun isReg ({mode,...}:stat) = Word.andb (mode, S_IFMT) = S_IFDIR
    fun size ({size,...}:stat) = Word.toIntX size
  end

  val prim_close =
      _import "close"
      : __attribute__((no_callback,suspend)) int -> int
  val prim_fopen =
      _import "prim_GenericOS_open"
      : __attribute__((no_callback,suspend)) (string, string) -> int
  val prim_lseek =
      _import "prim_GenericOS_lseek"
      : __attribute__((no_callback,suspend)) (int, int, int) -> int


  fun close fd =
      if prim_close fd < 0 then raise SMLSharp_Runtime.OS_SysErr () else ()

  fun openf (filename, mode) =
      let
        val fd = prim_fopen (filename, mode)
      in
        if fd < 0 then raise SMLSharp_Runtime.OS_SysErr () else fd
      end

  fun lseek (fd, pos, whence) =
      let
        val ret = prim_lseek (fd, pos, whence)
      in
        if ret < 0 then raise SMLSharp_Runtime.OS_SysErr () else ret
      end

  val prim_readAry =
      _import "prim_GenericOS_read"
      : __attribute__((no_callback,suspend))
        (int, SMLSharp_Builtin.Word8.word array, word, word) -> int
  val prim_writeAry =
      _import "prim_GenericOS_write"
      : __attribute__((no_callback,suspend))
        (int, SMLSharp_Builtin.Word8.word array, word, word) -> int

  fun readVec (fd, len) =
      if len < 0 then raise Size else
      let
        val buf = SMLSharp_Builtin.Array.alloc len
        val n = prim_readAry (fd, buf, 0w0, Word.fromInt len)
      in
        if n < 0 then raise SMLSharp_Runtime.OS_SysErr ()
        else if n = len then SMLSharp_Builtin.Array.turnIntoVector buf
        else
          let
            val ret = SMLSharp_Builtin.Array.alloc n
          in
            SMLSharp_Builtin.Array.copy_unsafe (buf, 0, ret, 0, n);
            SMLSharp_Builtin.Array.turnIntoVector ret
          end
      end

  fun readArr (fd, slice) =
      let
        val (buf, beg, len) = Word8ArraySlice.base slice
        val n = prim_readAry (fd, buf, Word.fromInt beg, Word.fromInt len)
      in
        if n < 0 then raise SMLSharp_Runtime.OS_SysErr () else n
      end

  fun writeVec (fd, slice) =
      let
        val (buf, beg, len) = Word8VectorSlice.base slice
        val n = prim_writeAry (fd, SMLSharp_Builtin.Vector.castToArray buf,
                               Word.fromInt beg,
                               Word.fromInt len)
      in
        if n < 0 then raise SMLSharp_Runtime.OS_SysErr () else n
      end

  fun writeArr (fd, slice) =
      let
        val (buf, beg, len) = Word8ArraySlice.base slice
        val n = prim_writeAry (fd, buf,
                               Word.fromInt beg,
                               Word.fromInt len)
      in
        if n < 0 then raise SMLSharp_Runtime.OS_SysErr () else n
      end

end
