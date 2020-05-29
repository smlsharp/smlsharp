fun f x = f x
val _ = f (fn {k,...} => k)

(*
2017-02-03 katsu

This causes BUG.

uncaught exception: Bug.Bug: getFieldsOfTy found unexpected:?X2#{k: ?X3...} at src/compiler/matchcompilation/main/MatchCompiler.sml:405


2019-05-23 ohori 
別なバグとなる。
none:~1.~1-~1.~1 Warning:
  (type inference
  065) dummy type variable(s) are introduced due to value restriction in: it
Bug.Bug: PolyTyElimination: analyzePat: TPPATRECORD at src/compiler/compilePhases/polytyelimination/main/PolyTyElimination.sml:17

2019-05-24 ohori 
PolyTyEliminationを修正。TPPATRECORDの型の処理にdummy type variableの処理を追加。おそらくこれでよかろう。

2019-05-24 ohori 
上記のMatchCompilerのバグに戻る。これも、dummy type variableのKINDフィールドから型を取得する処理を追加。
MatchCompilerのはじめての修正。（バグ修正ではなく、追加機能への対応。
*)
