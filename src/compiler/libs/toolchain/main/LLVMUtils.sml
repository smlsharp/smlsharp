(**
 * llvm toolchain
 * @copyright (c) 2013, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure LLVMUtils : sig

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
      {systemBaseDir : Filename.filename,
       triple : string,
       arch : string,
       cpu : string,
       features : string,
       optLevel : opt_level,
       relocModel : reloc_model,
       LLCFLAGS : string list,
       OPTFLAGS : string list}

  val compile : compile_options
                -> LLVM.LLVMModuleRef * file_type * Filename.filename
                -> unit

end =
struct

  fun toAbsolute filename =
      if Filename.isAbsolute filename
      then filename
      else Filename.concatPath (Filename.pwd (), filename)

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
              CoreUtils.system
                {command =
                   CoreUtils.join
                     (command
                      :: map CoreUtils.quote flags
                      @ ["-o", CoreUtils.quote (Filename.toString dstfile),
                         CoreUtils.quote (Filename.toString srcfile)]),
                 quiet = false})
      end

  fun llc {systemBaseDir, source, flags, dstfile} =
      let
        val systemBaseDir = toAbsolute systemBaseDir
        val pluginDir = Filename.concatPath
                          (systemBaseDir, Filename.fromString "llvm")
        val plugin = Filename.concatPath
                       (pluginDir, 
                        Filename.fromString
                          ("smlsharp_gc." ^ SMLSharp_Config.DLLEXT ()))
      in
        llvmCommand {command = SMLSharp_Config.LLC (),
                     source = source,
                     flags = ("-load=" ^ Filename.toString plugin) :: flags,
                     dstfile = dstfile}
      end

  fun llvm_dis {source, dstfile} =
      llvmCommand {command = SMLSharp_Config.LLVM_DIS (),
                   source = source,
                   flags = [],
                   dstfile = dstfile}

  fun opt {source, flags, dstfile} =
      llvmCommand {command = SMLSharp_Config.OPT (),
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
      {systemBaseDir : Filename.filename,
       triple : string,
       arch : string,
       cpu : string,
       features : string,
       optLevel : opt_level,
       relocModel : reloc_model,
       LLCFLAGS : string list,
       OPTFLAGS : string list}

  fun optOption O0 = ["-O0"]
    | optOption O1 = ["-O1"]
    | optOption O2 = ["-O2"]
    | optOption O3 = ["-O3"]
    | optOption Os = ["-Os"]
    | optOption Oz = ["-Oz"]

  fun relocOption RelocDefault = []
    | relocOption RelocStatic = ["-relocation-model=static"]
    | relocOption RelocPIC = ["-relocation-model=pic"]
    | relocOption RelocDynamicNoPIC = ["-relocation-model=dynamic-no-pic"]

  fun compile {systemBaseDir, triple, arch, cpu, features, optLevel,
               relocModel, LLCFLAGS, OPTFLAGS}
              (module, fileType, outputFilename) =
      let
        val flags =
            ["-mtriple=" ^ triple]
            @ (case arch of "" => [] | _ => ["-march=" ^ arch])
            @ (case cpu of "" => [] | _ => ["-mcpu=" ^ cpu])
            @ (case features of "" => [] | _ => ["-mattr=" ^ features])
            @ optOption optLevel
            @ ["-tailcallopt"]
            @ relocOption relocModel
        val bcFile = TempFile.create ".bc"
        val _ = LLVM.LLVMWriteBitcodeToFile (module, Filename.toString bcFile)
        val optFile =
            case optLevel of
              O0 => bcFile
            | _ =>
              let
                val optFile = TempFile.create ".bc"
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
                llc {systemBaseDir = systemBaseDir,
                     flags = flags @ LLCFLAGS,
                     source = optFile,
                     dstfile = dstFile};
                dstFile
              end
            | ObjectFile =>
              let
                val dstFile = TempFile.create ".o"
              in
                llc {systemBaseDir = systemBaseDir,
                     flags = "-filetype=obj" :: flags @ LLCFLAGS,
                     source = optFile,
                     dstfile = dstFile};
                dstFile
              end
            | IRFile =>
              let
                val dstFile = TempFile.create ".ll"
              in
                llvm_dis {source = optFile, dstfile = dstFile};
                dstFile
              end
            | BitcodeFile =>
              optFile
      in
        CoreUtils.cp dstFile outputFilename
      end

end
