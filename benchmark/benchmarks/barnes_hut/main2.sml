structure Main =
  struct
    structure M3 = Main(Vector3);

    val name = "Barnes-Hut (3d)"

    fun testit strm = ()

    fun doit () = (
	  M3.srand 123;
	  M3.go {
	      output = fn _ => (),
	      bodies = M3.testdata 128,
	      tnow = 0.0, tstop = 2.0,
	      dtime = 0.025, eps = 0.05, tol = 1.0,
	      rmin = M3.S.V.tabulate (fn _ => ~2.0),
	      rsize = 4.0
	    })

  end;
