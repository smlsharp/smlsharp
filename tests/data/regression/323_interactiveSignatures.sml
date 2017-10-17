structure L = List : LIST;

(*
2016-04-02 ohori

signature mismatch errors in the interactive loop.

datatype型の参照がある，GENERAl, INTEGER, WORD等のシグネチャすべてで起きる．

以下の方法で解決．
basis.smiのシグネチャのインクルードをやめ，シグネチャをprelude.smiをsignatures.smiとしてまとめ，
SimpleMainで環境を作るとき，basis.smiを読み込んだ環境で，さらにsignatures.smiを読み込むように変更．
*)
(*
2016-07-15 katsu
私の記憶が確かなら，メールでの議論で上記の対応では不十分であることが分かり，
より詳細な分析と対応を行ったはず．たぶん以下のメール．

Date: Sun, 03 Apr 2016 17:16:23 +0900 (JST)
Message-Id: <20160403.171623.1943004671851390444.ohori@riec.tohoku.ac.jp>
To: katsu@riec.tohoku.ac.jp
Cc: smlsharp-dev@ml.riec.tohoku.ac.jp
Subject: Re: [smlsharp-dev: 239] Re: SML# 3.0 bug（深刻）
From: Atsushi Ohori <ohori@riec.tohoku.ac.jp>

上野さん，

インクルード関連，コードを確認してみました．

 >> includeの意味は，includeが書かれたファイルを_requireするとincludeを
 >> _requireに置き換えて展開する，というもののはずなので，従って，
 >> _requireが順不同なのと同様に，includeも順不同のはずで，実際バッチ
 >> コンパイルではそのように振舞っています．

分割コンパイルの場合ではそうですが，インタラクティブモードの場合これで
はすまず，インクルードを含むrequire集合から対話型の評価環境を作る必要
があり，ここで謎のエラーの原因のようです．

処理は，おおよそ以下のようになっているようです．

１ ローダがincludeを含むrequireをすべて読み込みrequireの環境と，すべて
  のインタフェイスファイルのprovide宣言をconctenatesしたprovide宣言列
  を生成する
２ requireの環境を評価しprovide宣言列のための評価環境を作る．
３ このprovide用評価環境でprovide宣言列を評価し，対話型プログラムを評
   価するための環境１を作る．
４ （現在の実装では）２のprovide用評価環境でシグネチャを評価し，環境２を作る
５ 環境１と環境２をマージしを返す．

３のprovide宣言列は，当然，シーケンシャルに評価されるます．この評価
は，分割コンパイルの時のコードとのチェックのためではなく，あたかもコー
ド実体が評価された結果と同様の効果をもつ環境を作っています．そこで，こ
のprovide宣言列の評価では，依存関係をまもる必要があります．依存関係が
崩れると，requireを評価したprovide用評価環境のセマンティックオブジェク
トが結果にあらわれてしまい，謎のエラーがでます．

また，４の処理は間違いで，シグネチャを評価は，provide用評価環境を環境
１をオーバライドしたものを使うべきです．（私が書いたコードです．
当時は，以上のことが見とうせていなかったためと思います．）

対策ですが，４の処理は修正しました．これで，シグネチャ問題はなくなりま
す．

provide宣言列の問題は，provide宣言列ををつくらない方法があるかもしれま
せんが，作りこみが必要であること，また，対話型モードはコンパイラしか使
わないので，依存関係をみたすようにソートして対応することにするのが，よ
いとおもいます．interactive unitをプリントするとstructure間の依存関係
がわかるので，それに従って，bassis.smiのエントリーをソートしました．

以上をコミットします．確認とテストが必要です．

        大堀 淳
*)
