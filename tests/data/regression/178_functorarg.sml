functor F (A : sig type t end) :> sig
  type 'a map
  val empty : 'a map
end =
struct
  type 'a map = A.t list
  val empty = []
end

(*
2011-12-02 katsu

This causes BUG at StaticAnalysis.

TLSELECT: unification fail
tlexp
#1
  _indexof(1,
           {1:
              ['a.
               {TAG('a), SIZE('a)}
               -> 'a map(t33[[opaque(rv1,['b. FREEBTV(35) list(t15[])])]])]})
  $T_b(5)
recordExp
$T_b(5)
indexExp
_indexof(1,
         {1:
            ['a.
             {TAG('a), SIZE('a)}
             -> 'a map(t33[[opaque(rv1,['b. FREEBTV(35) list(t15[])])]])]})
recordTy
{1:
   ['a.
    {TAG('a), SIZE('a)}
    -> 'a map(t33[[opaque(rv1,['b. FREEBTV(35) list(t15[])])]])]}
newRecordTy
{1: ['t34.({tag(t34), size(t34)} -f2-> (t36) list(t15[]))^{L1}]}^{L2}

indexTy
index(1, {1: ['t34.({tag(t34), size(t34)} -f2-> (t36) list(t15[]))^{L1}]}^{L2})

newIndexTy
index(1, {1: ['t34.({tag(t34), size(t34)} -f6-> (t35) list(t15[]))^{U}]}^{U})

[BUG] StaticAnalysis:TLSELECT: unification fail
    raised at: ../staticanalysis/main/StaticAnalysis.sml:290.29-290.61
   handled at: ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53

*)


(*
2011-12-04 ohori

Fixed. Needed to substitute inside of tyCon (TYDEF, opaqueRep) 
when we do substBTvar, of cource.
*)
