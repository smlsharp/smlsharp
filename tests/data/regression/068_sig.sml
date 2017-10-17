_interface "068_sig.smi"
signature S =
sig
  type s = t
  val f : s -> s
end

structure A : S =
struct
  type s = t
  fun f x = x : s
end

(*
2011-08-24 katsu

This causes an unexpected type error.

068_sig.sml:9.11-13.3 Error:
  (type inference 012) type and type annotation don't agree
    inferred type: s(t32) -> s(t32)
  type annotation: s(t0) -> s(t0)

*)

(*
2011-08-27 ohori

Fixed. This is related to 050. When a structure is signature checked with
opaque mode, the name evaluator produce a declaration
  val x : ty
where ty is an opaque type with its actual type inside.

When this is thpechecked by InferTypes, it reveals the actual type and
do type check. However, this revaling should be only those that are
introduced this signature. So we add
1. revealKey (RevealID.id)
2. ICSIGTYPE {ty, revealKey,...}
3. fun revealTy revealKey ty = ... (in InferType)
revealTy selectively reveals the actual types of only those types 
specified in the SIGTYPE.

*)
