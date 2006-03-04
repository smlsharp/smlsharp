(* path-util-sig.sml
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *
 * Various higher-level pathname and searching utilities.
 *)

signature PATH_UTIL =
  sig

    val findFile  : string list -> string -> string option
    val findFiles : string list -> string -> string list

    val existsFile : (string -> bool) -> string list -> string -> string option
    val allFiles   : (string -> bool) -> string list -> string -> string list

  end;

