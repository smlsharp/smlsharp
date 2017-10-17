ListPair.appEq ignore ([1, 2, 3, 4, 5, 6], [10, 40, 50, 50])

(* 2014-01-26 ohori
 コンパイラがBug.Bug例外終了．

より簡単な例：
ignore (1,2)

これは，DatatypeCompilerのバグ．DatatypeCompilerで，primitiveが複数引数の場合，
レコード引数の分解（またはη拡張）が必要．この判定を引数の型で行なっていたが，
多相型のプリミティブではレコード型にインスタンス化される可能性があり，判定を誤っている．

2014-01-26 ohori 修正．
*)

