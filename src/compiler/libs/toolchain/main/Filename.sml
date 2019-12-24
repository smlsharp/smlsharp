(**
 * filename type - a way for describing what you are thinking by types.
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure Filename =
struct
  type filename = string

  (* empty is the identity element of concatPath *)
  val empty = ""

  val dot = OS.Path.currentArc
  val dotdot = OS.Path.parentArc

  fun fromString x = x : filename
  fun toString x = x : string
  fun format_filename x = SMLFormat.BasicFormatters.format_string x

  fun isEmpty "" = true
    | isEmpty _ = false

  (* same as POSIX basename(1) *)
  fun basename filename =
      case OS.Path.splitDirFile filename of
        {dir, file = ""} => if dir = filename then dir else basename dir
      | {dir, file} => file

  fun removeTrailing filename =
      case OS.Path.splitDirFile filename of
        {dir, file = ""} => if dir = filename then dir else removeTrailing dir
      | _ => filename

  (* same as POSIX dirname(1) *)
  fun dirname filename =
      case OS.Path.splitDirFile filename of
        {dir = "", file} => dot
      | {dir, file = ""} => if dir = filename then dir else dirname dir
      | {dir, file} => removeTrailing dir

  fun suffix filename =
      #ext (OS.Path.splitBaseExt filename)

  fun addSuffix ("", suffix) = ""
    | addSuffix (filename, suffix) =
      OS.Path.joinBaseExt {base = filename, ext = SOME suffix}

  fun removeSuffix filename =
      #base (OS.Path.splitBaseExt filename)

  fun replaceSuffix suffix filename =
      addSuffix (removeSuffix filename, suffix)

  fun pwd () =
      OS.FileSys.getDir ()

  fun concatPath ("", x) = x
    | concatPath (x, "") = x
    | concatPath (filename1, filename2) =
      OS.Path.concat (filename1, filename2)

  fun concatPaths nil = ""
    | concatPaths ("" :: t) = concatPaths t
    | concatPaths (filename :: nil) = filename
    | concatPaths (filename1 :: filename2 :: t) =
      concatPaths (concatPath (filename1, filename2) :: t)

  (* concatPaths o components is an identical function except that
   * unneeded shashes are removed *)
  fun components filename =
      case OS.Path.splitDirFile filename of
        {dir = "", file = ""} => []
      | {dir = "", file} => [file]
      | {dir, file = ""} => if dir = filename then [dir] else components dir
      | {dir, file} => components dir @ [file]

  fun isAbsolute filename =
      OS.Path.isAbsolute filename

  fun realPath "" = "."
    | realPath filename =
      OS.FileSys.realPath filename

  val compare = String.compare

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

  structure Map = SEnv
  structure Set = SSet

end
