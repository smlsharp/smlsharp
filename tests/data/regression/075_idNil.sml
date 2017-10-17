fun f (x:int list) = x
val _ = f nil

(*
2011-08-26 katsu

test3.sml:2.9-2.13 Error:
  (type inference 007) operator and operand don't agree
  operator domain: int(t0) list(t14)
  operand: ['a. 'a list(t14)]
*)

(*
2011-08-26 ohori

Fixed by adopting the following:

 >おそらく，必要なのは，unifyしない関数適用構文ではないかと思います．
 >
 >関数抽象側は引数に多相型を認めても，その型を環境に入れて処理を続ければ
 >よいだけなので，型推論上は問題ないと思いますし，type annotationが正し
 >ければその後のコンパイルにも影響ないはずです．
 >
 >問題なのは，関数適用でunifyするときの多相型の取り扱いと思います．
 >
 >この問題に対する簡単な対応のひとつは，unifyをせずに型のequality check
 >だけを行う関数適用構文を導入することです．
 >
 >さらに，この構文のhead positionを変数に限定し，かつその変数の型を関数型
 >に限定すれば，rank-1 や type instantiation の取り扱いとは独立して扱える
 >ようになると思います．
 >
 >具体的には，icexp に以下のような構文を追加．
 >
 >  ICAPPM_NOUNIFY of varInfo * icexp list * loc
 >
 >型付け規則は普通の関数適用と同様．
 >ただし，型推論のときにunifyを使わずに，型のequality checkのみを行う．

*)
