val x = 0w90
(*
2011-12-27 ohori
This causes the following error:
  192_0w90.sml:1.9-1.12 Error: too large constant
Any non zero word constant causes this.
*)

(*
2012-1-14 ohori
I remember this is fixed by some of the change made to the basis library.
*)
