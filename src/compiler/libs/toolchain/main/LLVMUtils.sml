(**
 * llvm toolchain
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure LLVMUtils =
struct

  datatype arg = datatype ShellUtils.arg

  val ASMEXT = "ll"
  val OBJEXT = "bc"

  fun toAbsolute filename =
      if Filename.isAbsolute filename
      then filename
      else Filename.concatPath (Filename.pwd (), filename)

  fun searchLine match file =
      let
        fun search input =
            case TextIO.inputLine input of
              NONE => NONE
            | SOME line =>
              case match (String.tokens Char.isSpace line) of
                SOME x => SOME x
              | _ => search input
        val input = Filename.TextIO.openIn file
        val result = search input handle e => (TextIO.closeIn input; raise e)
      in
        TextIO.closeIn input;
        result
      end

  local
    val version = ref NONE
    val defaultTarget = ref ""
    fun get () =
        let
          val command = [EXPAND (Config.LLC ()), ARG "-version"]
          val output = ShellUtils.system command
          val v = searchLine
                    (fn ["LLVM", "version", ""] => NONE
                      | ["LLVM", "version", version] => SOME version
                      | _ => NONE)
                    (#stdout output)
          val t = searchLine
                    (fn ["Default", "target:", ""] => NONE
                      | ["Default", "target:", target] => SOME target
                      | _ => NONE)
                    (#stdout output)
       in
         case (v, t) of
           (SOME ver, SOME target) =>
           (version := v;
            defaultTarget := target;
            {version = ver, target = target})
         | _ =>
           raise ShellUtils.Fail
                   {command = "getVersion " ^ ShellUtils.join command,
                    status = OS.Process.failure,
                    output = output}
       end
  in
  fun getVersion () =
      case !version of
        SOME x => x
      | NONE => #version (get ())
  fun getDefaultTarget () =
      case !defaultTarget of
        "" => #target (get ())
      | s => s
  end

  fun getSeries () =
      let
        val version = Substring.full (getVersion ())
        val ss = Substring.dropr Char.isDigit version
        val ss = Substring.dropr (fn c => c = #".") ss
      in
        Substring.string ss
      end

  fun llvmCommand {command, source, flags, dstfile} =
      let
        (* LLVM commands use an input file name (including /) as a module ID,
         * which is significant in code generation.  To make the input name
         * identical to the expected module ID, this function changes the
         * primary working directory to the directory where the input file
         * is in. *)
        val dstfile = toAbsolute dstfile
        val srcfile = Filename.basename source
        val srcdir = Filename.dirname source
      in
        CoreUtils.chdir
          srcdir
          (fn () =>
              ShellUtils.system
                (EXPAND command
                 :: flags
                 @ [ARG "-o", ARG (Filename.toString dstfile),
                    ARG (Filename.toString srcfile)]))
      end

  fun llc {systemBaseExecDir, source, flags, dstfile} =
      let
        val systemBaseExecDir = toAbsolute systemBaseExecDir
        val pluginSuffix = getSeries () ^ "." ^ Config.DLLEXT ()
        val pluginDir = Filename.concatPath
                          (systemBaseExecDir, Filename.fromString "llvm")
        val plugin = Filename.concatPath
                       (pluginDir,
                        Filename.fromString ("smlsharp_gc-" ^ pluginSuffix))
      in
        llvmCommand
          {command = Config.LLC (),
           source = source,
           flags = (ARG ("-load=" ^ Filename.toString plugin)) :: flags,
           dstfile = dstfile}
      end

  fun llvm_as {source, dstfile} =
      llvmCommand {command = Config.LLVM_AS (),
                   source = source,
                   flags = [],
                   dstfile = dstfile}

  fun llvm_dis {source, dstfile} =
      llvmCommand {command = Config.LLVM_DIS (),
                   source = source,
                   flags = [],
                   dstfile = dstfile}

  fun opt {source, flags, dstfile} =
      llvmCommand {command = Config.OPT (),
                   source = source,
                   flags = flags,
                   dstfile = dstfile}

  datatype opt_level =
      O0
    | O1
    | O2
    | O3
    | Os
    | Oz

  datatype reloc_model =
      RelocDefault
    | RelocStatic
    | RelocPIC
    | RelocDynamicNoPIC

  datatype file_type =
      AssemblyFile
    | ObjectFile
    | IRFile
    | BitcodeFile

  type compile_options =
      {systemBaseExecDir : Filename.filename,
       triple : string,
       arch : string,
       cpu : string,
       features : string,
       optLevel : opt_level,
       relocModel : reloc_model,
       LLCFLAGS : ShellUtils.arg list,
       OPTFLAGS : ShellUtils.arg list}

  fun optOption O0 = [ARG "-O0"]
    | optOption O1 = [ARG "-O1"]
    | optOption O2 = [ARG "-O2"]
    | optOption O3 = [ARG "-O3"]
    | optOption Os = [ARG "-Os"]
    | optOption Oz = [ARG "-Oz"]

  fun relocOption RelocDefault = []
    | relocOption RelocStatic = [ARG "-relocation-model=static"]
    | relocOption RelocPIC = [ARG "-relocation-model=pic"]
    | relocOption RelocDynamicNoPIC = [ARG "-relocation-model=dynamic-no-pic"]

  fun commandFlags ({triple, arch, cpu, features, optLevel, relocModel,
                     ...} : compile_options) =
      [ARG ("-mtriple=" ^ triple)]
      @ (case arch of "" => [] | _ => [ARG ("-march=" ^ arch)])
      @ (case cpu of "" => [] | _ => [ARG ("-mcpu=" ^ cpu)])
      @ (case features of "" => [] | _ => [ARG ("-mattr=" ^ features)])
      @ optOption optLevel
      @ relocOption relocModel
      @ [ARG "-tailcallopt"]
      @ (if List.exists
              (fn x => String.isPrefix x triple)
              ["x86_64", "amd64", "i386", "i486", "i586", "i686"]
         then [ARG "-no-x86-call-frame-opt"]
         else nil)

  fun compile (options as {systemBaseExecDir, triple, arch, cpu, features,
                           optLevel, relocModel, LLCFLAGS, OPTFLAGS})
              {srcfile = bcFile, dstfile = (fileType, outputFilename)} =
      let
        val flags = commandFlags options
        val optFile =
            case optLevel of
              O0 => bcFile
            | _ =>
              let
                val optFile = TempFile.create ("." ^ OBJEXT)
              in
                opt {flags = flags @ OPTFLAGS,
                     source = bcFile,
                     dstfile = optFile};
                optFile
              end
        val dstFile =
            case fileType of
              AssemblyFile =>
              let
                val dstFile = TempFile.create ".s"
              in
                llc {systemBaseExecDir = systemBaseExecDir,
                     flags = flags @ LLCFLAGS,
                     source = optFile,
                     dstfile = dstFile};
                dstFile
              end
            | ObjectFile =>
              let
                val dstFile = TempFile.create ".o"
              in
                llc {systemBaseExecDir = systemBaseExecDir,
                     flags = ARG "-filetype=obj" :: flags @ LLCFLAGS,
                     source = optFile,
                     dstfile = dstFile};
                dstFile
              end
            | IRFile =>
              let
                val dstFile = TempFile.create ("." ^ ASMEXT)
              in
                llvm_dis {source = optFile, dstfile = dstFile};
                dstFile
              end
            | BitcodeFile =>
              optFile
      in
        CoreUtils.cp dstFile outputFilename
      end

  fun assemble llfile =
      let
        val bcfile = TempFile.create ("." ^ OBJEXT)
      in
        llvm_as {source = llfile, dstfile = bcfile};
        bcfile
      end

  datatype ty =
      Int
    | Float
    | Vector
    | Aggregate
    | Pointer of int

  type alignment = {ty : ty, size : int, abi : int, prefer : int}

  type data_layout =
      {string : string,
       bigEndian : bool,
       stackAlignment : int,
       allocaAddrSpace : int,
       nativeIntWidths : int list,
       nonIntegralAddrSpaces : int list,
       alignment : alignment list}

  val defaultDataLayout =
      {string = "",
       bigEndian = false,
       stackAlignment = 0,
       allocaAddrSpace = 0,
       nativeIntWidths = nil,
       nonIntegralAddrSpaces = nil,
       alignment = [
         {ty = Int, size = 1, abi = 1, prefer = 1},
         {ty = Int, size = 8, abi = 1, prefer = 1},
         {ty = Int, size = 16, abi = 2, prefer = 2},
         {ty = Int, size = 32, abi = 4, prefer = 4},
         {ty = Int, size = 64, abi = 4, prefer = 8},
         {ty = Float, size = 16, abi = 2, prefer = 2},
         {ty = Float, size = 32, abi = 4, prefer = 4},
         {ty = Float, size = 64, abi = 8, prefer = 8},
         {ty = Float, size = 128, abi = 16, prefer = 16},
         {ty = Vector, size = 64, abi = 16, prefer = 16},
         {ty = Vector, size = 128, abi = 16, prefer = 16},
         {ty = Aggregate, size = 0, abi = 0, prefer = 8},
         {ty = Pointer 0, size = 64, abi = 8, prefer = 8}
       ]} : data_layout

  exception Parse

  fun scanInt ss =
      case Int.scan StringCvt.DEC Substring.getc ss of
        NONE => raise Parse
      | SOME (x, _) => x

  fun scanByte ss =
      let
        val n = scanInt ss
      in
        if Int.rem (n, 8) = 0 then Int.quot (n, 8) else raise Parse
      end

  fun parseDataLayoutField (nil, z) = raise Parse
    | parseDataLayoutField (key :: args, z) =
      case (Substring.getc (Substring.full key), map Substring.full args) of
        (SOME (#"e", _), nil) => z # {bigEndian = false}
      | (SOME (#"E", _), nil) => z # {bigEndian = true}
      | (SOME (#"S", s), nil) => z # {stackAlignment = scanInt s}
      | (SOME (#"A", s), nil) => z # {allocaAddrSpace = scanInt s}
      | (SOME (#"n", s), args) =>
        (case Substring.getc s of
           SOME (#"i", _) => z # {nonIntegralAddrSpaces = map scanInt args}
         | _ => z # {nativeIntWidths = scanInt s :: map scanInt args})
      | (SOME (#"p", s), size :: abi :: args) =>
        let
          val space = scanInt s handle Parse => 0
          val (prefer, args) = case args of h::t => (h, t) | nil => (abi, nil)
        in
          z # {alignment = {ty = Pointer space,
                            size = scanInt size,
                            abi = scanInt abi,
                            prefer = scanInt prefer}
                           :: #alignment z}
        end
      | (SOME (c, s), abi :: args) =>
        let
          val (ty, size) = case c of
                             #"i" => (Int, scanInt s)
                           | #"f" => (Float, scanInt s)
                           | #"v" => (Vector, scanInt s)
                           | #"a" => (Aggregate, 0)
                           | _ => raise Parse
          val (prefer, args) = case args of h::t => (h, t) | nil => (abi, nil)
        in
          z # {alignment = {ty = ty,
                            size = size,
                            abi = scanInt abi,
                            prefer = scanInt prefer}
                           :: #alignment z}
        end
      | _ => raise Parse

  fun unique f nil = nil
    | unique f (h :: t) = h :: unique f (List.filter (fn x => f x <> f h) t)

  fun parseDataLayout layout =
      let
        val fields = String.fields (fn c => c = #"-") layout
        val descs = map (String.fields (fn c => c = #":")) fields
        val spec =
            foldl (fn (x, z) => parseDataLayoutField (x, z) handle _ => z)
                  defaultDataLayout
                  descs
      in
        spec # {string = layout, alignment = unique #ty (#alignment spec)}
      end

  fun getDataLayout options =
      let
        val llfile = TempFile.create ("." ^ ASMEXT)
        val command =
            (EXPAND (Config.LLC ())
             :: ARG "-o" :: ARG "-" :: ARG "-print-before-all"
             :: commandFlags options @ [ARG (Filename.toString llfile)])
        val output = ShellUtils.system command
        val layout =
            searchLine
              (fn ["target", "datalayout", "=", s] =>
                  if size s >= 2
                     andalso String.isPrefix "\"" s
                     andalso String.isSuffix "\"" s
                  then SOME (substring (s, 1, size s - 2))
                  else NONE
                | _ => NONE)
              (#stderr output)
      in
        case layout of
          SOME layout => parseDataLayout layout
        | NONE =>
          raise ShellUtils.Fail
                  {command = "getDataLayout " ^ ShellUtils.join command,
                   status = OS.Process.failure,
                   output = output}
      end

end
