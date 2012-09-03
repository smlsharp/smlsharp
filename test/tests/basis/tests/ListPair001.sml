(*
test cases for ListPair structure.
*)

val zip00 = ListPair.zip ([] : string list, [] : int list);
val zip01 = ListPair.zip ([] : string list, [1]);
val zip10 = ListPair.zip (["a"], [] : int list);
val zip11 = ListPair.zip (["a"], [1]);
val zip12 = ListPair.zip (["a"], [1, 2]);
val zip21 = ListPair.zip (["a", "b"], [1]);
val zip22 = ListPair.zip (["a", "b"], [1, 2]);
val zip33 = ListPair.zip (["a", "b", "c"], [1, 2, 3]);

val unzip0 = ListPair.unzip ([] : (string * int) list);
val unzip1 = ListPair.unzip [("a", 1)];
val unzip2 = ListPair.unzip [("a", 1), ("b", 2)];

val appFun = fn (x, y) => print (x ^ y);
val app00 = ListPair.app appFun ([], []);
val app01 = ListPair.app appFun ([], ["x"]);
val app10 = ListPair.app appFun (["a"], []);
val app11 = ListPair.app appFun (["a"], ["x"]);
val app12 = ListPair.app appFun (["a"], ["x", "y"]);
val app21 = ListPair.app appFun (["a", "b"], ["x"]);
val app22 = ListPair.app appFun (["a", "b"], ["x", "y"]);
val app33 = ListPair.app appFun (["a", "b", "c"], ["x", "y", "z"]);

val mapFun = fn (x, y) => (x + 1) * y;
val map00 = ListPair.map mapFun ([], []);
val map01 = ListPair.map mapFun ([], [7]);
val map10 = ListPair.map mapFun ([1], []);
val map11 = ListPair.map mapFun ([1], [7]);
val map12 = ListPair.map mapFun ([1], [7, 8]);
val map21 = ListPair.map mapFun ([1, 2], [7]);
val map22 = ListPair.map mapFun ([1, 2], [7, 8]);
val map33 = ListPair.map mapFun ([1, 2, 3], [7, 8, 9]);

val foldlFun = fn (x, y, xs) => x :: y :: xs;
val foldl00 = ListPair.foldl foldlFun [] ([] : int List.list, []);
val foldl01 = ListPair.foldl foldlFun [] ([], [7]);
val foldl10 = ListPair.foldl foldlFun [] ([1], []);
val foldl11 = ListPair.foldl foldlFun [] ([1], [7]);
val foldl12 = ListPair.foldl foldlFun [] ([1], [7, 8]);
val foldl21 = ListPair.foldl foldlFun [] ([1, 2], [7]);
val foldl22 = ListPair.foldl foldlFun [] ([1, 2], [7, 8]);
val foldl33 = ListPair.foldl foldlFun [] ([1, 2, 3], [7, 8, 9]);

val foldrFun = fn (x, y, xs) => x :: y :: xs;
val foldr00 = ListPair.foldr foldrFun [] ([] : int List.list, []);
val foldr01 = ListPair.foldr foldrFun [] ([], [7]);
val foldr10 = ListPair.foldr foldrFun [] ([1], []);
val foldr11 = ListPair.foldr foldrFun [] ([1], [7]);
val foldr12 = ListPair.foldr foldrFun [] ([1], [7, 8]);
val foldr21 = ListPair.foldr foldrFun [] ([1, 2], [7]);
val foldr22 = ListPair.foldr foldrFun [] ([1, 2], [7, 8]);
val foldr33 = ListPair.foldr foldrFun [] ([1, 2, 3], [7, 8, 9]);

val existsFun = fn (x, y) => x mod 2 = 0 andalso y mod 3 = 0;
val exists00 = ListPair.exists existsFun ([], []);
val exists01__f = ListPair.exists existsFun ([], [7]);
val exists01__t = ListPair.exists existsFun ([], [9]);
val exists10_f_ = ListPair.exists existsFun ([1], []);
val exists10_t_ = ListPair.exists existsFun ([2], []);
val exists11_f_f = ListPair.exists existsFun ([1], [7]);
val exists11_f_t = ListPair.exists existsFun ([1], [9]);
val exists11_t_t = ListPair.exists existsFun ([2], [9]);
val exists12_f_ff = ListPair.exists existsFun ([1], [7, 8]);
val exists12_f_tf = ListPair.exists existsFun ([1], [9, 8]);
val exists12_t_tf = ListPair.exists existsFun ([2], [9, 8]);
val exists21_ff_f = ListPair.exists existsFun ([1, 3], [7]);
val exists21_ff_t = ListPair.exists existsFun ([1, 3], [9]);
val exists21_tf_f = ListPair.exists existsFun ([2, 3], [7]);
val exists21_tf_t = ListPair.exists existsFun ([2, 3], [9]);
val exists22_ff = ListPair.exists existsFun ([1, 3], [7, 8]);
val exists22_ft = ListPair.exists existsFun ([1, 2], [7, 9]);
val exists22_tf = ListPair.exists existsFun ([2, 3], [6, 8]);
val exists22_tt = ListPair.exists existsFun ([2, 4], [6, 9]);

val allFun = fn (x, y) => x mod 2 = 0 andalso y mod 3 = 0;
val all00 = ListPair.all allFun ([], []);
val all01__f = ListPair.all allFun ([], [7]);
val all01__t = ListPair.all allFun ([], [9]);
val all10_f_ = ListPair.all allFun ([1], []);
val all10_t_ = ListPair.all allFun ([2], []);
val all11_f_f = ListPair.all allFun ([1], [7]);
val all11_f_t = ListPair.all allFun ([1], [9]);
val all11_t_t = ListPair.all allFun ([2], [9]);
val all12_f_ff = ListPair.all allFun ([1], [7, 8]);
val all12_f_tf = ListPair.all allFun ([1], [9, 8]);
val all12_t_tf = ListPair.all allFun ([2], [9, 8]);
val all21_ff_f = ListPair.all allFun ([1, 3], [7]);
val all21_ff_t = ListPair.all allFun ([1, 3], [9]);
val all21_tf_f = ListPair.all allFun ([2, 3], [7]);
val all21_tf_t = ListPair.all allFun ([2, 3], [9]);
val all22_ff = ListPair.all allFun ([1, 3], [7, 8]);
val all22_ft = ListPair.all allFun ([1, 2], [7, 9]);
val all22_tf = ListPair.all allFun ([2, 3], [6, 8]);
val all22_tt = ListPair.all allFun ([2, 4], [6, 9]);
