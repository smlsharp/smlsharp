(*
test cases for List structure.
*)

val null1 = List.null ([] : int List.list);
val null2 = List.null [1];

val length1 = List.length [];
val length2 = List.length [1];
val length3 = List.length [1, 2];

val append1 = List.@ ([], [] : int List.list);
val append2 = List.@ ([1], []);
val append3 = List.@ ([], [1]);
val append4 = List.@ ([1, 2], []);
val append5 = List.@ ([], [1, 2]);
val append6 = List.@ ([1], [2]);
val append7 = List.@ ([1, 2], [2]);
val append8 = List.@ ([1, 2], [2, 3]);
val append9 = List.@ ([1], [2, 3]);

val hd1 = List.hd [] handle List.Empty => 1;
val hd2 = List.hd [1];
val hd3 = List.hd [1, 2];

val tl1 = List.tl [] handle List.Empty => [1];
val tl2 = List.tl [1];
val tl3 = List.tl [1, 2];

val last1 = List.last [] handle List.Empty => 1;
val last2 = List.last [1];
val last3 = List.last [1, 2];

val getItem1 = List.getItem ([] : int List.list);
val getItem2 = List.getItem [1];
val getItem3 = List.getItem [1, 2];

val nth00 = List.nth ([], 0) handle General.Subscript => 1;
val nth0m1 = List.nth ([], ~1) handle General.Subscript => 1;
val nth01 = List.nth ([], 1) handle General.Subscript => 1;
val nth10 = List.nth ([1], 0);
val nth11 = List.nth ([2], 1) handle General.Subscript => 1;
val nth1m1 = List.nth ([2], ~1) handle General.Subscript => 1;
val nth20 = List.nth ([1, 2], 0);
val nth21 = List.nth ([1, 2], 1);
val nth22 = List.nth ([1, 2], 2) handle General.Subscript => 3;

val take00 = List.take ([] : int List.list, 0);
val take0m1 = List.take ([], ~1) handle General.Subscript => [3];
val take01 = List.take ([], 1) handle General.Subscript => [3];
val take10 = List.take ([1], 0);
val take11 = List.take ([2], 1);
val take1m1 = List.take ([2], ~1) handle General.Subscript => [3];
val take12 = List.take ([2], 2) handle General.Subscript => [3];
val take20 = List.take ([1, 2], 0);
val take21 = List.take ([1, 2], 1);
val take22 = List.take ([1, 2], 2);
val take23 = List.take ([1, 2], 3) handle General.Subscript => [3];

val drop00 = List.drop ([] : int List.list, 0);
val drop0m1 = List.drop ([], ~1) handle General.Subscript => [3];
val drop01 = List.drop ([], 1) handle General.Subscript => [3];
val drop10 = List.drop ([1], 0);
val drop11 = List.drop ([2], 1);
val drop1m1 = List.drop ([2], ~1) handle General.Subscript => [3];
val drop12 = List.drop ([2], 2) handle General.Subscript => [3];
val drop20 = List.drop ([1, 2], 0);
val drop21 = List.drop ([1, 2], 1);
val drop22 = List.drop ([1, 2], 2);
val drop23 = List.drop ([1, 2], 3) handle General.Subscript => [3];

val rev0 = List.rev ([] : int List.list);
val rev1 = List.rev [1];
val rev2 = List.rev [1, 2];
val rev3 = List.rev [1, 2, 3];

val concat0 = List.concat ([] : int List.list List.list);
val concat10 = List.concat ([[]] : int List.list List.list);
val concat200 = List.concat ([[], []] : int List.list List.list)
val concat11 = List.concat [[1]];
val concat201 = List.concat [[], [1]];
val concat210 = List.concat [[1], []];
val concat211 = List.concat [[1], [2]];
val concat222 = List.concat [[1, 2], [3, 4]];
val concat3303 = List.concat [[1, 2, 3], [], [7, 8, 9]];
val concat3333 = List.concat [[1, 2, 3], [4, 5, 6], [7, 8, 9]];

val revAppend00 = List.revAppend ([], [] : int List.list);
val revAppend01 = List.revAppend ([], [1]);
val revAppend10 = List.revAppend ([1], []);
val revAppend11 = List.revAppend ([1], [2]);
val revAppend20 = List.revAppend ([1, 2], []);
val revAppend02 = List.revAppend ([], [1, 2]);
val revAppend22 = List.revAppend ([1, 2], [3, 4]);
val revAppend33 = List.revAppend ([1, 2, 3], [4, 5, 6]);

val appFun = fn x => print x;
val app0 = List.app appFun [];
val app1 = List.app appFun ["a"];
val app2 = List.app appFun ["a", "b"];
val app3 = List.app appFun ["a", "b", "c"];

val mapFun = fn x => x + 1;
val map0 = List.map mapFun [];
val map1 = List.map mapFun [1];
val map2 = List.map mapFun [1, 2];
val map3 = List.map mapFun [1, 2, 3];

