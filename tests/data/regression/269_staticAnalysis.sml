functor Simple() =
  struct

fun for start body =
	let
          fun f x = (body x; f(x+1))
	in
          f start
	end

end

(*
2014-01-26 katsu

This does not cause any error on LLVM backend.
*)
