(**
 * filename type - a way for describing what you are thinking by types.
 * @copyright (c) 2010, Tohoku University.
 * @author UENO Katsuhiro
 *)
structure Filename :> sig

  eqtype filename

  (* "/" is used as directory separator on any platform. *)
  val toString : filename -> string
  val fromString : string -> filename
  val format_filename : filename -> SMLFormat.FormatExpression.expression list

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

  val format_filename = SMLFormat.BasicFormatters.format_string

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
      OS.FileSys.realPath filename

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