val mapPartialFun = fn x => if 0 < x then SOME x else NONE;
val mapPartial0 = List.mapPartial mapPartialFun [];
val mapPartial10 = List.mapPartial mapPartialFun [0];
val mapPartial11 = List.mapPartial mapPartialFun [1];
val mapPartial200 = List.mapPartial mapPartialFun [0, 0];
val mapPartial201 = List.mapPartial mapPartialFun [0, 1];
val mapPartial210 = List.mapPartial mapPartialFun [1, 0];
val mapPartial211 = List.mapPartial mapPartialFun [1, 2];
val mapPartial3010 = List.mapPartial mapPartialFun [0, 1, 0];
val mapPartial3101 = List.mapPartial mapPartialFun [1, 0, 2];
val mapPartial3111 = List.mapPartial mapPartialFun [1, 2, 3];

val findFun = fn x => (x mod 2) = 0;
val find0 = List.find findFun [];
val find10 = List.find findFun [1];
val find11 = List.find findFun [0];
val find200 = List.find findFun [1, 3];
val find201 = List.find findFun [1, 2];
val find210 = List.find findFun [0, 1];
val find211 = List.find findFun [2, 4];
val find3101 = List.find findFun [2, 1, 4];
val find3010 = List.find findFun [1, 2, 3];
val find3111 = List.find findFun [2, 4, 6];

val filterFun = fn x => (x mod 2) = 0;
val filter0 = List.filter filterFun [];
val filter10 = List.filter filterFun [1];
val filter11 = List.filter filterFun [0];
val filter200 = List.filter filterFun [1, 3];
val filter201 = List.filter filterFun [1, 2];
val filter210 = List.filter filterFun [0, 1];
val filter211 = List.filter filterFun [2, 4];
val filter3101 = List.filter filterFun [2, 1, 4];
val filter3010 = List.filter filterFun [1, 2, 3];
val filter3111 = List.filter filterFun [2, 4, 6];

val partitionFun = fn x => (x mod 2) = 0;
val partition0 = List.partition partitionFun [];
val partition10 = List.partition partitionFun [1];
val partition11 = List.partition partitionFun [0];
val partition200 = List.partition partitionFun [1, 3];
val partition201 = List.partition partitionFun [1, 2];
val partition210 = List.partition partitionFun [0, 1];
val partition211 = List.partition partitionFun [2, 4];
val partition3101 = List.partition partitionFun [2, 1, 4];
val partition3010 = List.partition partitionFun [1, 2, 3];
val partition3111 = List.partition partitionFun [2, 4, 6];

val foldlFun = fn (x, xs) => x :: xs;
val foldl0 = List.foldl foldlFun [] ([] : int list);
val foldl1 = List.foldl foldlFun [] [1];
val foldl2 = List.foldl foldlFun [] [1, 2];
val foldl3 = List.foldl foldlFun [] [1, 2, 3];

val foldrFun = fn (x, xs) => x :: xs;
val foldr0 = List.foldr foldrFun [] ([] : int list);
val foldr1 = List.foldr foldrFun [] [1];
val foldr2 = List.foldr foldrFun [] [1, 2];
val foldr3 = List.foldr foldrFun [] [1, 2, 3];

val existsFun = fn x => (x mod 2) = 0;
val exists0 = List.exists existsFun [];
val exists10 = List.exists existsFun [1];
val exists11 = List.exists existsFun [0];
val exists200 = List.exists existsFun [1, 3];
val exists201 = List.exists existsFun [1, 2];
val exists210 = List.exists existsFun [0, 1];
val exists211 = List.exists existsFun [2, 4];
val exists3101 = List.exists existsFun [2, 1, 4];
val exists3010 = List.exists existsFun [1, 2, 3];
val exists3111 = List.exists existsFun [2, 4, 6];

val allFun = fn x => (x mod 2) = 0;
val all0 = List.all allFun [];
val all10 = List.all allFun [1];
val all11 = List.all allFun [0];
val all200 = List.all allFun [1, 3];
val all201 = List.all allFun [1, 2];
val all210 = List.all allFun [0, 1];
val all211 = List.all allFun [2, 4];
val all3101 = List.all allFun [2, 1, 4];
val all3010 = List.all allFun [1, 2, 3];
val all3111 = List.all allFun [2, 4, 6];

val tabulateFun = fn x => x;
val tabulate0 = List.tabulate (0, tabulateFun);
val tabulate1 = List.tabulate (1, tabulateFun);
val tabulate2 = List.tabulate (2, tabulateFun);
val tabulatem1 = List.tabulate (~1, tabulateFun) handle General.Size => [999];

(*
val collateFun =
    fn (x, y) =>
       if x < y
       then General.LESS
       else if x = y then General.EQUAL else General.GREATER;
val collate00 = List.collate collateFun ([], []);
val collate01 = List.collate collateFun ([], [1]);
val collate10 = List.collate collateFun ([1], [0]);
val collate11L = List.collate collateFun ([1], [2]);
val collate11E = List.collate collateFun ([1], [1]);
val collate11G = List.collate collateFun ([2], [1]);
val collate12L =  List.collate collateFun ([1], [1, 2]);
val collate12G =  List.collate collateFun ([2], [1, 2]);
val collate21L =  List.collate collateFun ([1, 2], [2]);
val collate21G =  List.collate collateFun ([1, 2], [1]);
val collate22L1 = List.collate collateFun ([2, 1], [3, 1]);
val collate22L2 = List.collate collateFun ([1, 2], [1, 3]);
val collate22E = List.collate collateFun ([1, 2], [1, 2]);
val collate22G1 = List.collate collateFun ([3, 1], [2, 1]);
val collate22G2 = List.collate collateFun ([1, 3], [1, 2]);
*)