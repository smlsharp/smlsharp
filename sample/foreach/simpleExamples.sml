(*
I 配列のデータ並列処理．（構文にwhere句が無い場合）

   _foreach <id> in <arrayExp> 
   with <pat>
   do <iteratorExp> 
   while <predExp>
   end

与えられた <arrayExp> の配列の各要素のインデックス
を <id> に束縛し，データ並列で <iteratorExp> の値を計算し，
配列を関数的に更新する．<iteratorExp>計算の際，配列の値と
新しく計算された値を参照することが可能．この目的のために，
<iteratorExp> 式では，型 
  {value:int -> 'a, newValue:int -> 'a, size:int}
型の値に束縛されたパターン <pat> が参照できる．
すべてのインデックスに対するデータ並列計算が終了すると，
各インデックスに対して<predExp>式が評価され，要素がひとつでも
trueを返せば，<iteratorExp>の計算が繰り替えされる．

各要素の型は以下の通り．
<arrayExp> : 'a array
<id> : int
<pat> : {value:int -> 'a, newValue:int -> 'a, size:int}
<iteratorExp> : 'a - > 'a （この中で，<pat>が束縛される）
<predExp> : 'a - > bool （この中で，<pat>が束縛される）

各配列要素の現在の値をXiとし，新しい値をnewXiとすると，この
構文は，
   newXi = <iteratorExp> (X1,..., Xn, newXj,..., newXk)
の計算を
   <predExp>(X1,..., Xn, newX1,..., newXn)
がすべてfalseになるまで繰り返す構文である．ここで，newXj,..., newXk
は，newXiの計算に依存しない要素の計算．
      
*)

