(*
 * @author YAMATODANI Kiyoshi
 * @copyright 2010, Tohoku University.
 *)

(* This file loads source files required to compile Script.sml.
 *)
use "../../../smlnj-lib/Util/lib-base-sig.sml";
use "../../../smlnj-lib/Util/lib-base.sml";
use "../../../smlnj-lib/Util/ord-key-sig.sml";
use "../../../smlnj-lib/Util/ord-set-sig.sml";
use "../../../smlnj-lib/Util/ord-map-sig.sml";
use "../../../smlnj-lib/Util/list-set-fn.sml";
use "../../../smlnj-lib/Util/list-map-fn.sml";
use "../../../smlnj-lib/RegExp/regexp-lib.use";
structure RegExp =
    RegExpFn(structure P = AwkSyntax structure E = BackTrackEngine);
