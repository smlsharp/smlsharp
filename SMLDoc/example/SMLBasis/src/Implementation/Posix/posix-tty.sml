(* posix-tty.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * Structure for POSIX 1003.1 operations on terminal devices
 *
 *)

local
    structure SysWord = SysWordImp
in
structure POSIX_TTY =
  struct

    structure FS = POSIX_FileSys
    structure P = POSIX_Process

    type pid = POSIX_Process.pid
    type file_desc = POSIX_FileSys.file_desc
    
    type word = SysWord.word
    type s_int = SysInt.int

    val ++ = SysWord.orb
    val & = SysWord.andb
    infix ++ &

    fun cfun x = CInterface.c_function "POSIX-TTY" x
    val osval : string -> s_int = cfun "osval"
    val w_osval = SysWord.fromInt o osval

    structure I =
      struct
        datatype flags = F of word

        fun fromWord w = F w
        fun toWord (F w) = w

        fun flags ms = F(List.foldl (fn (F m,acc) => m ++ acc) 0w0 ms)
        fun anySet (F m, F m') = (m & m') <> 0w0
        fun allSet (F m, F m') = (m & m') = m

        val brkint = F (w_osval "BRKINT")
        val icrnl  = F (w_osval "ICRNL")
        val ignbrk = F (w_osval "IGNBRK")
        val igncr  = F (w_osval "IGNCR")
        val ignpar = F (w_osval "IGNPAR")
        val inlcr  = F (w_osval "INLCR")
        val inpck  = F (w_osval "INPCK")
        val istrip = F (w_osval "ISTRIP")
        val ixoff  = F (w_osval "IXOFF")
        val ixon   = F (w_osval "IXON")
        val parmrk = F (w_osval "PARMRK")
      end

    structure O =
      struct
        datatype flags = F of word

        fun fromWord w = F w
        fun toWord (F w) = w

        fun flags ms = F(List.foldl (fn (F m,acc) => m ++ acc) 0w0 ms)
        fun anySet (F m, F m') = (m & m') <> 0w0
        fun allSet (F m, F m') = (m & m') = m

        val opost = F (w_osval "OPOST")
      end

    structure C =
      struct
        datatype flags = F of word

        fun fromWord w = F w
        fun toWord (F w) = w

        fun flags ms = F(List.foldl (fn (F m,acc) => m ++ acc) 0w0 ms)
        fun anySet (F m, F m') = (m & m') <> 0w0
        fun allSet (F m, F m') = (m & m') = m

        val clocal = F (w_osval "CLOCAL")
        val cread  = F (w_osval "CREAD")
        val csize  = F (w_osval "CSIZE")
        val cs5    = F (w_osval "CS5")
        val cs6    = F (w_osval "CS6")
        val cs7    = F (w_osval "CS7")
        val cs8    = F (w_osval "CS8")
        val cstopb = F (w_osval "CSTOPB")
        val hupcl  = F (w_osval "HUPCL")
        val parenb = F (w_osval "PARENB")
        val parodd = F (w_osval "PARODD")
      end

    structure L =
      struct
        datatype flags = F of word

        fun fromWord w = F w
        fun toWord (F w) = w

        fun flags ms = F(List.foldl (fn (F m,acc) => m ++ acc) 0w0 ms)
        fun anySet (F m, F m') = (m & m') <> 0w0
        fun allSet (F m, F m') = (m & m') = m

        val echo   = F (w_osval "ECHO")
        val echoe  = F (w_osval "ECHOE")
        val echok  = F (w_osval "ECHOK")
        val echonl = F (w_osval "ECHONL")
        val icanon = F (w_osval "ICANON")
        val iexten = F (w_osval "IEXTEN")
        val isig   = F (w_osval "ISIG")
        val noflsh = F (w_osval "NOFLSH")
        val tostop = F (w_osval "TOSTOP")
      end

    structure V =
      struct
        structure WV = Word8Vector
        structure WA = Word8Array
        structure B = Byte

        val nccs = osval "NCCS"

        val eof   = (osval "EOF")
        val eol   = (osval "EOL")
        val erase = (osval "ERASE")
        val intr  = (osval "INTR")
        val kill  = (osval "KILL")
        val min   = (osval "MIN")
        val quit  = (osval "QUIT")
        val susp  = (osval "SUSP")
        val time  = (osval "TIME")
        val start = (osval "START")
        val stop  = (osval "STOP")

        datatype cc = CC of WV.vector

        fun mkCC (arr, l) = let
              fun update (i, c) = WA.update(arr, i, B.charToByte c)
              in
                List.app update l;
                CC (WA.vector arr)
              end

        fun cc vals = mkCC (WA.array(nccs, 0w0), vals)
        fun update (CC v, vals) =
              mkCC (WA.tabulate (nccs, fn i => WV.sub(v,i)), vals)
        fun sub (CC v, i) = B.byteToChar (WV.sub(v,i))
      end

    datatype speed = B of word
    fun compareSpeed (B w, B w') =
          if SysWord.<(w, w') then LESS
          else if w = w' then EQUAL
          else GREATER
    fun speedToWord (B w) = w
    fun wordToSpeed w = B w
    val b0 = B (w_osval "B0")
    val b50 = B (w_osval "B50")
    val b75 = B (w_osval "B75")
    val b110 = B (w_osval "B110")
    val b134 = B (w_osval "B134")
    val b150 = B (w_osval "B150")
    val b200 = B (w_osval "B200")
    val b300 = B (w_osval "B300")
    val b600 = B (w_osval "B600")
    val b1200 = B (w_osval "B1200")
    val b1800 = B (w_osval "B1800")
    val b2400 = B (w_osval "B2400")
    val b4800 = B (w_osval "B4800")
    val b9600 = B (w_osval "B9600")
    val b19200 = B (w_osval "B19200")
    val b38400 = B (w_osval "B38400")
    
    datatype termios = TIOS of {
        iflag : I.flags,
        oflag : O.flags,
        cflag : C.flags,
        lflag : L.flags,
        cc : V.cc,
        ispeed : speed,
        ospeed : speed
      }

    fun termios arg = TIOS arg
    fun fieldsOf (TIOS arg) = arg
    fun getiflag (TIOS{iflag, ...}) = iflag
    fun getoflag (TIOS{oflag, ...}) = oflag
    fun getcflag (TIOS{cflag, ...}) = cflag
    fun getlflag (TIOS{lflag, ...}) = lflag
    fun getcc (TIOS{cc,...}) = cc

    fun getospeed (TIOS{ospeed,...}) = ospeed
    fun getispeed (TIOS{ispeed,...}) = ispeed

    fun setospeed (TIOS r, ospeed) =
          TIOS {
            iflag = #iflag r,
            oflag = #oflag r,
            cflag = #cflag r,
            lflag = #lflag r,
            cc = #cc r,
            ispeed = #ispeed r,
            ospeed = ospeed
          }
    fun setispeed (TIOS r, ispeed) =
          TIOS {
            iflag = #iflag r,
            oflag = #oflag r,
            cflag = #cflag r,
            lflag = #lflag r,
            cc = #cc r,
            ispeed = ispeed,
            ospeed = #ospeed r
          }
    
    structure TC =
      struct
        datatype set_action = SA of s_int

        val sanow = SA (osval "TCSANOW")
        val sadrain = SA (osval "TCSADRAIN")
        val saflush = SA (osval "TCSAFLUSH")

        datatype flow_action = FA of s_int

        val ooff = FA (osval "TCOOFF")
        val oon = FA (osval "TCOON")
        val ioff = FA (osval "TCIOFF")
        val ion = FA (osval "TCION")

        datatype queue_sel = QS of s_int

        val iflush = QS (osval "TCIFLUSH")
        val oflush = QS (osval "TCOFLUSH")
        val ioflush = QS (osval "TCIOFLUSH")
      end

    type termio_rep = (
           word *       	(* iflags *)
           word *       	(* oflags *)
           word *       	(* cflags *)
           word *       	(* lflags *)
           V.WV.vector *	(* cc *)
           word *		(* inspeed *)
	   word			(* outspeed *)
         )

    val tcgetattr : int -> termio_rep = cfun "tcgetattr"
    fun getattr fd = let
          val (ifs,ofs,cfs,lfs,cc,isp,osp) = tcgetattr (FS.intOf fd)
          in
            TIOS {
              iflag = I.F ifs,
              oflag = O.F ofs,
              cflag = C.F cfs,
              lflag = L.F lfs,
              cc = V.CC cc,
              ispeed = B isp,
              ospeed = B osp
            }
          end

    val tcsetattr : int * s_int * termio_rep -> unit = cfun "tcsetattr"
    fun setattr (fd, TC.SA sa, TIOS tios) = let
          val (I.F iflag) = #iflag tios
          val (O.F oflag) = #oflag tios
          val (C.F cflag) = #cflag tios
          val (L.F lflag) = #lflag tios
          val (V.CC cc) = #cc tios
          val (B ispeed) = #ispeed tios
          val (B ospeed) = #ospeed tios
          val trep = (iflag,oflag,cflag,lflag,cc,ispeed,ospeed)
          in
            tcsetattr (FS.intOf fd, sa, trep)
          end

    val tcsendbreak : int * int -> unit = cfun "tcsendbreak"
    fun sendbreak (fd, duration) = tcsendbreak (FS.intOf fd, duration)

    val tcdrain : int -> unit = cfun "tcdrain"
    fun drain fd = tcdrain (FS.intOf fd)

    val tcflush : int * s_int -> unit = cfun "tcflush"
    fun flush (fd, TC.QS qs) = tcflush (FS.intOf fd, qs)

    val tcflow : int * s_int -> unit = cfun "tcflow"
    fun flow (fd, TC.FA action) = tcflow (FS.intOf fd, action)

    val tcgetpgrp : int -> s_int = cfun "tcgetpgrp"
    fun getpgrp fd = P.PID(tcgetpgrp(FS.intOf fd))

    val tcsetpgrp : int * s_int -> unit = cfun "tcsetpgrp"
    fun setpgrp (fd, P.PID pid) = tcsetpgrp(FS.intOf fd, pid)

  end (* structure POSIX_TTY *)
end

