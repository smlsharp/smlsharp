_interface "fft.smi"

  val dtoa =
      _import "sml_dtoa"
      : __attribute__((no_callback))
        (real, int, int, int ref, int ref, char ptr ptr) -> char ptr
  val freedtoa =
      _import "sml_freedtoa"
      : __attribute__((no_callback)) char ptr -> unit
  val str_new =
      _import "sml_str_new"
      : __attribute__((no_callback,alloc)) char ptr -> string
  val ya_String_allocateImmutableNoInit =
      _import "prim_String_allocateImmutableNoInit"
      : __attribute__((pure,no_callback,alloc)) word -> string
  fun ! (ref x) = x

  fun op ^ (x:string, y:string) : string =
      let
        val n1 = SMLSharp.PrimString.size x
        val n2 = SMLSharp.PrimString.size y
        val newstr = ya_String_allocateImmutableNoInit (Word.fromInt (n1 + n2))
      in
        SMLSharp.PrimString.copy_unsafe (x, 0, newstr, 0, n1);
        SMLSharp.PrimString.copy_unsafe (y, 0, newstr, n1, n2);
        newstr
      end
  infix 6 ^

structure Array =
struct
  val sub = SMLSharp.PrimArray.sub_unsafe
  val update = SMLSharp.PrimArray.update_unsafe
  val array = SMLSharp.PrimArray.array
end

structure Math =
struct
  val cos = _import "cos" : real -> real
  val sin = _import "sin" : real -> real
end

structure Int =
struct
  open Int
  val toString = _import "prim_Int_toString" : __attribute__((alloc)) int -> string
end

structure Real =
struct
  open Real
  fun toString (d:real) : string =
      let
        val decpt = ref 0
        val sign = ref 0
        val s = dtoa (d, 2, 8, decpt, sign, (_cast(_NULL):char ptr ptr))
        val str = str_new s
        val _ = freedtoa s
        val str = "." ^ str
        val str = if !sign = 0 then str else "~" ^ str
      in
        str ^ "E" ^ Int.toString (!decpt)
      end
end

val print = _import "prim_print" : string -> unit

infix 6 o
fun f o g = fn x => f (g x)

structure Main = struct

local
open Array Math

val printr = print o Real.toString
val printi = print o Int.toString
in

val PI = 3.14159265358979323846

val tpi = 2.0 * PI

fun fft px py np =
  let fun find_num_points i m =
        if i < np then find_num_points (i+i) (m+1) else (i,m)
      val (n,m) = find_num_points 2 1 in
  if n = np
  then ()
  else
    let fun loop i = if i > n then () else (
      SMLSharp.PrimArray.update_unsafe(px, i, 0.0);
      SMLSharp.PrimArray.update_unsafe(py, i, 0.0);
      loop (i+1))
    in
      loop (np+1);
      print "Use "; printi n; print " point fft\n"
    end;

  let fun loop_k k n2 = if k >= m then () else
    let val n4 = n2 div 4
        val e  = tpi / (Real.fromInt n2)
        fun loop_j j a = if j > n4 then () else
          let val a3 = 3.0 * a
              val cc1 = cos(a)
              val ss1 = sin(a)
              val cc3 = cos(a3)
              val ss3 = sin(a3)
              fun loop_is is id = if is >= n then () else
                let fun loop_i0 i0 = if i0 >= n then () else
                  let val i1 = i0 + n4
	              val i2 = i1 + n4
	              val i3 = i2 + n4
	              val r1 = SMLSharp.PrimArray.sub_unsafe(px, i0) - SMLSharp.PrimArray.sub_unsafe(px, i2)
                      val _ = SMLSharp.PrimArray.update_unsafe(px, i0, SMLSharp.PrimArray.sub_unsafe(px, i0) + SMLSharp.PrimArray.sub_unsafe(px, i2))
                      val r2 = SMLSharp.PrimArray.sub_unsafe(px, i1) - SMLSharp.PrimArray.sub_unsafe(px, i3)
	              val _ = SMLSharp.PrimArray.update_unsafe(px, i1, SMLSharp.PrimArray.sub_unsafe(px, i1) + SMLSharp.PrimArray.sub_unsafe(px, i3))
                      val s1 = SMLSharp.PrimArray.sub_unsafe(py, i0) - SMLSharp.PrimArray.sub_unsafe(py, i2)
	              val _ = SMLSharp.PrimArray.update_unsafe(py, i0, SMLSharp.PrimArray.sub_unsafe(py, i0) + SMLSharp.PrimArray.sub_unsafe(py, i2))
                      val s2 = SMLSharp.PrimArray.sub_unsafe(py, i1) - SMLSharp.PrimArray.sub_unsafe(py, i3)
                      val _ = SMLSharp.PrimArray.update_unsafe(py, i1, SMLSharp.PrimArray.sub_unsafe(py, i1) + SMLSharp.PrimArray.sub_unsafe(py, i3))
                      val s3 = r1 - s2
                      val r1 = r1 + s2
                      val s2 = r2 - s1
                      val r2 = r2 + s1
                      val _ = SMLSharp.PrimArray.update_unsafe(px, i2, r1*cc1 - s2*ss1)
                      val _ = SMLSharp.PrimArray.update_unsafe(py, i2, ~s2*cc1 - r1*ss1)
                      val _ = SMLSharp.PrimArray.update_unsafe(px, i3, s3*cc3 + r2*ss3)
                      val _ = SMLSharp.PrimArray.update_unsafe(py, i3, r2*cc3 - s3*ss3)
                  in
                    loop_i0 (i0 + id)
                  end
                in
                  loop_i0 is;
                  loop_is (2 * id - n2 + j) (4 * id)
                end
          in
            loop_is j (2 * n2);
            loop_j (j+1) (e * Real.fromInt j)
          end
    in
      loop_j 1 0.0;
      loop_k (k+1) (n2 div 2)
    end
  in
    loop_k 1 n
  end;

