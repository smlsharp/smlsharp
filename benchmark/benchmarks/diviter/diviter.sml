(******************************************************************************
* File:         diviter.sml
* Description:  DIV benchmarks
* Author:       Richard Gabriel
* Created:      8-Apr-85
* Modified:     19-Jul-85 18:28:01 (Bob Shaw)
*               23-Jul-87 (Will Clinger: translated into Scheme)
*               4-May-94 (Will Clinger: translated into SML)
*               24-Jun-99 (Will Clinger: split into two files)
* Language:     Standard ML
* Status:       Public Domain
******************************************************************************)
 
(*  DIV2 -- Benchmark which divides by 2 using lists of n []'s.              *)

fun create_n n =
  let fun loop (n, a) =
    if n = 0
      then a
      else loop (n-1, []::a)
  in loop (n, [])
  end

val ll = create_n 200

fun iterative_div2 l =
  let fun loop ([], a) = a
        | loop (x::y::z, a) = loop (z, x::a)
  in loop (l, [])
  end

fun run_benchmark x = x
val diviter_iters = 400000

fun div_iter (n) =
  run_benchmark ("diviter", n, fn () => iterative_div2 ll,
                               fn (x) => length x = 100)

fun main () = div_iter (diviter_iters)

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
