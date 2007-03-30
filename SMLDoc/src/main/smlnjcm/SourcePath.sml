(**
 * Operations over abstract names for CM source files.
 *
 * @author (c) 2000 by Lucent Technologies, Bell Laboratories
 * @author Matthias Blume
 * @version $Id: SourcePath.sml,v 1.4 2006/10/12 22:00:04 kiyoshiy Exp $
 *)
signature SOURCE_PATH =
sig

  (***************************************************************************)

  type file
  type dir
  type prefile

  (***************************************************************************)

  (* make abstract paths *)
  val native
      : {err: string -> unit } -> { context: dir, spec: string} -> prefile
  val standard
      : {err: string -> unit } -> { context: dir, spec: string} -> prefile

  (* augment a prefile (naming a directory) with a list of arcs... *)
  val extend : prefile -> string list -> prefile

  (* check that there is at least one arc in after the path's context *)
  val file : prefile -> file

  (* To be able to pickle a file, turn it into a prefile first... *)
  val pre : file -> prefile

  (* directory paths (contexts) *)
  val cwd : unit -> dir
  (* return the directory where the specified file is contained. *)
  val dir : file -> dir

  (* get info out of abstract paths *)
  val osstring : file -> string

  (* same for prefile *)
  val osstring_prefile_relative : prefile -> string

  (* get name of dir *)
  val osstring_dir : dir -> string

  (* get name of prefile *)
  val osstring_prefile : prefile -> string

  (***************************************************************************)

end

(**
 * @author (c) 2000 by Lucent Technologies, Bell Laboratories
 * @author Matthias Blume
 * @version $Id: SourcePath.sml,v 1.4 2006/10/12 22:00:04 kiyoshiy Exp $
 *)
structure SourcePath :> SOURCE_PATH =
struct

  (***************************************************************************)

  structure P = OS.Path
  structure F = OS.FileSys
  structure I = FileID

  fun impossible s = raise Fail ("impossible error in SrcPath: " ^ s)

  (***************************************************************************)

  (* A pre-path is similar to the result of P.fromString except that
   * we keep the list of arcs in reversed order.  This makes adding
   * and removing arcs at the end easier. *)
  type prepath = {revarcs: string list, vol: string, isAbs: bool}

  type elab = {pp: prepath}

  datatype dir =
	   CWD of { name: string, pp: prepath }
         | ROOT of string
         | DIR of file

  and file = PATH of {context: dir, arcs: string list} (* at least one arc! *)

  type prefile = {context: dir, arcs: string list, err: string -> unit}

  (***************************************************************************)

  fun string2pp n =
      let val {arcs, vol, isAbs} = P.fromString n
      in {revarcs = rev arcs, vol = vol, isAbs = isAbs} end

  fun absElab (arcs, vol) =
      {pp = {revarcs = rev arcs, vol = vol, isAbs = true}}

  fun cwd () =
      let val directory = F.getDir ()
      in CWD{name = directory, pp = string2pp directory} end

  fun pre (PATH {arcs, context, ...}) =
      {arcs = arcs, context = context, err = fn (_: string) => ()}

  fun dirPP {revarcs = _ :: revarcs, vol, isAbs} =
      {revarcs = revarcs, vol = vol, isAbs = isAbs}
    | dirPP _ = impossible "dirPP"

  fun dirElab {pp} = {pp = dirPP pp}

  fun augPP arcs {revarcs, vol, isAbs} =
      {revarcs = List.revAppend (arcs, revarcs), vol = vol, isAbs = isAbs}

  fun augElab arcs {pp} = {pp = augPP arcs pp}

  fun elab_dir (CWD {name, pp}) = {pp = pp}
    | elab_dir (ROOT vol) = absElab ([], vol)
    | elab_dir (DIR p) = dirElab (elab_file p)

  and elab_file (PATH {context, arcs}) = augElab arcs (elab_dir context)

  fun pp2name {revarcs, vol, isAbs} =
      P.toString {arcs = rev revarcs, vol = vol, isAbs = isAbs}

  val dir = DIR

  val osstring = I.canonical o pp2name o #pp o elab_file

  fun osstring_prefile {context, arcs, err} =
      I.canonical (pp2name (#pp (augElab arcs (elab_dir context))))

  fun osstring_dir d =
      case pp2name (#pp (elab_dir d)) of
	"" => P.currentArc
      | s => I.canonical s

  datatype stdspec =
	   RELATIVE of string list
         | ABSOLUTE of string list
         | ANCHORED of string * string list

  fun parseStdspec err s =
      let
	fun delim #"/" = true
	  | delim #"\\" = true
	  | delim _ = false
	fun transl ".." = P.parentArc
	  | transl "." = P.currentArc
	  | transl arc = arc
	val impossible = fn s => impossible ("AbsPath.parseStdspec: " ^ s)
      in
	case map transl (String.fields delim s) of
	  [""] => impossible "zero-length name"
	| [] => impossible "no fields"
	| "" :: arcs => ABSOLUTE arcs
	| arcs as ["$"] =>
	  (
            err (concat ["invalid zero-length anchor name in: `", s, "'"]);
	    RELATIVE arcs
          )
	| arcs as ("$" :: "" :: _) =>
	  (
            err (concat ["invalid zero-length anchor name in: `", s, "'"]);
	    RELATIVE arcs
          )
	| "$" :: (arcs as (arc1 :: _)) => ANCHORED (arc1, arcs)
	| arcs as (arc1 :: arcn) =>
	  if String.sub (arc1, 0) <> #"$"
          then RELATIVE arcs
	  else ANCHORED (String.extract (arc1, 1, NONE), arcn)
      end

  fun file ({context, arcs, err}: prefile) =
      PATH
      {
        context = context,
	arcs =
        (case arcs of
	   [] =>
           (err
            (concat
                 [
                   "path needs at least one arc relative to `",
		   pp2name (#pp (elab_dir context)),
                   "'"
                 ]);
	    ["<bogus>"])
	 | _ => arcs)
      }

  fun prefile (c, l, e) = {context = c, arcs = l, err = e}

  fun native {err} {context, spec} =
      case P.fromString spec of
	{arcs, vol, isAbs = true} => prefile (ROOT vol, arcs, err)
      | {arcs, ...} => prefile (context, arcs, err)

  fun standard {err} {context, spec} =
      case parseStdspec err spec of
	RELATIVE l => prefile (context, l, err)
      | ABSOLUTE l => prefile (ROOT "", l, err)
      | ANCHORED (a, l) => impossible "Anchor not supported."

  fun extend {context, arcs, err} morearcs =
      {context = context, arcs = arcs @ morearcs, err = err}

  fun osstring_prefile_relative (p as {arcs, context, ...}) =
      case context of
	DIR _ =>
        I.canonical (P.toString {arcs = arcs, vol = "", isAbs = false})
      | _ => osstring_prefile p

  val osstring_relative = osstring_prefile_relative o pre

  (***************************************************************************)

end
