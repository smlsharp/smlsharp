(* posix-flags-sig.sml
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *)

signature POSIX_FLAGS =
  sig

    eqtype  flags

    val toWord : flags -> SysWord.word
    val wordTo : SysWord.word -> flags

    val flags : flags list -> flags

    val allSet : (flags * flags) -> bool

    val anySet : (flags * flags) -> bool

  end;
