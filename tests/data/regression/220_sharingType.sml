signature S =
sig
  type t
  type s
  sharing type t = s
end

structure S : S =
struct
  datatype t = D of int
  datatype s = E of int
end

(*
2012-07-12

Error:
  (name evaluation 220) Signature mismatch (datatype): S.t(2)

この形のsignatureを持ったstructureは存在し得ない。
definitionの上では許されているようだが、実体が存在しないものを受け入れるかどうか仕様を確認しないといけない。
*)

(*
2012-07-19 ohori
This is the same as 212_wheretype.sml;
this is the feature of SML#.
*)

(*
2017-08-07 katsu
そもそも最初の問題提起がおかしい．
この形のsignatureを持ったstructureは存在する．
structure S : S =
struct
  datatype t = D of int
  type s = t
end
上記のコードはSMLの定義上signature mismatchを起こす．
*)
