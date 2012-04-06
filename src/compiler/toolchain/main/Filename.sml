(**
 * filename type - a way for describing what you are thinking by types.
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure Filename :> sig

  type filename

  (* "/" is used as directory separator on any platform. *)
  val toString : filename -> string
  val fromString : string -> filename

  val basename : filename -> filename
  val dirname : filename -> filename
  val suffix : filename -> string option
  val addSuffix : filename * string -> filename
  val removeSuffix : filename -> filename
  val replaceSuffix : string -> filename -> filename
  val pwd : unit -> filename
  val concatPath : filename * filename -> filename
  val isAbsolute : filename -> bool
  val realPath : filename -> filename

  structure TextIO : sig
    val openIn : filename -> TextIO.instream
    val openOut : filename -> TextIO.outstream
  end
  structure BinIO : sig
    val openIn : filename -> BinIO.instream
    val openOut : filename -> BinIO.outstream
  end

end =
struct
  type filename = string

  fun toString x = x : string
  fun fromString x = x : filename

  fun basename filename =
      #file (OS.Path.splitDirFile filename)

  fun dirname filename =
      case #dir (OS.Path.splitDirFile filename) of
        "" => "."
      | x => x

  fun suffix filename =
      #ext (OS.Path.splitBaseExt filename)

  fun addSuffix (filename, suffix) =
      OS.Path.joinBaseExt {base = filename, ext = SOME suffix}

  fun removeSuffix filename =
      #base (OS.Path.splitBaseExt filename)

  fun replaceSuffix suffix filename =
      addSuffix (removeSuffix filename, suffix)

  fun pwd () =
      OS.FileSys.getDir ()

  fun concatPath ("", filename) = filename
    | concatPath (filename1, filename2) =
      if filename1 = OS.Path.currentArc
      then filename2
      else OS.Path.concat (filename1, filename2)

  fun isAbsolute filename =
      OS.Path.isAbsolute filename

  fun realPath filename =
      let
        val maxLinks = 64
        fun toFilename (root, cur) =
            String.concatWith "/" (rev root @ rev cur)
        fun readlink name =
            SOME (OS.FileSys.readLink name) handle _ => NONE
        fun walk (0, _, _, _) = raise OS.SysErr ("too many symlinks", NONE)
          | walk (n, root, cur, nil) = toFilename (root, cur)
          | walk (n, root, cur, ""::path) = walk (n, root, cur, path)
          | walk (n, root, cur, "."::path) = walk (n, root, cur, path)
          | walk (n, root, _::cur, ".."::path) = walk (n, root, cur, path)
          | walk (n, root, nil, ".."::path) =
            (case root of
               ""::_ => walk (n, root, nil, path)
             | _ => walk (n, ".."::root, nil, path))
          | walk (n, root, cur, name::path) =
            case readlink (toFilename (root, name::cur)) of
              NONE => walk (n, root, name::cur, path)
            | SOME filename =>
              case String.fields (fn c => c = #"/") filename of
                ""::lpath => walk (n-1, [""], nil, lpath)
              | lpath => walk (n-1, root, cur, lpath @ path)
      in
        case String.fields (fn c => c = #"/") filename of
          ""::path => walk (maxLinks, [""], nil, path)
        | path => walk (maxLinks, nil, nil, path)
      end

  structure TextIO =
  struct
    fun openIn filename = TextIO.openIn filename
    fun openOut filename = TextIO.openOut filename
  end
  structure BinIO =
  struct
    fun openIn filename = BinIO.openIn filename
    fun openOut filename = BinIO.openOut filename
  end

end
