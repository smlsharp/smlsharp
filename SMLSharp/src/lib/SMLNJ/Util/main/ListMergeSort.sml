(* listsort.sml
 *
 * COPYRIGHT (c) 1993 by AT&T Bell Laboratories.  See COPYRIGHT file for details.
 *
 * List sorting routines using a smooth applicative merge sort
 * Taken from, ML for the Working Programmer, LCPaulson. pg 99-100
 *)

structure ListMergeSort : LIST_SORT = 
  struct

    fun sort (op > : 'a * 'a -> bool) ls = let 
          fun merge([],ys) = ys
            | merge(xs,[]) = xs
            | merge(x::xs,y::ys) =
                if x > y then y::merge(x::xs,ys) else x::merge(xs,y::ys)
          fun mergepairs(ls as [l], k) = ls
            | mergepairs(l1::l2::ls,k) =
                if k mod 2 = 1 then l1::l2::ls
                else mergepairs(merge(l1,l2)::ls, k div 2)
            | mergepairs _ = raise LibBase.Impossible "ListSort.sort"
          fun nextrun(run,[])    = (rev run,[])
            | nextrun(run,x::xs) = if x > hd run then nextrun(x::run,xs)
                                   else (rev run,x::xs)
          fun samsorting([], ls, k)    = hd(mergepairs(ls,0))
            | samsorting(x::xs, ls, k) = let 
                val (run,tail) = nextrun([x],xs)
                in samsorting(tail, mergepairs(run::ls,k+1), k+1)
                end
          in 
            case ls of [] => [] | _ => samsorting(ls, [], 0)
          end

    fun uniqueSort cmpfn ls = let 
          open LibBase
          fun merge([],ys) = ys
            | merge(xs,[]) = xs
            | merge(x::xs,y::ys) =
                case cmpfn (x,y) of
                  GREATER => y::merge(x::xs,ys)
                | EQUAL   => merge(x::xs,ys)
                | _       => x::merge(xs,y::ys)
          fun mergepairs(ls as [l], k) = ls
            | mergepairs(l1::l2::ls,k) =
                if k mod 2 = 1 then l1::l2::ls
                else mergepairs(merge(l1,l2)::ls, k div 2)
            | mergepairs _ = raise LibBase.Impossible "ListSort.uniqueSort"
          fun nextrun(run,[])    = (rev run,[])
            | nextrun(run,x::xs) = 
                case cmpfn(x, hd run) of
                  GREATER => nextrun(x::run,xs)
                | EQUAL   => nextrun(run,xs)
                | _       => (rev run,x::xs)
          fun samsorting([], ls, k)    = hd(mergepairs(ls,0))
            | samsorting(x::xs, ls, k) = let 
                val (run,tail) = nextrun([x],xs)
                in samsorting(tail, mergepairs(run::ls,k+1), k+1)
                end
          in 
            case ls of [] => [] | _ => samsorting(ls, [], 0)
          end

    fun sorted (op >) = let 
          fun s (x::(rest as (y::_))) = not(x>y) andalso s rest
            | s l = true
          in s end

  end (* ListMergeSort *)
