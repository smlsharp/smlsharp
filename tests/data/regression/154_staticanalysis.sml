infixr ::

structure Fifo :> sig
  type 'a queue
  val empty : 'a queue
  val get : 'a queue -> 'a * 'a queue
end = 
struct
  type 'a queue = 'a list * 'a list
  val empty = (nil, nil)
  fun get (a::x,y) = (a, (x, y))
end

val q = Fifo.empty : int Fifo.queue
val (_,newQueue) = Fifo.get q

(*
2011-11-28 katsu

This causes BUG at StaticAnalysis.

Unification fails (3)
int(t0[]) queue(t30[[opaque(rv1,['a. 'a list(t15[]) * 'a list(t15[])])]])
{1: int(t0[]) list(t15[]), 2: int(t0[]) list(t15[])}^{U}
TLSELECT: unification fail
tlexp
#1
  _indexof(1,
           int(t0[])
           * int(t0[])
               queue(t30[[opaque(rv1,['a. 'a list(t15[]) * 'a list(t15[])])]]))
  $T_b(10)
recordExp
$T_b(10)
indexExp
_indexof(1,
         int(t0[])
         * int(t0[])
             queue(t30[[opaque(rv1,['a. 'a list(t15[]) * 'a list(t15[])])]]))
recordTy
int(t0[])
* int(t0[]) queue(t30[[opaque(rv1,['a. 'a list(t15[]) * 'a list(t15[])])]])
newRecordTy
{1: int(t0[]), 2: {1: int(t0[]) list(t15[]), 2: int(t0[]) list(t15[])}^{U}}^{U}

indexTy
index(1,
      {
        1: int(t0[]),
        2: {1: int(t0[]) list(t15[]), 2: int(t0[]) list(t15[])}^{U}
      }
      ^{U})

newIndexTy
index(1,
      {
        1: int(t0[]),
        2: int(t0[]) queue(t30[[opaque(rv1,['a. 'a list(t15[]) * 'a list(t15[])])]])
      }
      ^{U})

[BUG] StaticAnalysis:TLSELECT: unification fail
    raised at: ../staticanalysis/main/StaticAnalysis.sml:290.29-290.61
   handled at: ../toplevel2/main/Top.sml:836.37
                main/SimpleMain.sml:368.53
*)
