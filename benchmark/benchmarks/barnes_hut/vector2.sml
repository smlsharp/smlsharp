(* vector2.sml
 *
 * COPYRIGHT (c) 1993, AT&T Bell Laboratories.
 *
 * 2 dimensional vector arithmetic.
 *)

structure Vector2 : VECTOR =
  struct

    type 'a vec = {x : 'a, y : 'a}
    type realvec = real vec

    val dim = 2

    fun tabulate f = {x = f 0, y = f 1}

    fun equal({x, y}, {x=x1, y=y1}) = Real.==(x, x1) andalso Real.==(y, y1)
    val zerov = {x = 0.0, y = 0.0}

    fun addv ({x=x1, y=y1} : realvec, {x=x2, y=y2}) = {x=x1+x2, y=y1+y2}

    fun subv ({x=x1, y=y1} : realvec, {x=x2, y=y2}) = {x=x1-x2, y=y1-y2}

    fun dotvp ({x=x1, y=y1} : realvec, {x=x2, y=y2}) = x1*x2 + y1*y2

    fun crossvp ({x=x1, y=y1} : realvec, {x=x2, y=y2}) = {x=x1*y2, y=x2*y1}

    fun addvs ({x, y} : realvec, s) = {x=x+s, y=y+s}

    fun mulvs ({x, y} : realvec, s) = {x=x*s, y=y*s}

    fun divvs ({x, y} : realvec, s) = {x=x/s, y=y/s}

    fun mapv f {x, y} = {x = f x, y = f y}

    fun map3v f ({x=x1, y=y1}, {x=x2, y=y2}, {x=x3, y=y3}) =
	  {x = f(x1, x2, x3), y = f(y1, y2, y3)}

    fun foldv f {x, y} init = f(y, f(x, init))

    fun format {lp, rp, sep, cvt} {x, y} = String.concat[lp, cvt x, sep, cvt y, rp]

    fun explode {x, y} = [x, y]

    fun implode [x, y] = {x=x, y=y}
      | implode _ = raise Fail "implode: bad dimension"

    type matrix = {
	    m00 : real, m01 : real,
	    m10 : real, m11 : real
	  }

    val zerom = {
	    m00 = 0.0, m01 = 0.0,
	    m10 = 0.0, m11 = 0.0
	  }

    fun addm (a : matrix, b : matrix) = {
	    m00=(#m00 a + #m00 b), m01=(#m01 a + #m01 b),
	    m10=(#m10 a + #m10 b), m11=(#m11 a + #m11 b)
	  }

    fun outvp ({x=a0, y=a1} : realvec, {x=b0, y=b1}) = {
	    m00=(a0*b0), m01=(a0*b1),
	    m10=(a1*b0), m11=(a1*b1)
	  }

  end (* VectMath *)

