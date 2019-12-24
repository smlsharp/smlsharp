
infix - :=
val op - = SMLSharp_Builtin.Int32.sub_unsafe
val op := = SMLSharp_Builtin.General.:=
val ! = SMLSharp_Builtin.General.!

val r = ref {a=((1,2),(3,4)), b=((5,6),(7,8)), c=((9,1),(2,3)), d=((4,5),(6,7))}
fun f g = r := g (!r)
fun r 0 = ()
  | r n = (f (fn z as {a=((a,b),(c,d)),...} => z # {c = ((d,c),(b,a))});
           r (n-1))

val _ = r 10000000

(*
2016-07-29 katsu

This sometimes causes segmentation fault if this runs with SMLSHARP_HEAPSIZE=1M.
*)
(*
2016-07-29 katsu

(1) iはstatic allocateされる．従ってiのヘッダーのFLAG_SKIPは立っている．
(2) レコードアップデート z # {a = ...} で，新しくアロケートされたレコードに
iの内容がヘッダも込みでコピーされる．このとき，iのヘッダーのFLAG_SKIPも
コピーされてしまう．従って，新しいレコードは実行時にアロケートされたにも
かかわらずFLAG_SKIPを持つことになる．このため，GCは新しいレコードとその子
要素をトレースしない．結果として新しいレコードはライブなのに回収されてしまう．

*)
