(**
 * stdio.sml - sample program using standard I/O of C
 *
 * @copyright (c) 2006-2007, Tohoku University.
 * @author UENO Katsuhiro
 * @version $Id: stdio.sml,v 1.6.2.1 2007/03/26 06:26:50 katsu Exp $
 *)


val libc = "/lib/libc.so.6"
(*
val libc = "/usr/lib/libc.dylib"  (* Mac OS X *)
*)
(*
use "cconfig.sml";
val libc = valOf (CConfig.findLibrary("c","fopen",["stdio.h"]));
*)

val libc = DynamicLink.dlopen libc
val c_fopen = DynamicLink.dlsym (libc, "fopen")
val c_fwrite = DynamicLink.dlsym (libc, "fwrite")
val c_fread = DynamicLink.dlsym (libc, "fread")
val c_fclose = DynamicLink.dlsym (libc, "fclose")

type c_file = unit ptr

val fopen = c_fopen : _import (string, string) -> c_file
val fclose = c_fclose : _import c_file -> unit

fun fread (dst, len, file) =
    _ffiapply c_fread (dst : 'a array, _sizeof('a), len : int, file : c_file)
                      : int

fun fwrite (dst, len, file) =
    _ffiapply c_fwrite (dst : 'a array, _sizeof('a), len : int, file : c_file)
                       : int

fun printAry ary =
    (Array.app (fn x => print (" " ^ Real.toString x)) ary;
     print "\n")


(* create a file and write an real array to it. *)

val file = fopen ("test.bin", "wb")
val _ = if file = NULL then raise Fail "fopen failed" else ()

val data = Array.fromList [0.0, 1.0, 2.5, 3.1, ~104.6]
val _ = printAry data

val _ = fwrite (data, Array.length data, file)

val _ = fclose file


(* open the file and read the real array from it. *)

val file = fopen ("test.bin", "rb")
val _ = if file = NULL then raise Fail "fopen failed" else ()

val buf = Array.array (5, 0.0)
val _ = printAry buf

val _ = fread (buf, Array.length buf, file)

val _ = fclose file

val _ = printAry buf
