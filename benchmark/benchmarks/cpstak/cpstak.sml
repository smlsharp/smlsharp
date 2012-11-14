fun cpstak (x, y, z) =
  let fun tak (x, y, z, k) =
        if not (y < x)
          then k z
          else tak (x - 1,
                    y,
                    z,
                    fn (v1) =>
                      tak (y - 1,
                           z,
                           x,
                           fn (v2) =>
                             tak (z - 1,
                                  x,
                                  y,
                                  fn (v3) =>
                                    tak (v1, v2, v3, k))))
  in tak (x, y, z, fn (a) => a)
  end

fun run_benchmark x = x
val cpstak_iters = 300

fun cpstak_benchmark (n) =
  run_benchmark ("cpstak", n, fn () => cpstak (18, 12, 6),
                              fn (x) => x = 7)

fun main () = cpstak_benchmark (cpstak_iters)

structure Main =
struct
  fun testit out =
      let val (_,_,f,t) = main ()
      in TextIO.output (out, if t (f ()) then "OK\n" else "Fail\n") end
  fun doit () =
      let val (_,n,f,_) = main ()
          fun loop 0 = () | loop n = (f (); loop (n-1))
      in loop n end
end
