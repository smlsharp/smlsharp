(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

fun eval script =
    let
      val doOpen =
          DynamicBind.importSymbol "doOpen" : _import (string) -> int
    in
      doOpen "hoge"
    end;
val evalptr = eval : _export (string) -> int;
val _ = DynamicBind.exportSymbol ("eval", evalptr);

