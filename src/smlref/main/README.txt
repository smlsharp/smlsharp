このディレクトリには、src/compiler/compilePhase/analyzefiles/ に実装さ
れているSMLソースコード集合の定義・参照関係分析フェーズの結果を格納し
たデータベースのデータを使用する種々の補助関数が定義されている。

* src/compiler/compilePhase/analyzefiles/の定義・参照関係分析フェーズ
の起動例

./src/compiler/smlsharp -Bsrc -A[dbname=smlsharp] [-dprintInfo=yes] ./src/compiler/smlsharp.smi

-Adbname=smlsharp 使用するPostgreSQLデータベース名。-Aのみ指定すると
環境変数SMLSHARP_SMLREFDBを参照する。

-dprintInfo=yesで、発行するSQLコマンドをダンプ。ただし、４８MB程度の
テキストファイルを出力。


* smlref-mode.el  sml-modeのサポートライブラリ
使用法：
 (setq sml-mode-hook '(lambda ()
     (load-library "smlref-mode.el")
     ...
    )
  )
などを.emacsに追加

キーバインド：
(global-set-key "\C-x\C-d" 'findDef) ; 現在のポイントの名前の定義を探し、別bufferに表示
(global-set-key "\C-x\C-r" 'findRef) ; 現在のポイントの名前の参照位置を探し、別bufferに表示

sml-ref-mode 参照リストバッファのメジャーモード：
(local-set-key "\C-M" 'open-ref-point)
を定義。その行のファイルをopenし、参照位置に移動

* SMLRef 
 smlref-mode.el が使用するコマンド。
現在、smlref-mode.elに
(defvar sml-ref-command
  "/home/ohori/share/HG/smlsharp/smlsharp/src/smlref/main/SMLRef")
とハードコードしてある。

* DBSchema.o
便宜上、以下を直接参照：
DBSchema.o: \
 ../../compiler/compilePhases/analyzefiles/main/DBSchema.sml \
 ../../compiler/compilePhases/analyzefiles/main/DBSchema.smi

* Log.sml
SMLRefコマンドデバッグのためのログファイル。現在、すべてのSMLRefコマンドの結果を、
AnalyzeFiles.analyzeFilesが設定したbaseDir下に SMLRef.log ファイルが書き込まれる。

* GenReuireDecls
AnalyzeFiles.analyzeFiles結果を分析する種々の試験的な関数。
コマンドには使用されていない。


