(* space.sml
 *
 * COPYRIGHT (c) 1993, AT&T Bell Laboratories.
 *
 * The quad/oct-tree representation of space.
 *)

signature SPACE =
  sig

    structure V : VECTOR

    datatype body = Body of {
	mass : real,
	pos : real V.vec ref,
	vel : real V.vec ref,
	acc : real V.vec ref,
	phi : real ref
      }

    datatype cell
      = BodyCell of body
      | Cell of node Array.array

    and node
      = Empty
      | Node of {
	  mass : real ref,
	  pos : real V.vec ref,
	  cell : cell
	}

    datatype space = Space of {
	rmin : real V.vec,
	rsize : real,
	root : node
      }

    val nsub : int	(* number of sub cells / cell (2 ^ V.dim) *)

    val putCell : (cell * int * node) -> unit
    val getCell : (cell * int) -> node
    val mkCell : unit -> cell
    val mkBodyNode : body -> node
    val mkCellNode : cell -> node
    val eqBody : body * body -> bool

  (* debugging code *)
    val dumpTree : node -> unit
    val prBody : body -> string
    val prNode : node -> string

  end; (* SPACE *)
