(* build.sml
 *
 * COPYRIGHT (c) 1994 AT&T Bell Laboratories.
 *
 * Build a two-dimensional tree for TSP.
 *)

structure BuildTree : sig

    datatype axis = X_AXIS | Y_AXIS

    val buildTree : {
	    n : int, dir : axis,
	    min_x : real, min_y : real, max_x : real, max_y : real
	  } -> Tree.tree

  end = struct

    structure T = Tree

    val m_e	= 2.7182818284590452354
    val m_e2	= 7.3890560989306502274
    val m_e3	= 20.08553692318766774179
    val m_e6	= 403.42879349273512264299
    val m_e12	= 162754.79141900392083592475

    datatype axis = X_AXIS | Y_AXIS

  (* builds a 2D tree of n nodes in specified range with dir as primary axis *)
    fun buildTree arg = let
	  val rand = Rand.mkRandom 0w314
	  fun drand48 () = Rand.norm (rand ())
	  fun median {min, max, n} = let
	        val t = drand48(); (* in [0.0..1.0) *)
	        val retval = if (t > 0.5)
		      then Math.ln(1.0-(2.0*(m_e12-1.0)*(t-0.5)/m_e12))/12.0
		      else ~(Math.ln(1.0-(2.0*(m_e12-1.0)*t/m_e12))/12.0)
	        in
	          min + ((retval + 1.0) * (max - min)/2.0)
	        end
	  fun uniform {min, max} = min + (drand48() * (max - min))
	  fun build {n = 0, ...} = T.NULL
	    | build {n, dir=X_AXIS, min_x, min_y, max_x, max_y} = let
		val med = median{min=min_y, max=max_y, n=n}
		fun mkTree (min, max) = build{
			n=n div 2, dir=Y_AXIS, min_x=min_x, max_x=max_x,
			min_y=min, max_y=max
		      }
		in
		  T.mkNode(
		    mkTree(min_y, med), mkTree(med, max_y),
		    uniform{min=min_x, max=max_x}, med, n)
		end
	    | build {n, dir=Y_AXIS, min_x, min_y, max_x, max_y} = let
		val med = median{min=min_x, max=max_x, n=n}
		fun mkTree (min, max) = build{
			n=n div 2, dir=X_AXIS, min_x=min, max_x=max,
			min_y=min_y, max_y=max_y
		      }
		in
		  T.mkNode(
		    mkTree(min_x, med), mkTree(med, max_x),
		    med, uniform{min=min_y, max=max_y}, n)
		end
	  in
	    build arg
	  end

  end; (* Build *)

