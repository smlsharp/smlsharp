functor F (A : sig type t end) :>
sig
  type s
  val f : ('a -> A.t) -> s
end
=
struct
  type s = A.t list
  val f = f
end

(*
2011-12-06 katsu

This causes BUG at StaticAnalysis.

Unification fails (3)
[.t38 list(t15[])]
t38 list(t15[])
TLSELECT: unification fail
tlexp
#1
  _indexof(1,
           {1:
              ['a(36).
               {TAG('a(36)), SIZE('a(36))}
               -> ('a(36) -> FREEBTV(38))
                  -> s(t33[[opaque(rv1,[. FREEBTV(38) list(t15[])])]])]})
  $T_b(5)
recordExp
$T_b(5)
indexExp
_indexof(1,
         {1:
            ['a(36).
             {TAG('a(36)), SIZE('a(36))}
             -> ('a(36) -> FREEBTV(38))
                -> s(t33[[opaque(rv1,[. FREEBTV(38) list(t15[])])]])]})
recordTy
{1:
   ['a(36).
    {TAG('a(36)), SIZE('a(36))}
    -> ('a(36) -> FREEBTV(38))
       -> s(t33[[opaque(rv1,[. FREEBTV(38) list(t15[])])]])]}
newRecordTy
{
  1: ['t36.
       ({tag(t36), size(t36)}
        -f4-> ((t36 -f0-> t38)^{G,B} -f1-> (t38) list(t15[]))^{G,B})
       ^{L0}]
}
^{L1}

indexTy
index(1,
      {
        1: ['t36.
             ({tag(t36), size(t36)}
              -f4-> ((t36 -f0-> t38)^{G,B} -f1-> (t38) list(t15[]))^{G,B})
             ^{L0}]
      }
      ^{L1})

newIndexTy
index(1,
      {
        1: ['t36.
             ({tag(t36), size(t36)}
              -f10-> ((t36 -f8-> t38)^{U} -f9-> [.t38 list(t15[])])^{U})
             ^{U}]
      }
      ^{U})

[BUG] StaticAnalysis:TLSELECT: unification fail
    raised at: ../staticanalysis/main/StaticAnalysis.sml:290.29-290.61
   handled at: ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53
*)
