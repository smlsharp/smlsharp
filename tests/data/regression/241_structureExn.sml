structure F =
struct
  exception Foo = FOO
  exception Bar = BAR
  structure S = ST
end

(*
2013-01-26 katsu

This does not seem to cause any error.
I do not know what is the case of this ticket since there is no comment left.
Move to fixed, anyway.

*)
