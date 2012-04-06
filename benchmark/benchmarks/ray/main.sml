(* main.sml
 *
 * COPYRIGHT (c) 1992 AT&T Bell Laboratories
 *
 * Main structure for running raytracer as benchmark.
 *)

structure Main =
  struct

    fun doit () = let
	  val strm = TextIO.openString ("\
		  \100 0 0 0 8 8 8 color sphere\n\
		  \/./TEST raytrace\n\
		  \stop\n\
		\")
	  in
	    Interface.rtInit();
	    Interp.parse strm
	  end

  end;

