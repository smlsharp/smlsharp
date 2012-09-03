(**
 * compiler toolchain support - binutils
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure BinUtils : sig

  val assemble : {source: Filename.filename, flags: string list,
                  object: Filename.filename} -> unit
  val link : {flags: string list, objects: Filename.filename list,
              libs: string list, dst: Filename.filename} -> unit
  val partialLink : {objects: Filename.filename list, dst: Filename.filename}
                    -> unit
  val archive : {objects: Filename.filename list, archive: Filename.filename}
                -> unit

  val OBJEXT : string   (* ToDo: move to SMLSharpConfiguration *)
  val LIBEXT : string
  val ASMEXT : string

end =
struct

  val maxCommandLineSize = 1024
  val OBJEXT = "o"
  val LIBEXT = "a"
  val ASMEXT = "s"

  fun join [x] = x
    | join (""::t) = join t
    | join (h::t) = h ^ " " ^ join t
    | join nil = ""

  fun quote "" = "\"\""
    | quote x = x (* FIXME *)

  fun take maxSize strs =
      let
        fun prepend (x, (l1, l2)) = (x::l1, l2)
        fun loop (nil, cols) = (nil, nil)
          | loop (h::t, cols) =
            if cols + 1 + size h > maxSize
            then (nil, h::t) else prepend (h, loop (t, cols + 1 + size h))
      in
        loop (strs, 0)
      end

  fun takeAtLeast1 maxSize strs =
      case take maxSize strs of (nil, h::t) => ([h], t) | x => x

  fun invokeLinker (pre, files, post) =
      let
        val maxSize = maxCommandLineSize - (size pre + size post + 2)

        fun loop (nil, linked) = loop (linked, nil)
          | loop (files, linked) =
            case take maxSize (linked @ files) of
              (args, nil) => CoreUtils.system (join (pre :: args @ [post]))
            | _ =>
              case files of
                [file] => loop (nil, linked @ [file])
              | _ =>
                let
                  val objfile = TempFile.create ("."^OBJEXT)
                  val objfile = quote (Filename.toString objfile)
                  val pre = SMLSharpConfiguration.LD ^ " -r "
                  val post = " -o " ^ objfile
                  val maxSize = maxCommandLineSize - (size pre + size post)
                  val (args, rest) = takeAtLeast1 maxSize files
                in
                  CoreUtils.system (pre ^ join args ^ post);
                  loop (rest, linked @ [objfile])
                end
      in
        loop (files, nil)
      end

  fun link {flags, objects, libs, dst} =
      let
        val objects = map (quote o Filename.toString) objects
        val pre = join (SMLSharpConfiguration.CC ::
                        SMLSharpConfiguration.LDFLAGS ::
                        map quote flags)
        val post = join (SMLSharpConfiguration.LIBS ::
                         map quote libs
                         @ ["-o", quote (Filename.toString dst)])
      in
        invokeLinker (pre, objects, post)
      end

  fun partialLink {objects, dst} =
      let
        val objects = map (quote o Filename.toString) objects
        val pre = SMLSharpConfiguration.LD ^ " -r "
        val post = " -o " ^ quote (Filename.toString dst)
      in
        invokeLinker (pre, objects, post)
      end

  fun assemble {source, flags, object} =
      CoreUtils.system (join ([SMLSharpConfiguration.CC] @
                              map quote flags @
                              ["-c", quote (Filename.toString source),
                               "-o", quote (Filename.toString object)]))

  fun archive {objects, archive} =
      let
        val _ = CoreUtils.rm_f archive
        val archive = quote (Filename.toString archive)
        val objects = map (quote o Filename.toString) objects
        val pre = join [SMLSharpConfiguration.AR, "qc", archive] ^ " "
        val maxSize = maxCommandLineSize - size pre

        fun loop nil = ()
          | loop args =
            let
              val (args, rest) = takeAtLeast1 maxSize args
            in
              CoreUtils.system (pre ^ join args);
              loop rest
            end
      in
        loop objects;
        CoreUtils.system (SMLSharpConfiguration.RANLIB ^ " " ^ archive)
      end

end
