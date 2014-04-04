(**
 * stdio.sml - sample program using standard I/O of C
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: stdio.sml,v 1.7 2007/04/02 09:42:29 katsu Exp $
 *)

type c_file = unit ptr

val fopen = _import "fopen" : (string, string) -> c_file
val fclose = _import "fclose" : c_file -> ()

fun fread (dst, len, file) =
    _ffiapply _import "fread"
      (dst : 'a array, _sizeof('a), len : int, file : c_file) : int

fun fwrite (dst, len, file) =
    _ffiapply _import "fwrite"
      (dst : 'a array, _sizeof('a), len : int, file : c_file) : int

fun printAry ary =
    (Array.app (fn x => print (" " ^ Real.toString x)) ary;
     print "\n")


(* create a file and write an real array to it. *)

val file = fopen ("test.bin", "wb")
val _ = if Pointer.isNull file then raise Fail "fopen failed" else ()

val data = Array.fromList [0.0, 1.0, 2.5, 3.1, ~104.6]
val _ = printAry data

val _ = fwrite (data, Array.length data, file)

val _ = fclose file


(* open the file and read the real array from it. *)

val file = fopen ("test.bin", "rb")
val _ = if Pointer.isNull file then raise Fail "fopen failed" else ()

val buf = Array.array (5, 0.0)
val _ = printAry buf

val _ = fread (buf, Array.length buf, file)

val _ = fclose file

val _ = printAry buf
