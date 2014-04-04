(**
 * compiler toolchain support - binutils
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure BinUtils : sig

  val assemble : {source: Filename.filename, flags: string list,
                  object: Filename.filename} -> unit
  val link : {flags: string list, objects: Filename.filename list,
              libs: string list, dst: Filename.filename,
              useCXX: bool, quiet: bool} -> unit
  val partialLink : {objects: Filename.filename list, dst: Filename.filename}
                    -> unit
  val archive : {objects: Filename.filename list, archive: Filename.filename}
                -> unit

end =
struct

  val join = CoreUtils.join
  val quote = CoreUtils.quote

  fun take maxSize strs =
      let
        fun prepend (x, (l1, l2)) = (x::l1, l2)
        fun loop (nil, cols) = (nil, nil)
          | loop (h::t, cols) =
            let
              val len = cols + 1 + size (quote h)
            in
              if len > maxSize then (nil, h::t) else prepend (h, loop (t, len))
            end
      in
        loop (strs, 0)
      end

  fun invokeLinker NONE {pre, objfiles, post, quiet} =
      CoreUtils.system
        {command = join ([pre]
                         @ map (quote o Filename.toString) objfiles
                         @ [post]),
         quiet = quiet}
    | invokeLinker (SOME maxCommandLineSize) {pre, objfiles, post, quiet} =
      let
        val maxSize = maxCommandLineSize - (size pre + size post + 2)
        fun loop (nil, linked) = loop (linked, nil)
          | loop (files, linked) =
            case take maxSize (linked @ files) of
              (args, nil) =>
              CoreUtils.system
                {command = join ([pre] @ map quote args @ [post]),
                 quiet = quiet}
            | (nil, args as [_]) =>
              CoreUtils.system 
                {command = join ([pre] @ map quote args @ [post]),
                 quiet = quiet}
            | _ =>
              let
                val objfile = TempFile.create ("."^SMLSharp_Config.OBJEXT())
                val objfile = Filename.toString objfile
                val pre = join [SMLSharp_Config.LD (), "-r"]
                val post = join ["-o", quote objfile]
                val maxSize = maxCommandLineSize - (size pre + size post + 2)
                val (linkobjs, rest) =
                    case take maxSize files of
                      (files as _::_::_, rest) => (files, rest)
                    | (file1::nil, file2::rest) => ([file1, file2], rest)
                    | (file1::nil, nil) => (nil, [file1])
                    | (nil, file1::file2::rest) => ([file1, file2], rest)
                    | (nil, file1::nil) => (nil, [file1])
                    | (nil, nil) => (nil, nil)
              in
                case linkobjs of
                  nil => loop (rest, linked)
                | _::_ =>
                  (CoreUtils.system
                     {command = join ([pre] @ linkobjs @ [post]),
                      quiet = quiet};
                   loop (rest, linked @ [objfile]))
              end
      in
        loop (map Filename.toString objfiles, nil)
      end

  fun link {flags, objects, libs, dst, useCXX, quiet} =
      invokeLinker
        (SMLSharp_Config.CMDLINE_MAXLEN ())
        {pre = join ((if useCXX
                      then SMLSharp_Config.CXX ()
                      else SMLSharp_Config.CC ())
                     :: SMLSharp_Config.LDFLAGS ()
                     :: map quote flags),
         objfiles = objects,
         post = join (map quote libs
                      @ [SMLSharp_Config.LIBS (),
                         "-o", quote (Filename.toString dst)]),
         quiet = quiet}
        
  fun partialLink {objects, dst} =
      invokeLinker
        (SMLSharp_Config.CMDLINE_MAXLEN ())
        {pre = join [SMLSharp_Config.LD (), "-r"],
         objfiles = objects,
         post = join ["-o", quote (Filename.toString dst)],
         quiet = false}

  fun assemble {source, flags, object} =
      CoreUtils.system
        {command = join (SMLSharp_Config.CC ()
                         :: map quote flags
                         @ ["-c", quote (Filename.toString source),
                            "-o", quote (Filename.toString object)]),
         quiet = false}

  fun invokeAr NONE {objects, archive} =
      (CoreUtils.system
         {command = join (SMLSharp_Config.AR ()
                          :: "qc"
                          :: quote (Filename.toString archive)
                          :: map (quote o Filename.toString) objects),
          quiet = false};
       CoreUtils.system
         {command = join [SMLSharp_Config.RANLIB (),
                          quote (Filename.toString archive)],
          quiet = false})
    | invokeAr (SOME maxCommandLineSize) {objects, archive} =
      let
        val _ = CoreUtils.rm_f archive
        val archive = Filename.toString archive
        val objects = map Filename.toString objects
        val pre = join [SMLSharp_Config.AR (), "qc", quote archive]
        val maxSize = maxCommandLineSize - size pre
        fun loop nil = ()
          | loop args =
            let
              val (args, rest) =
                  case take maxSize args of
                    (args as _::_, rest) => (args, rest)
                  | (nil, file::rest) => ([file], rest)
                  | (nil, nil) => (nil, nil)
            in
              CoreUtils.system {command = join (pre :: args), quiet = false};
              loop rest
            end
      in
        loop objects;
        CoreUtils.system
          {command = join [SMLSharp_Config.RANLIB (), quote archive],
           quiet = false}
      end

  fun archive args =
      invokeAr (SMLSharp_Config.CMDLINE_MAXLEN ()) args

end
