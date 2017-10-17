signature PSIG =
sig
  type t
end;
signature FSIG =
sig
  type s
end;

functor FOpaq(S : PSIG) :> FSIG = 
struct
  type s = S.t
end;

(*
2012-7-13 hikaru

This causes a BUG at functor.
[BUG] NameEval: uncaught exception in NameEval
*)

(*
2012-7-18 ohori
Fixed by 4313:85eaf8fc0756.
This is a subtle bug due to the following.
We fist note the following.
1. When a functor has an argument structure containing "type foo",
   then the compiler convert the type foo (foo appiled to nil) to 
   a type variable and abstracted.
2. When that functor is applied, the abstracted type 'foo is instantiated
   and a type definition type foo = \tau is generated.
3. When a structure has a constraint with an opaque signature, then 
    "type foo = \tau" is converted to a new datatype and remember
    "\tau" in the runtimeTy field.
Howver, when a functor body has an opaque signature containing 
  "type foo" 
in the argument signature, we need to produce a new datatype 
with its runtimeTy information for compilation, which is impossible 
since its runtimeTy is determined in future application.
This is the source of this bug.

To deal with this situation, I refined the definition of runtimeTy to be
   datatype runtimeTy
     = BUILTINty of BuiltinType.ty
     | LIFTEDty of tvar  
The latter is to refer to the future instantiation of tvar.
*)
