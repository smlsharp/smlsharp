(* simple-textio-dev.sml
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *
 * A simple (no styles) pretty-printing device for output to TextIO outstreams.
 *)

structure SimpleTextIODev : sig

    include PP_DEVICE

    val openDev : {dst : TextIO.outstream, wid : int} -> device

  end = struct

    datatype device = DEV of {
	dst : TextIO.outstream,
	wid : int
      }

  (* no style support *)
    type style = unit
    fun sameStyle _ = true
    fun pushStyle _ = ()
    fun popStyle _ = ()
    fun defaultStyle _ = ()

    val openDev = DEV

  (* maximum printing depth (in terms of boxes) *)
    fun depth _ = NONE

  (* the width of the device *)
    fun lineWidth (DEV{wid, ...}) = SOME wid
  (* the suggested maximum width of text on a line *)
    fun textWidth _ = NONE

  (* output some number of spaces to the device *)
    fun space (DEV{dst, ...}, n) = TextIO.output (dst, StringCvt.padLeft #" " n "")

  (* output a new-line to the device *)
    fun newline (DEV{dst, ...}) = TextIO.output1 (dst, #"\n")

  (* output a string/character in the current style to the device *)
    fun string (DEV{dst, ...}, s) = TextIO.output (dst, s)
    fun char (DEV{dst, ...}, c) = TextIO.output1 (dst, c)

  (* if the device is buffered, then flush any buffered output *)
    fun flush (DEV{dst, ...}) = TextIO.flushOut dst

  end;

