signature SIGA =
sig
  val return : int (* これを消すとエラーは発生しない *)
end;

structure STRA : SIGA =
struct
  val return = 314
end;

functor Mk (M : SIGA) =
struct
end;

structure S = Mk(STRA);

(*
2012-09-12 katsu

This ticket is derived from https://github.com/smlsharp/smlsharp/issues/3

Executing the above steps in interactive mode causes BUG.

SML# version 1.1.0 (2012-08-08 12:08:42 JST) for x86-linux
# use "235_functor.sml";
functor Mk
  (sig
    val return : int
  end) =
    sig
    end
signature SIGA =
  sig
    val return : int
  end
structure STRA =
  struct
    val return = 314 : int
  end
# structure S = Mk(STRA);
[BUG] none:0.0-0.0: exvar not found (SAContext):0

*)
