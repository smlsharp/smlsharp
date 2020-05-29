val x = 1;
val y = x;
val x = 2;
(y,x);

(* 
2018-02-18
以下のバグを引き起こす
Bug.Bug: analyzeExp: TPEXVAR at src/compiler/compilePhases/polytyelimination/main/PolyTyElimination.sml:717
# 

この原因は，以下の組み合わせによる．
＊ externSetの管理をversion込で行っていないこと，
＊ val id = longid 宣言は，実際の外部変数を作らず，idの参照を静的に解決しているだけ．
例の場合，yは外部名 x.0 にコンパイルされ，次の x は新しx.1としてexportされる．
したがって，(x,y)に対して，
extern x.0
extern x.1
を出力する必要があるが，externSetのキーにversionがセットされていないため，
extern x.1
が出力されない．

*)
