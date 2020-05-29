_sql db => insert into #db.people (age) values (SOME 1)

(*
2013-8-26 hikaru saito

This causes a bug.

Unification fails (3)
int(t0[])
t127
EXVAR(SQL.Some) {int, FREEBTV(127)}
 {_tagof(int), _sizeof(int), $75(75), $76(76)}
 cast((("1", cast(contag(0wx0))), 1))
argTyList
(int(t0[]), t127)SQL.value(t24[])

newArgTyList
(t127, int(t0[]))SQL.value(t24[])


[BUG] StaticAnalysis:unification fail(3)

*)

(* 2013-08-31 ohori
5357:392027fb11b6 で修正．ConstantTermのsqlValueの誤り．
厄介な問題

        fun sqlValue (string as (_, dbiTy)) (exp, valueTy) =
            conTerm {con = toRC BT.VALUETPConInfo,
(* 2013-08-31 ohori bug 266_SQLInsertOption.sml; SQL.Som 1 がbug例外を起こす．
   このハンドコードは，脆弱．型変数の抽象の順序は，型に現れる順．
                     instTyList = [valueTy, dbiTy],
*)
                     instTyList = [dbiTy,valueTy],
                     arg = SOME (#1 (pairTerm (stringDBIPairTerm string,
                                               (exp, valueTy))))}

*)

(* 2013-09-21 ohori 
以下のエラーでコンパイラがアボート．
$ smllr  -c 266_SQLInsertOption.sml
smllr: /usr/local/src/llvm-3.3.src/include/llvm/Support/Casting.h:237: typename llvm::enable_if<llvm::is_same<Y, typename llvm::simplify_type<From>::SimpleType>, typename llvm::cast_retty<X, Y*>::ret_type>::type llvm::cast(Y* ) [with X = llvm::IntegerType, Y = llvm::Type]: Assertion `isa<X>(Val) && "cast<Ty>() argument of incompatible type!"' failed.
アボートしました
*)

(*
2014-01-26 katsu

The above errors do not occur on the latest LLVM backend.
*)
