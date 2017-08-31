signature S1 = sig end
signature S2 = sig end;

(*
2012-07-09 endom

printerがおかしいために、下記のように出力結果が改行されない。
signature S1 =
  sig
  endsignature S2 =
  sig
  end
*)

(* 2012-7-19 ohori 
This is the same as 211_printSignatureAnd.sml, and has been
fixed.
*)
