(**
 * compiler toolchain support - binutils
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure BinUtils =
struct

  datatype arg = datatype ShellUtils.arg

  fun nestLink pre linked nil post =
      nestLink pre nil linked post
    | nestLink pre linked files post =
      case ShellUtils.split {pre = pre, args = linked @ files, post = post} of
        (args, nil) => ShellUtils.system (pre @ args @ post)
      | (nil, args as _::nil) => ShellUtils.system (pre @ args @ post)
      | _ =>
        let
          val objfile = TempFile.create ("." ^ Config.OBJEXT ())
          val objfile = Filename.toString objfile
          val pre = [EXPAND (Config.LD ()), ARG "-r"]
          val post = [ARG "-o", ARG objfile]
          val (linkobjs, rest) =
              case ShellUtils.split {pre = pre, args = files, post = post} of
                (files as _::_::_, rest) => (files, rest)
              | (file1::nil, file2::rest) => ([file1, file2], rest)
              | (file1::nil, nil) => (nil, [file1])
              | (nil, file1::file2::rest) => ([file1, file2], rest)
              | (nil, file1::nil) => (nil, [file1])
              | (nil, nil) => (nil, nil)
        in
          case linkobjs of
            nil => nestLink pre linked rest post
          | _::_ =>
            (ShellUtils.system (pre @ linkobjs @ post);
             nestLink pre (linked @ [ARG objfile]) rest post)
        end

  fun invokeLinker {pre, files, post} =
      (nestLink pre nil files post; ())

  fun link {flags, objects, libs, dst, useCXX} =
      invokeLinker
        {pre = EXPAND (if useCXX
                       then Config.CXX ()
                       else Config.CC ())
               :: EXPAND (Config.LDFLAGS ())
               :: flags,
         files = map (ARG o Filename.toString) objects,
         post = libs
                @ [EXPAND (Config.LIBS ()),
                   ARG "-o", ARG (Filename.toString dst)]}
        
  fun partialLink {objects, dst} =
      invokeLinker
        {pre = [EXPAND (Config.LD ()), ARG "-r"],
         files = map (ARG o Filename.toString) objects,
         post = [ARG "-o", ARG (Filename.toString dst)]}

  fun assemble {source, flags, object} =
      (ShellUtils.system
         (EXPAND (Config.CC ())
          :: flags
          @ [ARG "-c", ARG (Filename.toString source),
             ARG "-o", ARG (Filename.toString object)]);
       ())

  fun invokeAr {objects, archive} =
      let
        val pre = [EXPAND (Config.AR ()),
                   ARG "qc", ARG (Filename.toString archive)]
        val (args, rest) =
            case ShellUtils.split {pre = pre, args = objects, post = nil} of
              (args as _::_, rest) => (args, rest)
            | (nil, arg::rest) => ([arg], rest)
            | (nil, nil) => (nil, nil)
      in
        ShellUtils.system (pre @ args);
        case rest of
          _::_ => invokeAr {objects = rest, archive = archive}
        | nil =>
          (ShellUtils.system [EXPAND (Config.RANLIB ()),
                              ARG (Filename.toString archive)];
           ())
      end

  fun archive {objects, archive} =
      (CoreUtils.rm_f archive;
       invokeAr {objects = map (ARG o Filename.toString) objects,
                 archive = archive})

end
