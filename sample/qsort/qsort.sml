(**
 * qsort.sml - sample program using FFI
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: qsort.sml,v 1.9 2007/09/20 09:02:53 matsu Exp $
 *)

fun qsort (a, f) =
    _ffiapply _import "qsort"
      (a : 'a array,
       Array.length a : int,
       _sizeof('a),
       f : ('a ptr, 'a ptr) -> int) : ()

fun printIntAry x = (Array.app (fn x => print (" " ^ Int.toString x)) x;
                     print "\n")
fun printRealAry x = (Array.app (fn x => print (" " ^ Real.toString x)) x;
                      print "\n")

val a = Array.fromList [4,75,14,2147483647,3,6,423,42,~2147483648,8,2]
val b = Array.fromList [2.3, 1.1, 0.2,10.5,~12.0]

val _ = printIntAry a
val _ = printRealAry b

fun compare (p1, p2) =
    let
      val n1 = Pointer.load p1
      val n2 = Pointer.load p2
    in
      if n1 > n2 then 1 else if n1 < n2 then ~1 else 0
    end

val _ = qsort (a, compare)
val _ = qsort (b, compare)

val _ = printIntAry a
val _ = printRealAry b
