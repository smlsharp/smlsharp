structure A = struct datatype foo = F of int end :> sig datatype foo = F of int end;
A.F;

(* 対話モードで、以下のバグとなる。
  Bug.Bug: toReifiedTy: CONSTRUCTty at src/compiler/extensions/reflection/main/TyToReifiedTy.sml:162.38(7006)
*)
