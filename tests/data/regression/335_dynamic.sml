datatype 'a template = TEMPLATE of 'a * unit ptr ref * unit ptr ref

fun import jstr =
    let
      val dyn = JSON.import jstr
      val hdf = ref (Pointer.NULL ()) : unit ptr ref
      val cs = ref (Pointer.NULL ()) : unit ptr ref
    in      
      TEMPLATE (dyn, hdf, cs)
    end

fun decompose temp =
    case temp of
        TEMPLATE (dyn, hdf, cs) => (dyn, hdf, cs)

fun compose tuple = TEMPLATE tuple

;

val template = import "{\"name\":null, \"age\":null}"

val typedTemplate =
    let
      val (dyn, hdf, cs) = decompose template
    in
      compose
        (_json dyn as {name : string option, age : int option} JSON.dyn,
         hdf, cs)
    end

val str = SOME "Hanako"
val dynamicStr = JSON.toDynamic str
val jsonStr = JSON.dynamicToJson dynamicStr
fun viewFunStr (x : JSON.json) = str

val num = SOME 100
val dynamicNum = JSON.toDynamic num
val jsonNum = JSON.dynamicToJson dynamicNum

(* 2016-11-14 osaka

このファイルをSML#の対話環境にコピーする（useで読み込ませない）と，
最後の行のJSON.dynamicToJsonでsegmentation fault.

*)

(* 2016-11-14 katsu

fixed by
changeset:   7688:e4acd795cebb
user:        UENO Katsuhiro
date:        Mon Nov 14 22:06:19 2016 +0900
files:       smlsharp/src/runtime/dump.c
description:
  bugfix
*)
