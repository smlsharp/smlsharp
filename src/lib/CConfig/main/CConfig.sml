(**
 * System configuration inspection by using C compiler.
 *
 * @copyright (c) 2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: CConfig.sml,v 1.1 2007/03/17 15:09:03 katsu Exp $
 *)
structure CConfig : C_CONFIG =
struct

  (***************************************************************************)

  infix //
  infixr 7 ifNone ifSome
  infixr 8 $
  infixr 9 try ensure

  local
      datatype 'a err = Error of exn | Success of 'a
  in
  fun f $ x = f x
  fun x try f = f x
  fun f ensure g =
      fn x => let val v = Success (f x) handle e => Error e
                  val () = g x
              in case v of Error e => raise e | Success v => v
              end
  end

  val op // = OS.Path.concat

  fun x ifNone f = case x of SOME x => x | NONE => f ()
  fun x ifSome f = case x of SOME x => SOME (f x) | NONE => NONE

  (***************************************************************************)

  (*** utilities ***)

  fun mkdtemp () =
      let val name = OS.FileSys.tmpName ()
          val _ = OS.FileSys.mkDir name
      in name
      end

  fun removeDir dirname =
      let
        fun loop dir =
            case OS.FileSys.readDir dir of
              NONE => ()
            | SOME filename =>
              (if filename <> OS.Path.currentArc andalso
                  filename <> OS.Path.parentArc
               then OS.FileSys.remove (dirname // filename)
               else ();
               loop dir)
      in
        (OS.FileSys.openDir dirname) try loop ensure OS.FileSys.closeDir;
        OS.FileSys.rmDir dirname
      end

  fun rm_f filename =
      OS.FileSys.remove filename handle _ => ()

  fun openAppend filename f =
      (TextIO.openAppend filename) try f ensure TextIO.closeOut

  fun openOut filename f =
      (TextIO.openOut filename) try f ensure TextIO.closeOut

  fun readFile filename =
      (TextIO.openIn filename) try TextIO.inputAll ensure TextIO.closeIn

  fun isReadable filename =
      ((BinIO.openIn filename) try (fn _ => true) ensure BinIO.closeIn)
      handle _ => false

  fun unchomp s =
      if String.isSuffix "\n" s then s else s ^ "\n"

  fun chomp s =
      if String.isSuffix "\n" s orelse String.isSuffix "\r" s
      then String.substring (s, 0, size s - 1)
      else if String.isSuffix "\r\n" s
      then String.substring (s, 0, size s - 2)
      else s

  fun scanInt s =
      valOf $ StringCvt.scanString (Int.scan StringCvt.DEC) s
  fun scanWord s =
      valOf $ StringCvt.scanString (Word.scan StringCvt.DEC) s
  fun scanLargeInt s =
      valOf $ StringCvt.scanString (LargeInt.scan StringCvt.DEC) s
  fun scanLargeWord s =
      valOf $ StringCvt.scanString (LargeWord.scan StringCvt.DEC) s
  fun scanReal s =
      valOf $ StringCvt.scanString Real.scan s
  val fmtInt =
      Int.toString

  (***************************************************************************)

  (*** configurations ***)

  val conftest_name = "conftest"
  val config_log = "cconfig.log"

  val verboseOpt = ref false
  val noticeOpt = ref true
  val loggingOpt = ref true

  fun verbose b = verboseOpt := b
  fun message b = noticeOpt := b
  fun logging b = loggingOpt := b

  (* FIXME: should be system dependent. *)
  val defaultConfig =
      [("CC", "cc"),
       ("CPP", "cpp"),
       ("OUTFLAG", "-o "),
       ("CFLAGS", "-g"),
       ("LDD", "ldd"),
       ("LIBARG", "-l$(lib)"),
       ("LIBNAME_PREFIX", "lib"),
       ("LIBNAME_SUFFIX", ".so"),
       ("ARCSEP", OS.Path.fromUnixPath "/"),
       ("EXEEXT", ""),
       ("TRY_LINK",
        "$(CC) $(OUTFLAG)$(out) $(INCFLAGS) $(CPPFLAGS) \
        \$(CFLAGS) $(ccopt) $(src) $(LIBPATH) $(LDFLAGS) $(ldopt) \
        \$(LOCAL_LIBS) $(LIBS)"),
       ("TRY_COMPILE",
        "$(CC) -c $(INCFLAGS) $(CPPFLAGS) $(CFLAGS) $(ccopt) $(src)"),
       ("TRY_LDD",
        "$(LDD) $(out)")]

  val configEnv = ref nil : (string * string) list ref

  fun setConfig key value =
      let val l = List.filter (fn (k,_) => key <> k) (!configEnv)
      in configEnv := (case value of SOME v => (key,v) :: l | NONE => l)
      end

  fun findConfig l (key : string) =
      List.find (fn (k,_) => key = k) l
      ifSome (fn (_, v) => v)

  exception Config

  fun getConfig key =
      findConfig (!configEnv) key
      ifNone (fn _ => OS.Process.getEnv key
      ifNone (fn _ => findConfig defaultConfig key
      ifNone (fn _ => raise Config)))

  fun getConfig' overwrites key =
      findConfig overwrites key
      ifNone (fn _ => getConfig key)

  fun config key =
      {set = setConfig key,
       get = fn () => SOME (getConfig key) handle Config => NONE}

  fun addConfig key value =
      setConfig key (SOME (getConfig key ^ " " ^ value)
                     handle Config => SOME value)

  (* replace $HOGE with its config value *)
  local
    open Substring
    fun isKeyChar c = Char.isAlpha c orelse c = #"_"

    fun expand' config "" = ""
      | expand' config str =
        let
          fun getConfig1 (key, r) =
              (config (string key) handle Config => "", triml 1 r)
          val (l, r) = splitl (fn c => c <> #"$") (full str)
          val r = triml 1 r
          val (c, r) =
              if isPrefix "$" r
              then ("$", triml 1 r)
              else if isPrefix "(" r
              then getConfig1 $ splitl (fn c => c <> #")") (triml 1 r)
              else if isPrefix "{" r
              then getConfig1 $ splitl (fn c => c <> #"}") (triml 1 r)
              else getConfig1 $ splitl isKeyChar r
        in
          string l ^ expand' config (c ^ string r)
        end
  in

  fun expand str =
      expand' getConfig str

  fun getconf overwrites key =
      expand' (getConfig' overwrites) (getConfig' overwrites key)

  end

  fun libArg name =
      if String.isPrefix "-" name then name
      else if name = "" then name
      else getconf [("lib", name)] "LIBARG"

  fun lddCmd name =
      getconf [("out", name)] "TRY_LDD"

  fun conftest_c base = base // conftest_name ^ ".c"
  fun conftest_out base = base // conftest_name ^ ".out"
  fun conftest_exe base = base // conftest_name ^ (getConfig "EXEEXT")

  (***************************************************************************)

  (*** logging ***)

  fun log f =
      (if !loggingOpt then openAppend config_log f else ();
       if !verboseOpt then f TextIO.stdErr else ())
      handle _ => ()

  fun notice msg =
      (log (fn out => TextIO.output (out, "notice: " ^ unchomp msg));
       if !noticeOpt andalso not (!verboseOpt)
       then TextIO.output (TextIO.stdErr, msg)
       else ())
      handle _ => ()

  fun checkingFor msg f =
      let val _ = notice ("checking for "^msg^"... ")
          val b = f ()
          val _ = notice (if b then "yes\n" else "no\n")
      in b
      end

  fun checkingForVal' fmt msg f =
      let val _ = notice ("checking for "^msg^"... ")
          val v = f ()
          val _ = notice (case v of SOME s => unchomp (fmt s)
                                  | NONE => "failed\n")
      in v
      end

  fun checkingForVal msg f = checkingForVal' (fn x => x) msg f

  fun logSrc src =
      log (fn out =>
              (TextIO.output (out, "checked program was:\n\
                                   \/* begin */\n");
               TextIO.output (out, src);
               TextIO.output (out, "/* end */\n\n")))

  (***************************************************************************)

  (*** tasks ***)

  fun tryInTmp f =
      (mkdtemp ()) try f ensure removeDir

  fun tryInDir dir f =
      (OS.FileSys.getDir ())
      try (fn oldpwd => (OS.FileSys.chDir dir; f oldpwd))
      ensure OS.FileSys.chDir

  fun cppHeaders headers =
      concat $ map (fn s => "#include <"^s^">\n") headers

  fun createCSource base src =
      let
        val conftest_c = conftest_c base
        val src = unchomp src
      in
        rm_f conftest_c;
        openOut (base // conftest_name ^ ".c")
                (fn out => TextIO.output (out, src));
        src
      end

  fun tryCommand base command =
      let
        (* B shell required *)
        val conftest_out = conftest_out base
        val _ = rm_f conftest_out
        val command = command^" > "^conftest_out^" 2>&1"
        val _ =
            log (fn out => TextIO.output (out, "command: "^command^"\n"))
        val status = OS.Process.system command
        val output = readFile conftest_out handle _ => ""
      in
        log (fn out =>
                (TextIO.output (out, unchomp output);
                 TextIO.output (out, "exit status at "^fmtInt status^"\n\n")));
        (status, output)
      end

  fun tryLink base src ldopt =
      let
        val src = createCSource base src
        val conftest_exe = conftest_exe base
        val _ = rm_f conftest_exe
        val config = [("ldopt", ldopt),
                      ("src", conftest_c base),
                      ("out", conftest_exe)]
        val command = getconf config "TRY_LINK"
        val (status, _) = tryCommand base command
        val _ = logSrc src
      in
        status = OS.Process.success
      end

  fun tryRun base src ldopt =
      if tryLink base src ldopt
      then SOME $ tryInDir base (fn _ => tryCommand base (conftest_exe base))
      else NONE

  fun tryFunc base funcname headers ldopt =
      let
        val headers = cppHeaders headers
        val src1 =
            "int t() { "^funcname^"(); return 0; }\n\
            \int main() { return 0; }\n"
        val src2 =
            "void *t() {\n\
            \  void ((*volatile p)()); p = (void(*)())"^funcname^";\n\
            \  return p;\n\
            \}\n\
            \int main() { return 0; }\n"
        val result = tryLink base (headers ^ src1) ldopt
                     orelse tryLink base (headers ^ src2) ldopt
      in
        if result then addConfig "LIBS" ldopt else ();
        result
      end

  (* scan path-like substrings *)
  fun searchFilenames str =
      map Substring.string
      $ List.filter (Substring.isSubstring (getConfig "ARCSEP"))
      $ Substring.tokens Char.isSpace
      $ Substring.full str

  (* match s with <PREFIX>[-.0-9]*<SUFFIX> *)
  fun libnameMatch prefix suffix x =
      let val ss = Substring.full x
      in Substring.isPrefix prefix ss andalso
         (let val ss = Substring.triml (size prefix) ss
          in Substring.isSuffix suffix ss andalso
             (let val ss = Substring.trimr (size suffix) ss
              in Substring.isEmpty
                     (Substring.dropl (fn #"-" => true
                                        | #"." => true
                                        | x => Char.isDigit x) ss)
              end)
          end)
      end

  fun downcase x = String.translate (str o Char.toLower) x

  (*
   * look for path-like strings from given output
   * and pick up appriciate one from them.
   *)
  fun searchLibFile name (status, output) =
      if status = OS.Process.success then
        let
          val prefix = getConfig "LIBNAME_PREFIX"
          val suffix = getConfig "LIBNAME_SUFFIX"
          fun equalMatch (x:string) (k,_) = k = x
          fun exactMatch (x:string) (_,k) = k = x
          fun exactLibMatch x (_,k) = libnameMatch (prefix ^ x) suffix k
          fun partLibMatch x (_,k) =
              let val (_,ks) = Substring.position x (Substring.full k)
              in libnameMatch x suffix (Substring.string ks)
              end
          val name' = downcase name
          val filenames = List.filter isReadable (searchFilenames output)
          val l = map (fn x => (x, OS.Path.file (downcase x))) filenames
        in
          case List.filter (equalMatch name) l of
            [(x,_)] => SOME x
          | _ =>
            case List.filter (exactLibMatch name') l of
              [(x,_)] => SOME x
            | _ =>
              case List.filter (partLibMatch name') l of
                [(x,_)] => SOME x
              | _ =>
                case List.filter (exactMatch name') l of
                  [(x,_)] => SOME x
                | _ =>
                  let
                    val name = Substring.string
                               $ Substring.taker
                                     (fn c => Char.isAlphaNum c
                                              orelse Char.isPunct c)
                               $ Substring.full name
                    val name' = downcase name
                  in
                    case List.filter (equalMatch name) l of
                      [(x,_)] => SOME x
                    | _ =>
                      case List.filter (exactLibMatch name') l of
                        [(x,_)] => SOME x
                      | _ =>
                        case List.filter (exactMatch name') l of
                          [(x,_)] => SOME x
                        | _ =>
                          case filenames of h::t => SOME h | nil => NONE
                  end
        end
      else NONE

  fun findLibrary (libname, funcname, headers) =
      (* FIXME: no need to consider cross compiling? *)
      tryInTmp
      (fn base =>
          let val libarg = libArg libname
          in checkingForVal (funcname^"() in "^libarg)
             (fn () =>
                 if tryFunc base funcname headers libarg
                 then
                   let val conftest_exe = conftest_exe base
                       val ret = tryCommand base (lddCmd conftest_exe)
                   in searchLibFile libname ret
                   end
                 else NONE)
          end)

  fun haveLibrary (libname, funcname, headers) =
      tryInTmp
      (fn base =>
          let val libarg = libArg libname
          in checkingFor (funcname^"() in "^libarg)
             (fn () => tryFunc base funcname headers (libArg libname))
          end)

  (***************************************************************************)

  val intFormat = ("%d", "int")
  val uintFormat = ("%u", "unsigned int")
  val longFormat = ("%ld", "long")
  val ulongFormat = ("%lu", "unsigned long")
  val doubleFormat = ("%.2000f", "double")
  val floatFormat = ("%.2000f", "float")
  val stringFormat = ("%s", "char*")

  fun tryConst base (format, cast) const headers =
      let
        (* FIXME: no need to consider cross compiling? *)
        val headers = cppHeaders ("stdio.h"::headers)
        val src =
             headers^"\
            \int main() {\n\
            \  printf(\""^format^"\\n\", ("^cast^")("^const^"));\n\
            \  return 0;\n\
            \}\n"
      in
        tryRun base src ""
        ifSome (fn (_, output) => output)
      end

  fun checkSizeOf (ctype, headers) =
      tryInTmp
      (fn base =>
          let val result =
                  checkingForVal ("size of "^ctype)
                  (fn () => tryConst base intFormat
                                     ("sizeof("^ctype^")") headers)
          in scanInt (valOf result)
          end)

  fun haveConst format name headers =
      tryInTmp
      (fn base => checkingForVal name
                  (fn () => tryConst base format name headers))

  fun haveConstInt (name, headers) =
      (haveConst intFormat name headers) ifSome scanInt

  fun haveConstUInt (name, headers) =
      (haveConst uintFormat name headers) ifSome scanWord

  fun haveConstLong (name, headers) =
      (haveConst longFormat name headers) ifSome scanLargeInt

  fun haveConstULong (name, headers) =
      (haveConst longFormat name headers) ifSome scanLargeWord

  fun haveConstFloat (name, headers) =
      (haveConst floatFormat name headers) ifSome scanReal

  fun haveConstDouble (name, headers) =
      (haveConst doubleFormat name headers) ifSome scanReal

  fun haveConstString (name, headers) =
      (haveConst stringFormat name headers) ifSome chomp

  (***************************************************************************)

  local
    open Substring
  in
  fun checkStructMember (ctype, field, headers) =
      let
        (* FIXME: no need to consider cross compiling? *)
        val headers = cppHeaders ("stdio.h"::headers)
        val src =
             headers^"\
            \int main() {\n\
            \  "^ctype^" t;\n\
            \  printf(\"%d %d\\n\", sizeof(t."^field^"),\
            \ (int)(((char*)&t."^field^") - (char*)&t));\n\
            \  return 0;\n\
            \}\n"
      in
        tryInTmp
        (fn base =>
            checkingForVal'
                (fn (l,r) => "size="^fmtInt l^", offset="^fmtInt r)
                (field^" in "^ctype)
            (fn () =>
                tryRun base src ""
                ifSome (fn (_, output) =>
                           let val (_, r) = splitl Char.isDigit (full output)
                           in (scanInt output, scanInt $ string r)
                           end)))
      end
  end

  (***************************************************************************)

  val isBigEndian = ref NONE : bool option ref
  val charBit = ref NONE : bool option ref

  fun cacheResult r f =
      case !r of
        SOME x => x
      | NONE =>
        let val result = f ()
        in result before r := SOME result
        end

  fun checkIsBigEndian () =
      cacheResult isBigEndian
      (fn () =>
        let
          (* FIXME: already done at compilation of runtime *)
          val headers = cppHeaders ["stdio.h"]
          val src =
               headers^"\
              \union t { unsigned int t1; unsigned char t2[sizeof(int)]; };\n\
              \int main() {\n\
              \  volatile union t t;\n\
              \  t.t1 = 0x12345678;\n\
              \  return t.t2[0] != 0x12;\n\
              \}\n"
        in
          tryInTmp
          (fn base =>
              checkingFor "bigendian"
              (fn () => case tryRun base src "" of
                          SOME (status, _) => status = 0
                        | NONE => false))
        end)

  fun checkCharBitIs8 () =
      cacheResult charBit
      (fn () => haveConstInt ("CHAR_BIT", ["limits.h"]) = SOME 8)

  (***************************************************************************)

  local
    val sub = Word8Array.sub
    val update = Word8Array.update

    infix << >> && ||
    val op << = Word32.<<
    val op >> = Word32.>>
    val op && = Word32.andb
    val op || = Word32.orb
    fun toWord8 w = Word8.fromInt (Word32.toInt w)
    fun fromWord8 w = Word32.fromInt (Word8.toInt w)

    fun read (inc, ary, i, 0, w) = w
      | read (inc, ary, i, n, w) =
        read (inc, ary, i + inc, n - 1, (w << 0w8) || fromWord8 (sub (ary, i)))

    fun write (inc, ary, i, 0, w) = ()
      | write (inc, ary, i, n, w) =
        (update (ary, i, toWord8 (w && 0wxff));
         write (inc, ary, i + inc, n - 1, w >> 0w8))

    fun readLE  (ary, i, n) = read  (~1, ary, i + n - 1, n, 0w0)
    fun readBE  (ary, i, n) = read  ( 1, ary, i, n, 0w0)
    fun writeLE (ary, i, n, w) = write ( 1, ary, i, n, w)
    fun writeBE (ary, i, n, w) = write (~1, ary, i + n - 1, n, w)

    fun accessor' bigendian (offset, size) =
        {
          get = if bigendian
                then fn ary => readBE (ary, offset, size)
                else fn ary => readLE (ary, offset, size),
          set = if bigendian
                then fn (ary, w) => writeBE (ary, offset, size, w)
                else fn (ary, w) => writeLE (ary, offset, size, w)
        }
  in
  fun accessor x =
      let
        val bigendian = checkIsBigEndian ()
        val _ = if checkCharBitIs8 () then () else raise Fail "CHAR_BIT"
      in
        accessor' bigendian x
      end
  end

  (***************************************************************************)

end