(* 配列要素へのデータ並列マップ
   mapArray : ['a. ('a -> 'a) -> 'a array -> 'a array]
 *)
fun mapArray f A = 
   _foreach id in A with {value, newValue, size}
   do f (value id) while false
   end

(* ガウスサイデル法 
  Gauss_Sidel : real -> real array array * real array -> real array
*)
fun Gauss_Sidel epsilon (a, b) = 
    let
      val size = Array.length a 
      val x = Array.array(size, 0.0)
      fun A (i,j) = Array.sub(Array.sub(a,i), j)
      fun Ai i = Array.sub(a,i)
      fun B i = Array.sub(b,i)
      fun sumAX x newx i = 
          let
            fun X j = if j < i then newx j else  x j
            fun each j R = 
                if j >= size then R 
                else if j = i then each (j+1) R
                else each (j+1) (A(i,j) * X(j) + R)
          in
            each 0 0.0
          end
    in
      _foreach i in x with {value=X, newValue=newX, size}
      do (B(i) - sumAX X newX i) / A(i,i)
      while Real.abs(newX(i) - X(i)) > epsilon
      end
    end

(*
I 再帰的データのデータ並列処理．（構文にwhere句がある場合）

   _foreach <id> in <dataExp> 
   where <setupExp>
   with <pat>
   do <iteratorExp> 
   while <predExp>
   end

1．初期化処理

ユーザが指定した<setupExp>を使い，与えられた <dataExp> データ
の各ノード（リストのnilやツリーのemptyも一ノード）を，
名前（抽象データ型indexの値）から，indexを子ノードとして含む値
へのマップ（配列）に変換する．インデックス値を名前Xiとする方程式
    Xi = C(Xj,...,Xk)
がつくられる．<setupExp>は，この変換のために，
   default : 'para,
   initialize : ('para -> index) -> 'seq -> index.
   finalize : (index -> 'para) -> index -> 'seq,
   size : int
の各値（関数）を指定する．initializeは，変換後のノード値にインデクス
を割りてる 関数を受け取り，データを再帰的にたどって，再帰的データの
各ノードを変換する関数．返り値のindexは，再帰構造をたもつために使用される．
たとえば，リスト型
 datatype 'a list = nil | :: of 'a * 'a list
を
*)
   datatype 'a LIST = NIL | CONS of 'a * index
(*
に型に変換したい場合，以下の関数
  initialize : ['a. ('a LIST -> index) -> 'a list -> index]
*)
  fun initialize toLIST l =
      case l of
        nil => toLIST NIL
      | h :: tail => 
        let
          val TAIL = initialize toLIST tail
        in
          toLIST (CONS(h, TAIL))
        end
(*
をinitializeのフィールドに指定すればよい．この初期化のより，
例えば，リスト型の値 1::2::3::nilは
   X1 = CONS(1, X2)
   X2 = CONS(2, X3)
   X3 = CONS(3, X4)
   X4 = NIL
の方程式の表現に変換される．

finalizeは，indexを用いた方程式表現を，indexを展開し，もとの
データに変換すための関数である．例えば上記リストの場合，
ユーザは，以下の関数をfinilieのフィールドに指定すればよい．
  finalize : ['a. (index -> 'a LIST) -> index -> 'a list]
*)
fun finalize toData i =
    case toData i of
      NIL => nil
    | CONS(head, tail) => head :: (finalize toData tail)
(*
  sizeは，再帰的データの要素数を返す関数である．ただし，リストの
nilやツリーのemptyも1と数える．リストの場合は，以下のような
定義である．
  size : 'a list -> int
*)
fun size nil = 1
  | size (h::t) = 1 + size t
(*
ユーザは，これら関数を用いて，<setUp>式を以下のように定義する
*)
val param = 
    {
     default = NIL,
     finalize = finalize,
     initialize = initialize,
     size = size
    }
  : {default: 'a LIST,
     finalize: (index -> 'a LIST) -> index -> 'a list,
     initialize: ('a LIST -> index) -> 'a list -> index,
     size: 'a list -> int};

(*

2．データ並列計算．

各ノードに関して，名前を <id> に束縛し，対応する値を <iteratorExp> 
によって新しい値にデータ並列で更新する．配列同様，<iteratorExp>計算の際，
配列の値と新しく計算された値を参照することが可能．
この目的のために，<iteratorExp> 式では，型 
  {value:index -> 'para, newValue:index -> 'para, size:int}
型の値に束縛されたパターン <pat> が参照できる．
すべてのインデックスに対するデータ並列計算が終了すると，
各インデックスに対して<predExp>式が評価され，要素がひとつでも
trueを返せば，<iteratorExp>の計算が繰り替えされる．

これは，データを表す方程式を並列変換する計算である．
たとえば，1::2::3::nil を 2::3::4::nilに変換する
計算は
   X1 = CONS(1, X2)
   X2 = CONS(2, X3)
   X3 = CONS(3, X4)
   X4 = NIL
を
   X1 = CONS(2, X2)
   X2 = CONS(3, X3)
   X3 = CONS(4, X4)
   X4 = NIL
に変換する計算であり，各ノードは，head + 1を実行すればよい．
この計算は，
*)
   _foreach id in [1,2,3] where param
   with {value, ...}
   do case (value id) of
        NIL => NIL
      | CONS(i, TAIL) => CONS (i + 1, TAIL)
   while false
   end;
(* 勿論，高階のマップ関数
   parallemMap : ['a. ('a -> 'a) -> 'a list -> 'a list]
も，単に関数抽象するだけで，定義できる．*)
   fun parallemMap f L  = 
   _foreach id in L where param
   with {value, ...}
   do case (value id) of
        NIL => NIL
      | CONS(head, TAIL) => CONS (f head, TAIL)
   while false
   end;

(* 変数Xiを参照し，さらに，繰り返し判定で新しい値を参照すれば，
  データ並列scanなどの関数も宣言的に定義可能．そのために，
  中間データ構造とparamを以下のように定義する．
*)

datatype 'a parList
  = NIL
  | CELL of {head : 'a, cham: index, tail: index}
fun initialize toLIST l =
    case l of
      nil => toLIST NIL
    | h :: tail => 
      let
        val TAIL = initialize toLIST tail
      in
        toLIST (CELL {head = h, cham=TAIL, tail=TAIL})
      end
fun finalize toData i =
    case toData i of
      NIL => nil
    | CELL{head, tail,...} => head :: (finalize toData tail)
val param = {default = NIL,finalize = finalize,
             initialize = initialize,
             size = size}
(* この chamフィールド，データ並列計算で知られるpointer jumping
を行うための"cham pointer"の表現である．この関数は，リスト要素んｐ
O(log n)回のデータ並列ステップでscamを計算する関数である．
*)
fun sufixsum L = 
   _foreach id in L where param
   with {value, newValue, ...}
   do case (value id) of
        NIL =>  NIL
      | CELL {head =i, tail, cham} =>
        (case value cham of 
           CELL {head, tail=_, cham} =>
           CELL {head = i + head,  cham = cham, tail = tail}
         | NIL =>  CELL {head =i, cham = cham, tail = tail}
        )
    while case (newValue id) of
            CELL {head =i, cham, tail} =>
            (case newValue cham of NIL => false | _ => true)
          | _ => false
    end