(************************************)
(*  Last stage, length=2 butterfly  *)
(************************************)

  let fun loop_is is id = if is >= n then () else
    let fun loop_i0 i0 = if i0 > n then () else
      let val i1 = i0 + 1
          val r1 = SMLSharp.PrimArray.sub_unsafe(px, i0)
          val _ = SMLSharp.PrimArray.update_unsafe(px, i0, r1 + SMLSharp.PrimArray.sub_unsafe(px, i1))
          val _ = SMLSharp.PrimArray.update_unsafe(px, i1, r1 - SMLSharp.PrimArray.sub_unsafe(px, i1))
          val r1 = SMLSharp.PrimArray.sub_unsafe(py, i0)
          val _ = SMLSharp.PrimArray.update_unsafe(py, i0, r1 + SMLSharp.PrimArray.sub_unsafe(py, i1))
          val _ = SMLSharp.PrimArray.update_unsafe(py, i1, r1 - SMLSharp.PrimArray.sub_unsafe(py, i1))
      in
        loop_i0 (i0 + id)
      end
    in
      loop_i0 is;
      loop_is (2*id - 1) (4 * id)
    end
  in
    loop_is 1 4
  end;

(*************************)
(*  Bit reverse counter  *)
(*************************)

  let fun loop_i i j = if i >= n then () else
   (if i < j then
     (let val xt = SMLSharp.PrimArray.sub_unsafe(px, j)
      in SMLSharp.PrimArray.update_unsafe(px, j, SMLSharp.PrimArray.sub_unsafe(px, i)); SMLSharp.PrimArray.update_unsafe(px, i, xt)
      end;
      let val xt = SMLSharp.PrimArray.sub_unsafe(py, j)
      in SMLSharp.PrimArray.update_unsafe(py, j, SMLSharp.PrimArray.sub_unsafe(py, i)); SMLSharp.PrimArray.update_unsafe(py, i, xt)
      end)
    else ();
    let fun loop_k k j =
              if k < j then loop_k (k div 2) (j-k) else j+k
        val j' = loop_k (n div 2) j
    in
      loop_i (i+1) j'
    end)
  in
    loop_i 1 1
  end;

  n
  end

fun abs x = if x >= 0.0 then x else ~x

fun test np =
  let val _ = (printi np; print "... ")
      val enp = Real.fromInt np
      val npm = (np div 2) - 1
      val pxr = SMLSharp.PrimArray.array (np+2, 0.0)
      val pxi = SMLSharp.PrimArray.array (np+2, 0.0)
      val t = PI / enp
      val _ = SMLSharp.PrimArray.update_unsafe(pxr, 1, (enp - 1.0) * 0.5)
      val _ = SMLSharp.PrimArray.update_unsafe(pxi, 1, 0.0)
      val n2 = np  div  2
      val _ = SMLSharp.PrimArray.update_unsafe(pxr, n2+1, ~0.5)
      val _ = SMLSharp.PrimArray.update_unsafe(pxi, n2+1,  0.0)
      fun loop_i i = if i > npm then () else
        let val j = np - i
            val _ = SMLSharp.PrimArray.update_unsafe(pxr, i+1, ~0.5)
            val _ = SMLSharp.PrimArray.update_unsafe(pxr, j+1, ~0.5)
            val z = t * Real.fromInt i
            val y = ~0.5*(cos(z)/sin(z))
            val _ = SMLSharp.PrimArray.update_unsafe(pxi, i+1,  y)
            val _ = SMLSharp.PrimArray.update_unsafe(pxi, j+1, ~y)
        in
          loop_i (i+1)
        end
      val _ = loop_i 1
(***
      val _ = print "\n"
      fun loop_i i = if i > 15 then () else
        (print i; print "\t";
         print (SMLSharp.PrimArray.sub_unsafe(pxr, i+1)); print "\t";
         print (SMLSharp.PrimArray.sub_unsafe(pxi, i+1)); print "\n"; loop_i (i+1))
      val _ = loop_i 0
***)
      val _ = fft pxr pxi np
(***
      fun loop_i i = if i > 15 then () else
        (print i; print "\t";
         print (SMLSharp.PrimArray.sub_unsafe(pxr, i+1)); print "\t";
         print (SMLSharp.PrimArray.sub_unsafe(pxi, i+1)); print "\n"; loop_i (i+1))
      val _ = loop_i 0
***)
      fun loop_i i zr zi kr ki = if i >= np then (zr,zi) else
        let val a = abs(SMLSharp.PrimArray.sub_unsafe(pxr, i+1) - Real.fromInt i)
            val (zr, kr) =
              if zr < a then (a, i) else (zr, kr)
            val a = abs(SMLSharp.PrimArray.sub_unsafe(pxi, i+1))
            val (zi, ki) =
              if zi < a then (a, i) else (zi, ki)
        in
          loop_i (i+1) zr zi kr ki
        end
      val (zr, zi) = loop_i 0 0.0 0.0 0 0
      val zm = if abs zr < abs zi then zi else zr
  in
    printr zm; print "\n"
  end

fun loop_np i np = if i > 13 then () else
  (test np; loop_np (i+1) (np*2))

fun doit () = (let val s = (Real.toString 1.23)
in loop_np 1 16 end)

fun testit outstream = doit()

end
end;
