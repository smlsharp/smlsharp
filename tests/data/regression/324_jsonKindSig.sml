structure Template 
:> sig
    val g : ['a, 'b#reify. ('a * 'b) * 'a -> int]
  end
=
struct
  fun ('a, 'b#reify) g ((filler, value:'b),a)= 1:int
end 


(* 2016-06-05 ohori
カインド制約があるシグネチャが型エラーを起こすことがある．

# use "324_jsonKindSig.sml";
324_jsonKindSig.sml:1.10-8.2 Error:
  (type inference 011d) signature mismatch at 
    inferred type: ('FRR('RIGID) * 'FRN#json) * 'FRM -> int
  type annotation: ('FRR('RIGID) * 'FRQ('RIGID)#json) * 'FRR('RIGID) -> int
*)

(*
2016-07-14 katsu
このチェンジセットの時点でこの問題は発生しない

  changeset:   7547:1183956ca6a8
  user:        tsasaki
  date:        Thu Jul 14 11:45:24 2016 +0900
  coerceTyがconstraintを返すように変更

*)
