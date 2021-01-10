(**
 * Polytype elimination
 *
 * @copyright (c) 2017 Tohoku University.
 * @author UENO Katsuhiro
 *)

structure PolyTyElimination =
struct

  structure C = TypedCalc
  structure D = TypedCalcCon
  structure T = Types
  structure DK = DynamicKind
  structure DKU = DynamicKindUtils

  fun bug s = Bug.Bug ("PolyTyElimination: " ^ s)

  fun optionToList NONE = nil
    | optionToList (SOME x) = [x]

  open PolyTyInstance

  (* just for benchmark *)
  val countSubst = ref 0
  val countOptimized = ref 0
  val countBoxed = ref 0
  val countUnboxed = ref 0
  val countSize1 = ref 0
  val countSize2 = ref 0
  val countSize4 = ref 0
  val countSize8 = ref 0
  val countRecord = ref 0
  val countEmpty = ref 0
  val countKeep = ref 0
  fun inc c = c := !c + 1

  structure BoundTypeVarID =
  struct
    open BoundTypeVarID
    structure Map =
    struct
      open Map
      fun all f m =
          foldl (fn (x, z) => z andalso f x) true m
      fun alli f m =
          foldli (fn (k, x, z) => z andalso f (k, x)) true m
      fun fromSet f s =
          Set.foldl (fn (x, z) => insert (z, x, f x)) empty s
      fun domainSet m =
          foldli (fn (x, _, z) => Set.add (z, x)) Set.empty m
    end
  end

  (* In this phase, each BoundTypeVarID.id is associated with a meta
   * variable identified by MetaID.id, which denotes the set of instances.
   * the choice of BoundTypeVarID.id is significant: bound type variables
   * that are associated with the same meta variable are identified by
   * the same id. *)
  structure MetaID :> sig
    eqtype id
    val toString : id -> string
    val idOf : BoundTypeVarID.id -> id
    structure Set : sig
      type set
      val empty : set
      val union : set * set -> set
      val map : (id -> id) -> set -> set
      val fromBtvSet : BoundTypeVarID.Set.set -> set
    end
    structure Map : sig
      type 'a map
      val empty : 'a map
      val isEmpty : 'a map -> bool
      val insert : 'a map * id * 'a -> 'a map
      val find : 'a map * id -> 'a option
      val map : ('a -> 'b) -> 'a map -> 'b map
      val mapi : (id * 'a -> 'b) -> 'a map -> 'b map
      val mapPartial : ('a -> 'b option) -> 'a map -> 'b map
      val appi : (id * 'a -> unit) -> 'a map -> unit
      val foldl : ('a * 'b -> 'b) -> 'b -> 'a map -> 'b
      val foldli : (id * 'a * 'b -> 'b) -> 'b -> 'a map -> 'b
      val unionWith : ('a * 'a -> 'a) -> 'a map * 'a map -> 'a map
      val mergeWith : ('a option * 'b option -> 'c option)
                      -> 'a map * 'b map -> 'c map
      val toBtvMap : 'a map -> 'a BoundTypeVarID.Map.map
      val fromBtvMap : ('a -> 'b) -> 'a BoundTypeVarID.Map.map -> 'b map
      val fromBtvSet : (id -> 'a) -> BoundTypeVarID.Set.set -> 'a map
      val fromSet : (id -> 'a) -> Set.set -> 'a map
      val domainSet : 'a map -> Set.set
      val all : ('a -> bool) -> 'a map -> bool
    end
  end =
  struct
    open BoundTypeVarID
    fun idOf (x:id) = x
    structure Set =
    struct
      open Set
      fun fromBtvSet (x:set) = x
    end
    structure Map =
    struct
      open Map
      fun toBtvMap (x:'a map) = x
      val fromBtvMap = map
      val fromBtvSet = fromSet
    end
  end

(*
  fun toTypeKind EMPTY =
      #kind Types.univKind
    | toTypeKind BOXED =
      T.KIND {tvarKind = T.UNIV,
              properties = nil,
              dynamicKind = DynamicKind.bottomKind
             }
    | toTypeKind UNIV =
      #kind Types.univKind

  fun fromTypeKind (T.KIND kind) =
      case kind of
        {tvarKind = T.UNIV, properties, dynamicKind} => 
        if T.isBoxedProperties properties then BOXED else UNIV
      | {tvarKind = T.REC _,...} => BOXED
      | {tvarKind = T.OCONSTkind _,...} => UNIV
      | {tvarKind = T.OPRIMkind _,...} => UNIV
*)


  (* imperative union-find algorithm *)
  structure UnionFind :> sig
    type 'a node
    val new : 'a -> 'a node
    val find : 'a node -> 'a
    val union : ({root:'a, child:'a} -> 'a) -> 'a node * 'a node -> unit
  end =
  struct
    datatype 'a node' = R of word * 'a | F of 'a node
    withtype 'a node = 'a node' ref

    fun new x = ref (R (0w0, x))

    fun find' (r as ref (R x)) = (r, x)
      | find' (ref (F (r as ref (R x)))) = (r, x)
      | find' (r as ref (F x)) =
        let val ret as (root, _) = find' x in r := F root; ret end

    fun find node =
        case find' node of (_, (_, x)) => x

    fun union merge (node1, node2) =
        let
          val (node1, (rank1, x1)) = find' node1
          val (node2, (rank2, x2)) = find' node2
        in
          if node1 = node2 then ()
          else if rank1 > rank2
          then (node1 := R (rank1, merge {root=x1, child=x2});
                node2 := F node1)
          else if rank1 < rank2
          then (node1 := F node2;
                node2 := R (rank2, merge {root=x2, child=x1}))
          else (node1 := R (rank1 + 0w1, merge {root=x1, child=x2});
                node2 := F node1)
      end
  end

  type meta =
      {id : MetaID.id, instances : instance list ref}

  fun new id =
      UnionFind.new ({id = id, instances = ref nil} : meta)

  fun touch (r as ref nodes) ids =
      case
        MetaID.Map.foldli
          (fn (id, (kind, dynamicKind), (nodes, z)) =>
              case MetaID.Map.find (nodes, id) of
                SOME _ => (nodes, z)
              | NONE => (MetaID.Map.insert (nodes, id, new id), false))
          (nodes, true)
          ids
      of
        (_, true) => ()
      | (nodes, false) => r := nodes

  fun findNode nodes id =
      case MetaID.Map.find (!nodes, id) of
        SOME x => x
      | NONE => raise bug "findNode"

  fun equalId nodes (id1, id2) =
      if id1 = id2
      then ()
      else UnionFind.union
             (fn {root as {instances=i1, ...}, child={instances=i2, ...}} =>
                 root # {instances = ref (!i2 @ !i1)} : meta)
             (findNode nodes id1, findNode nodes id2)

  fun instanceOf nodes (inst, id) =
      let
        val node = findNode nodes id
        val {instances, ...} = UnionFind.find node
      in
        instances := inst :: !instances
      end

  fun instantiate nodes btvEnv (polyTy, nil) = ()
    | instantiate nodes btvEnv (polyTy, instTyList) =
      let
          val {boundtvars, ...} =
              case TypesBasics.derefTy polyTy of
                T.POLYty x => x
              | _ => raise bug "analyzeExp: TPTAPP: not POLYty"
        fun tyvars ty =
            let
              val tvs = TypesBasics.EFBTV ty
            in
              if BoundTypeVarID.Set.isSubset
                   (tvs, BoundTypeVarID.Map.domainSet btvEnv)
              then tvs
              else raise bug "tyvars"
            end
      in
        ListPair.appEq
          (fn (tid, ty) =>
              instanceOf nodes (INST (tyvars ty, ty), MetaID.idOf tid))
          (BoundTypeVarID.Map.listKeys boundtvars, instTyList)
          handle ListPair.UnequalLengths => raise bug "instantiate"
      end

  local
    exception NotEqual

    fun equalUnion (subst1, subst2) =
        BoundTypeVarID.Map.unionWith
          (fn (x, y) => if BoundTypeVarID.eq (x, y) then x else raise NotEqual)
          (subst1, subst2)

    fun equalList f r (xs, ys) =
        ListPair.foldlEq
          (fn (x, y, z) => equalUnion (z, f r (x, y)))
          BoundTypeVarID.Map.empty
          (xs, ys)
        handle ListPair.UnequalLengths => raise NotEqual

    fun equalListOpt f r (NONE, NONE) = BoundTypeVarID.Map.empty
      | equalListOpt f r (NONE, SOME _) = raise NotEqual
      | equalListOpt f r (SOME _, NONE) = raise NotEqual
      | equalListOpt f r (SOME l1, SOME l2) = equalList f r (l1, l2)

    fun revealOpaqueRep (T.TYCON tyCon, args) =
        T.CONSTRUCTty {tyCon = tyCon, args = args}
      | revealOpaqueRep (T.TFUNDEF {admitsEq, arity, polyTy}, args) =
        TypesBasics.tpappTy (polyTy, args)

    fun revealTyCon {tyCon as {dtyKind, ...}, args} =
        case dtyKind of
          T.OPAQUE {opaqueRep, revealKey} => revealOpaqueRep (opaqueRep, args)
        | T.INTERFACE opaqueRep => revealOpaqueRep (opaqueRep, args)
        | T.DTY _ => T.CONSTRUCTty {tyCon = tyCon, args = args}

    fun equalTy r (ty1, ty2) =
        case (ty1, ty2) of
          (T.TYVARty (ref (T.SUBSTITUTED ty1)), ty2) => equalTy r (ty1, ty2)
        | (ty1, T.TYVARty (ref (T.SUBSTITUTED ty2))) => equalTy r (ty1, ty2)
        | (T.CONSTRUCTty (a as {tyCon={dtyKind=T.OPAQUE _,...},...}), ty2) =>
          equalTy r (revealTyCon a, ty2)
        | (T.CONSTRUCTty (a as {tyCon={dtyKind=T.INTERFACE _,...},...}), ty2) =>
          equalTy r (revealTyCon a, ty2)
        | (ty1, T.CONSTRUCTty (a as {tyCon={dtyKind=T.OPAQUE _,...},...})) =>
          equalTy r (ty1, revealTyCon a)
        | (ty1, T.CONSTRUCTty (a as {tyCon={dtyKind=T.INTERFACE _,...},...})) =>
          equalTy r (ty1, revealTyCon a)
        | (T.SINGLETONty sty1, T.SINGLETONty sty2) =>
          equalSingletonTy r (sty1, sty2)
        | (T.DUMMYty (id1, kind1), T.DUMMYty (id2, kind2)) =>
          if id1 = id2
          then equalKind r (kind1, kind2)
          else raise NotEqual
        | (T.EXISTty (id1, kind1), T.EXISTty (id2, kind2)) =>
          if id1 = id2
          then equalKind r (kind1, kind2)
          else raise NotEqual
        | (T.BOUNDVARty t1, T.BOUNDVARty t2) =>
          BoundTypeVarID.Map.singleton (t1, t2)
        | (T.FUNMty (argTys1, retTy1), T.FUNMty (argTys2, retTy2)) =>
          equalList equalTy r (retTy1 :: argTys1, retTy2 :: argTys2)
        | (T.RECORDty fields1, T.RECORDty fields2) =>
          RecordLabel.Map.foldl
            equalUnion
            BoundTypeVarID.Map.empty
            (RecordLabel.Map.mergeWith
               (fn (SOME ty1, SOME ty2) => SOME (equalTy r (ty1, ty2))
                 | _ => raise NotEqual)
               (fields1, fields2))
        | (T.CONSTRUCTty {tyCon=c1, args=args1},
           T.CONSTRUCTty {tyCon=c2, args=args2}) =>
          if #id c1 = #id c2
          then equalList equalTy r (args1, args2)
          else raise NotEqual
        | (T.POLYty {boundtvars=btv1, constraints=c1, body=ty1},
           T.POLYty {boundtvars=btv2, constraints=c2, body=ty2}) =>
          (*
           * Note that the following:
           * - The order of bound type variables in boundtvars is significant;
           *   record compilation generates extra arguments with respect to
           *   their order.
           * - Unused bound type variables, say ['a. unit], may appear due to
           *   opaque phantom type.  The meaning of ['a. unit] is different
           *   from that of unit because of type-directed compilation.
           *   See the test case 341_phantom for example.
           *)
          let
            val subst1 = equalList equalConstraint r (c1, c2)
            val subst2 = equalTy r (ty1, ty2)
            val subst3 = equalBtvEnv r (btv1, btv2)
            val subst = equalUnion (equalUnion (subst1, subst2), subst3)
          in
            BoundTypeVarID.Map.appi
              (fn (tid1, tid2) =>
                  if BoundTypeVarID.Map.inDomain (btv1, tid1)
                  then equalId r (MetaID.idOf tid1, MetaID.idOf tid2)
                  else ())
              subst;
            BoundTypeVarID.Map.filteri
              (fn (tid1, _) => not (BoundTypeVarID.Map.inDomain (btv1, tid1)))
              subst
          end
        | (T.SINGLETONty _, _) => raise NotEqual
        | (T.DUMMYty _, _) => raise NotEqual
        | (T.EXISTty _, _) => raise NotEqual
        | (T.BOUNDVARty _, _) => raise NotEqual
        | (T.FUNMty _, _) => raise NotEqual
        | (T.RECORDty _, _) => raise NotEqual
        | (T.CONSTRUCTty _, _) => raise NotEqual
        | (T.POLYty _, _) => raise NotEqual
        | (T.BACKENDty _, _) =>
          raise bug "equalTy: BACKENDty never occur"
        | (T.ERRORty, _) =>
          raise bug "equalTy: ERRORty never occur"
        | (T.TYVARty (ref (T.TVAR _)), _) =>
          raise bug "equalTy: TVAR never occur"

    and equalSingletonTy r (sty1, sty2) =
        case (sty1, sty2) of
          (T.INSTCODEty s1, T.INSTCODEty s2) => equalOprimSelector r (s1, s2)
        | (T.INDEXty (l1, ty1), T.INDEXty (l2, ty2)) => equalTy r (ty1, ty2)
        | (T.TAGty ty1, T.TAGty ty2) => equalTy r (ty1, ty2)
        | (T.SIZEty ty1, T.SIZEty ty2) => equalTy r (ty1, ty2)
        | (T.REIFYty ty1, T.REIFYty ty2) => equalTy r (ty1, ty2)
        | (T.INSTCODEty _, _) => raise NotEqual
        | (T.INDEXty _, _) => raise NotEqual
        | (T.TAGty _, _) => raise NotEqual
        | (T.SIZEty _, _) => raise NotEqual
        | (T.REIFYty _, _) => raise NotEqual

    and equalOprimSelector
          r ({oprimId=id1, longsymbol=s1, match=m1},
             {oprimId=id2, longsymbol=s2, match=m2}) =
        if id1 = id2 andalso Symbol.eqLongsymbol (s1, s2)
        then equalOverloadMatch r (m1, m2)
        else raise NotEqual

    and equalOverloadMatch r (match1, match2) =
        case (match1, match2) of
          (T.OVERLOAD_CASE (ty1, matches1), T.OVERLOAD_CASE (ty2, matches2)) =>
          TypID.Map.foldl
            (fn ((x,y),z) => equalUnion (equalOverloadMatch r (x, y), z))
            (equalTy r (ty1, ty2))
            (TypID.Map.mergeWith
               (fn (NONE, NONE) => NONE
                 | (SOME _, NONE) => raise NotEqual
                 | (NONE, SOME _) => raise NotEqual
                 | (SOME x, SOME y) => SOME (x, y))
               (matches1, matches2))
        | (T.OVERLOAD_CASE _, _) => raise NotEqual
        | (T.OVERLOAD_EXVAR {exVarInfo={path=path1,...}, instTyList=i1},
           T.OVERLOAD_EXVAR {exVarInfo={path=path2,...}, instTyList=i2}) =>
          if Symbol.eqLongsymbol (path1, path2)
          then equalListOpt equalTy r (i1, i2)
          else raise NotEqual
        | (T.OVERLOAD_EXVAR _, _) => raise NotEqual
        | (T.OVERLOAD_PRIM {primInfo={primitive=p1,...}, instTyList=i1},
           T.OVERLOAD_PRIM {primInfo={primitive=p2,...}, instTyList=i2}) =>
          if p1 = p2
          then equalListOpt equalTy r (i1, i2)
          else raise NotEqual
        | (T.OVERLOAD_PRIM _, _) => raise NotEqual

    and equalConstraint r (T.JOIN {res=r1, args=(a11, a12), loc=_},
                           T.JOIN {res=r2, args=(a21, a22), loc=_}) =
        equalList equalTy r ([r1, a11, a12], [r2, a21, a22])

    and equalKind
          r (T.KIND
               {properties = prop1, tvarKind=t1, dynamicKind=_},
             T.KIND
               {properties = prop2, tvarKind=t2, dynamicKind=_}) =
        if T.equalProperties prop1 prop2
        then equalTvarKind r (t1, t2)
        else raise NotEqual

    and equalTvarKind r (tvarKind1, tvarKind2) =
        case (tvarKind1, tvarKind2) of
          (T.OCONSTkind tys1, T.OCONSTkind tys2) =>
          equalList equalTy r (tys1, tys2)
        | (T.OPRIMkind {instances=i1, operators=o1},
           T.OPRIMkind {instances=i2, operators=o2}) =>
          equalUnion
            (equalList equalTy r (i1, i2),
             equalList equalOprimSelector r (o1, o2))
        | (T.UNIV, T.UNIV) => BoundTypeVarID.Map.empty
        | (T.REC fields1, T.REC fields2) =>
          equalList equalTy r (RecordLabel.Map.listItems fields1,
                               RecordLabel.Map.listItems fields2)
        | (T.OCONSTkind _, _) => raise NotEqual
        | (T.OPRIMkind _, _) => raise NotEqual
        | (T.UNIV, _) => raise NotEqual
        | (T.REC _, _) => raise NotEqual

    and equalBtvEnv r (boundtvars1, boundtvars2) =
        ListPair.foldlEq
          (fn ((tid1, kind1), (tid2, kind2), subst) =>
              let
                val subst1 = BoundTypeVarID.Map.singleton (tid1, tid2)
                val subst2 = equalKind r (kind1, kind2)
              in
                equalUnion (equalUnion (subst1, subst2), subst)
              end)
          BoundTypeVarID.Map.empty
          (BoundTypeVarID.Map.listItemsi boundtvars1,
           BoundTypeVarID.Map.listItemsi boundtvars2)
          handle ListPair.UnequalLengths => raise NotEqual
  in

  fun equal r (ty1, ty2) =
      ignore (equalTy r (ty1, ty2))
      handle NotEqual => raise bug "equal"

  fun equalList r (tys1, tys2) =
      ListPair.appEq (equal r) (tys1, tys2)
      handle ListPair.UnequalLengths => raise bug "equalList"

  fun equalAll r nil = ()
    | equalAll r (x :: nil) = ()
    | equalAll r (x :: h :: t) = (equal r (x, h); equalAll r (x :: t))

  val equalTy =
      fn x =>
         BoundTypeVarID.Map.alli
           (op =)
           (equalTy (ref MetaID.Map.empty) x)
         handle NotEqual => false

  end (* local *)

  local
    fun getIdsUnion (map1, map2) =
        MetaID.Map.unionWith
          (fn ((kx, x), (ky,y)) => if DKU.eqKind (x, y) then (kx,x) else raise bug "getIdsUnion") 
          (map1, map2)

    fun getIdsList f xs =
        foldl (fn (x, z) => getIdsUnion (f x, z)) MetaID.Map.empty xs

    fun getIdsListOpt f NONE = MetaID.Map.empty
      | getIdsListOpt f (SOME l) = getIdsList f l

    fun getIdsTy ty =
        case ty of
          T.TYVARty (ref (T.SUBSTITUTED ty)) => getIdsTy ty
        | T.SINGLETONty sty => getIdsSingletonTy sty
        | T.DUMMYty (id, kind) => getIdsKind kind
        | T.EXISTty (id, kind) => getIdsKind kind
        | T.BOUNDVARty t => MetaID.Map.empty
        | T.FUNMty (argTys, retTy) => getIdsList getIdsTy (retTy :: argTys)
        | T.RECORDty fields =>
          getIdsList getIdsTy (RecordLabel.Map.listItems fields)
        | T.CONSTRUCTty {tyCon, args} => getIdsList getIdsTy args
        | T.POLYty {boundtvars, constraints, body} =>
          getIdsUnion
            (getIdsUnion
               (getIdsList getIdsConstraint constraints,
                getIdsTy body),
             getIdsBtvEnv boundtvars)
        | T.BACKENDty bty => getIdsBackendTy bty
        | T.ERRORty =>
          raise bug "getIdsTy: ERRORty never occur"
        | T.TYVARty (ref (T.TVAR _)) =>
          raise bug "getIdsTy: TVAR never occur"

    and getIdsBackendTy bty =
        case bty of
          T.RECORDSIZEty ty => getIdsTy ty
        | T.RECORDBITMAPINDEXty (i, ty) => getIdsTy ty
        | T.RECORDBITMAPty (i, ty) => getIdsTy ty
        | T.CCONVTAGty codeEntryTy => getIdsCodeEntryTy codeEntryTy
        | T.FUNENTRYty codeEntryTy => getIdsCodeEntryTy codeEntryTy
        | T.CALLBACKENTRYty {tyvars, haveClsEnv, argTyList, retTy,
                             attributes} =>
          getIdsUnion
            (getIdsUnion (getIdsBtvEnv tyvars, getIdsList getIdsTy argTyList),
             case retTy of NONE => MetaID.Map.empty | SOME ty => getIdsTy ty)
        | T.SOME_FUNENTRYty => MetaID.Map.empty
        | T.SOME_FUNWRAPPERty => MetaID.Map.empty
        | T.SOME_CLOSUREENVty => MetaID.Map.empty
        | T.SOME_CCONVTAGty => MetaID.Map.empty
        | T.FOREIGNFUNPTRty {argTyList, varArgTyList, resultTy, attributes} =>
          getIdsList
            getIdsTy
            ((case resultTy of
                NONE => nil
              | SOME ty => [ty])
             @ (case varArgTyList of
                  NONE => argTyList
                | SOME l => argTyList @ l))
    and getIdsCodeEntryTy {tyvars, haveClsEnv, argTyList, retTy} =
        getIdsUnion
          (getIdsUnion (getIdsBtvEnv tyvars, getIdsList getIdsTy argTyList),
           getIdsTy retTy)
    and getIdsSingletonTy sty =
        case sty of
          T.INSTCODEty s => getIdsOprimSelector s
        | T.INDEXty (l, ty) => getIdsTy ty
        | T.TAGty ty => getIdsTy ty
        | T.SIZEty ty => getIdsTy ty
        | T.REIFYty ty => getIdsTy ty

    and getIdsOprimSelector {oprimId, longsymbol, match} =
        getIdsOverloadMatch match

    and getIdsOverloadMatch match =
        case match of
          T.OVERLOAD_CASE (ty, matches) =>
          TypID.Map.foldl
            (fn (x,z) => getIdsUnion (getIdsOverloadMatch x, z))
            (getIdsTy ty)
            matches
        | T.OVERLOAD_EXVAR {exVarInfo, instTyList} =>
          getIdsListOpt getIdsTy instTyList
        | T.OVERLOAD_PRIM {primInfo, instTyList} =>
          getIdsListOpt getIdsTy instTyList

    and getIdsConstraint (T.JOIN {res, args=(ty1, ty2), loc}) =
        getIdsList getIdsTy [res, ty1, ty2]

    and getIdsBtvEnv btvEnv =
        getIdsUnion
          (getIdsList getIdsKind (BoundTypeVarID.Map.listItems btvEnv),
           MetaID.Map.fromBtvMap
             (fn k => (k, case DKU.kindOfStaticKind k of
                            NONE => raise Bug.Bug "getIdsBtvEnv"
                          | SOME k => k))
             btvEnv)

    and getIdsKind (T.KIND {tvarKind,...}) =
        getIdsTvarKind tvarKind

    and getIdsTvarKind tvarKind =
        case tvarKind of
          T.OCONSTkind tys => getIdsList getIdsTy tys
        | T.OPRIMkind {instances, operators} =>
          getIdsUnion
            (getIdsList getIdsTy instances,
             getIdsList getIdsOprimSelector operators)
        | T.UNIV => MetaID.Map.empty
        | T.REC fields => getIdsList getIdsTy (RecordLabel.Map.listItems fields)
  in

  val getIds = getIdsTy
  val getIdsBtvEnv = getIdsBtvEnv

  fun getIdsConstraints l =
      getIdsList getIdsConstraint l

  fun getIdsInstance inst =
      case inst of
        EXTERN _ => MetaID.Set.empty
      | UNDEF => MetaID.Set.empty
      | INST (tyvars, ty) =>
        MetaID.Set.union
          (MetaID.Set.fromBtvSet tyvars,
           MetaID.Map.domainSet (getIdsTy ty))

  fun getIdsInstances insts =
      foldl (fn (x,z) => MetaID.Set.union (getIdsInstance x, z))
            MetaID.Set.empty
            insts

  end (* local *)

  fun export r ty =
      MetaID.Map.appi
        (fn (id, (_, kind)) => instanceOf r (EXTERN kind, id))
        (getIds ty)

  fun extendEnv env env2 =
      env # {env = D.extendEnv (#env env, env2)}

  fun extendVarEnv env varEnv =
      env # {env = D.extendEnv (#env env, D.varEnv varEnv)}

  fun extendBtvEnv env btvEnv =
      env # {env = D.extendEnv (#env env, D.btvEnv btvEnv)}

  fun addVars env vars =
      env # {env = D.extendEnv (#env env, D.makeVarEnv vars)}

  type a_env =
      {env : D.env,
       subst : TyAlphaRename.btvMap}

  fun analyzeTy r (env:a_env) ty =
      let
        val ty = TyAlphaRename.copyTy (#subst env) ty
      in
        touch r (getIds ty);
        ty
      end

  fun analyzeVarInfo r (env:a_env) (var : Types.varInfo) =
      var # {ty = analyzeTy r env (#ty var)}

  fun analyzeConInfo r (env:a_env) (con : Types.conInfo) =
      con # {ty = analyzeTy r env (#ty con)}

  fun analyzeExnInfo r (env:a_env) (exn : Types.exnInfo) =
      exn # {ty = analyzeTy r env (#ty exn)}

  fun analyzeExnCon (env:a_env) exncon =
      case exncon of
        C.EXN exnInfo =>
        (case ExnID.Map.find (#exnEnv (#env env), #id exnInfo) of
           NONE => raise bug "analyzeExnCon: TPEXN"
         | SOME {ty,...} => (C.EXN (exnInfo # {ty = ty}), ty))
      | C.EXEXN exExnInfo =>
        (case LongsymbolEnv.find (#exExnEnv (#env env), #path exExnInfo) of
           NONE => raise bug "analyzeExnCon: TPEXEXN"
         | SOME {ty,...} => (C.EXEXN (exExnInfo # {ty = ty}), ty))

  fun analyzePrimInfo r (env:a_env) (prim : Types.primInfo) =
      let
        val ty = analyzeTy r env (#ty prim)
      in
        export r ty;
        prim # {ty = ty}
      end

  fun analyzeOPrimInfo r (env:a_env) (prim : Types.oprimInfo) =
      let
        val ty = analyzeTy r env (#ty prim)
      in
        export r ty;
        prim # {ty = ty}
      end

  fun analyzeFFIty r env ffity =
      case ffity of
        C.FFIBASETY (ty, loc) =>
        C.FFIBASETY (analyzeTy r env ty, loc)
      | C.FFIFUNTY (attributes, argTys, varArgTys, retTys, loc) =>
        C.FFIFUNTY
          (attributes,
           map (analyzeFFIty r env) argTys,
           Option.map (map (analyzeFFIty r env)) varArgTys,
           map (analyzeFFIty r env) retTys,
           loc)
      | C.FFIRECORDTY (fields, loc) =>
        C.FFIRECORDTY
          (map (fn (label, ffity) => (label, analyzeFFIty r env ffity)) fields,
           loc)

  fun analyzeConstraints r (env:a_env) cs =
      let
        val cs = map (TyAlphaRename.copyConstraint (#subst env)) cs
      in
        touch r (getIdsConstraints cs);
        cs
      end

  fun analyzeBtvEnv r (env:a_env) btvEnv =
      let
        val (subst, btvEnv) = TyAlphaRename.newBtvEnv (#subst env) btvEnv
      in
        touch r (getIdsBtvEnv btvEnv);
        (btvEnv, extendBtvEnv env btvEnv # {subst = subst})
      end

  fun analyzePat r (env:a_env) tppat =
      case tppat of
        C.TPPATERROR _ => D.TPPATERROR
      | C.TPPATCONSTANT (const, ty, loc) =>
        D.TPPATCONSTANT (const, analyzeTy r env ty, loc)
      | C.TPPATDATACONSTRUCT {conPat, instTyList, argPatOpt, patTy, loc} =>
        let
          val conPat = analyzeConInfo r env conPat
        in
          export r (#ty conPat);
          D.TPPATDATACONSTRUCT
            {conPat = conPat,
             instTyList = Option.map (map (analyzeTy r env)) instTyList,
             argPatOpt = Option.map (analyzePat r env) argPatOpt,
             loc = loc}
        end
      | C.TPPATEXNCONSTRUCT {exnPat, argPatOpt, patTy, loc} =>
        let
          val (exnPat, exnTy) = analyzeExnCon env exnPat
        in
          D.TPPATEXNCONSTRUCT
            {exnPat = exnPat,
             argPatOpt = Option.map (analyzePat r env) argPatOpt,
             loc = loc}
        end
      | C.TPPATLAYERED {varPat, asPat, loc} =>
        let
          val varPat = analyzePat r env varPat
          val asPat = analyzePat r env asPat
        in
          equal r (#2 asPat, #2 varPat);
          D.TPPATLAYERED
            {varPat = varPat,
             asPat = asPat,
             loc = loc}
        end
      | C.TPPATRECORD {fields, recordTy, loc} =>
        let
          val fields = RecordLabel.Map.map (analyzePat r env) fields
          val recordTy = analyzeTy r env recordTy
          val recordTyFields =
              case TypesBasics.derefTy recordTy of
                T.RECORDty fields => fields
              | T.BOUNDVARty tid =>
                (case BoundTypeVarID.Map.find (#btvEnv (#env env), tid) of
                   SOME (T.KIND {tvarKind = T.REC fields, ...}) => fields
                 | _ => raise bug "analyzePat: TPPATRECORD (btv)")
              | T.DUMMYty (id, T.KIND {tvarKind = T.REC fields, ...}) => fields
                (* 338_dummytypeの対応 *)
              | T.EXISTty (id, T.KIND {tvarKind = T.REC fields, ...}) => fields
              | _ => raise bug "analyzePat: TPPATRECORD (tvar?)"
        in
          RecordLabel.Map.intersectWith
            (equal r)
            (RecordLabel.Map.map #2 fields, recordTyFields);
          D.TPPATRECORD
            (SOME (#btvEnv (#env env)))
            {fields = fields,
             recordTy = SOME recordTy,
             loc = loc}
        end
      | C.TPPATVAR var =>
        D.TPPATVAR (analyzeVarInfo r env var)
      | C.TPPATWILD (ty, loc) =>
        D.TPPATWILD (analyzeTy r env ty, loc)

  fun analyzeExp r (env:a_env) tpexp =
      case tpexp of
        C.TPERROR => D.TPERROR
      | C.TPCONSTANT {const, ty, loc} =>
        D.TPCONSTANT
          {const = const,
           ty = analyzeTy r env ty,
           loc = loc}
      | C.TPSIZEOF (ty, loc) =>
        D.TPSIZEOF (analyzeTy r env ty, loc)
      | C.TPREIFYTY (ty, loc) =>
        D.TPREIFYTY (analyzeTy r env ty, loc)
      | C.TPEXNTAG {exnInfo, loc} =>
        (case ExnID.Map.find (#exnEnv (#env env), #id exnInfo) of
           NONE => raise bug "analyzeExp: TPEXNTAG"
         | SOME {ty,...} =>
           D.TPEXNTAG {exnInfo = exnInfo # {ty = ty}, loc = loc})
      | C.TPEXEXNTAG {exExnInfo, loc} =>
        (case LongsymbolEnv.find (#exExnEnv (#env env), #path exExnInfo) of
           NONE => raise bug "analyzeExp: TPEXEXNTAG"
         | SOME {ty,...} =>
           D.TPEXEXNTAG {exExnInfo = exExnInfo # {ty = ty}, loc = loc})
      | C.TPEXVAR (var, loc) =>
        (case LongsymbolEnv.find (#exVarEnv (#env env), #path var) of
           NONE => 
           (
            print "TPEXVAR\n";
            print (Symbol.longsymbolToString (#path var));
            print "\n";
            raise bug "analyzeExp: TPEXVAR"
           )
         | SOME {ty,...} => D.TPEXVAR (var # {ty = ty}, loc))
      | C.TPVAR var =>
        (case VarID.Map.find (#varEnv (#env env), #id var) of
           NONE => raise bug "analyzeExp: TPVAR"
         | SOME {ty,...} => D.TPVAR (var # {ty = ty}))
      | C.TPRECFUNVAR {arity, var} =>
        (case VarID.Map.find (#varEnv (#env env), #id var) of
           NONE => raise bug "analyzeExp: TPRECFUNVAR"
         | SOME {ty,...} =>
           D.TPRECFUNVAR {arity = arity, var = var # {ty = ty}})
      | C.TPCAST ((exp, ty1), ty2, loc) =>
        let
          val exp as (_, expTy) = analyzeExp r env exp
          val ty2 = analyzeTy r env ty2
        in
          (* cast types must be preserved *)
          export r expTy;
          export r ty2;
          D.TPCAST ((exp, ty1), ty2, loc)
        end
      | C.TPDATACONSTRUCT {con, instTyList, argExpOpt, loc} =>
        let
          val con = analyzeConInfo r env con
          val instTyList = Option.map (map (analyzeTy r env)) instTyList
        in
          export r (#ty con);
          D.TPDATACONSTRUCT
            {con = con,
             instTyList = instTyList,
             argExpOpt = Option.map (analyzeExp r env) argExpOpt,
             loc = loc}
        end
      | C.TPEXNCONSTRUCT {exn, argExpOpt, loc} =>
        let
          val (exn, exnTy) = analyzeExnCon env exn
        in
          D.TPEXNCONSTRUCT
            {exn = exn,
             argExpOpt = Option.map (analyzeExp r env) argExpOpt,
             loc = loc}
        end
      | C.TPFFIIMPORT {funExp = C.TPFFIFUN (funExp, _), ffiTy, stubTy=_, loc} =>
        D.TPFFIIMPORT_FUN
          {funExp = analyzeExp r env funExp,
           ffiTy = analyzeFFIty r env ffiTy,
           loc = loc}
      | C.TPFFIIMPORT {funExp = C.TPFFIEXTERN symbol, ffiTy, stubTy=_, loc} =>
        D.TPFFIIMPORT_EXT
          {funExp = symbol,
           ffiTy = analyzeFFIty r env ffiTy,
           loc = loc}
      | C.TPFOREIGNSYMBOL {name, ty, loc} =>
        D.TPFOREIGNSYMBOL
          {name = name,
           ty = analyzeTy r env ty,
           loc = loc}
      | C.TPFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        D.TPFOREIGNAPPLY
          {funExp = analyzeExp r env funExp,
           argExpList = map (analyzeExp r env) argExpList,
           loc = loc}
      | C.TPCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        let
          val argVarList = map (analyzeVarInfo r env) argVarList
        in
          D.TPCALLBACKFN
            {attributes = attributes,
             argVarList = argVarList,
             bodyExp = analyzeExp r (addVars env argVarList) bodyExp,
             isVoid = not (isSome resultTy),
             loc = loc}
        end
      | C.TPTAPP {exp, expTy=_, instTyList, loc} =>
        let
          val exp as (_, expTy) = analyzeExp r env exp
          val instTyList = map (analyzeTy r env) instTyList
        in
          instantiate r (#btvEnv (#env env)) (expTy, instTyList);
          D.TPTAPP
            {exp = exp,
             instTyList = instTyList,
             loc = loc}
        end
      | C.TPPOLY {btvEnv, constraints, exp, expTyWithoutTAbs=_, loc} =>
        let
          val (btvEnv, env) = analyzeBtvEnv r env btvEnv
        in
          D.TPPOLY
            {btvEnv = btvEnv,
             constraints = analyzeConstraints r env constraints,
             exp = analyzeExp r env exp,
             loc = loc}
        end
      | C.TPFNM {argVarList, bodyExp, bodyTy=_, loc} =>
        let
          val argVarList = map (analyzeVarInfo r env) argVarList
        in
          D.TPFNM
            {argVarList = argVarList,
             bodyExp = analyzeExp r (addVars env argVarList) bodyExp,
             loc = loc}
        end
      | C.TPAPPM {argExpList, funExp, funTy=_, loc} =>
        let
          val funExp = analyzeExp r env funExp
          val argExpList = map (analyzeExp r env) argExpList
        in
          case TypesBasics.derefTy (#2 funExp) of
            T.FUNMty (argTys, bodyTy) =>
            equalList r (argTys, map #2 argExpList)
          | _ => raise bug "analyzeExp: TPAPPM: not funty";
          D.TPAPPM
            {funExp = funExp,
             argExpList = argExpList,
             loc = loc}
        end
      | C.TPCASEM {caseKind, expList, expTyList=_, loc, ruleBodyTy=_,
                   ruleList} =>
        let
          val expList = map (analyzeExp r env) expList
          val (ruleList, (argTys, _)) = analyzeMatchList r env ruleList
        in
          equalList r (argTys, map #2 expList);
          D.TPCASEM
            {caseKind = caseKind,
             expList = expList,
             ruleList = ruleList,
             loc = loc}
        end
      | C.TPSWITCH {exp, expTy, ruleList = C.CONSTCASE rules,
                    defaultExp, ruleBodyTy, loc} =>
        let
          val exp = analyzeExp r env exp
          val defaultExp = analyzeExp r env defaultExp
          fun analyzeRule {const, ty, body} =
              {const = const,
               ty = analyzeTy r env ty,
               body = analyzeExp r env body}
          val rules = map analyzeRule rules
        in
          equalAll r (#2 defaultExp :: map (#2 o #body) rules);
          D.TPSWITCH_CONSTCASE
            {exp = exp,
             ruleList = rules,
             defaultExp = defaultExp,
             loc = loc}
        end
      | C.TPSWITCH {exp, expTy, ruleList = C.CONCASE rules,
                    defaultExp, ruleBodyTy, loc} =>
        let
          val exp = analyzeExp r env exp
          val defaultExp = analyzeExp r env defaultExp
          fun analyzeRule {con, instTyList, argVarOpt, body} =
              let
                val con = analyzeConInfo r env con
                val instTyList = Option.map (map (analyzeTy r env)) instTyList
                val argVarOpt = Option.map (analyzeVarInfo r env) argVarOpt
                val (_, patTy, varEnv) =
                    D.TPPATDATACONSTRUCT
                      {conPat = con,
                       instTyList = instTyList,
                       argPatOpt = Option.map D.TPPATVAR argVarOpt,
                       loc = loc}
                val body = analyzeExp r (extendVarEnv env varEnv) body
              in
                export r (#ty con);
                ({con = con,
                  instTyList = instTyList,
                  argVarOpt = argVarOpt,
                  body = body},
                 T.FUNMty ([patTy], #2 body))
              end
          val rules = map analyzeRule rules
        in
          equalAll r (T.FUNMty ([#2 exp], #2 defaultExp) :: map #2 rules);
          D.TPSWITCH_CONCASE
            {exp = exp,
             ruleList = map #1 rules,
             defaultExp = defaultExp,
             loc = loc}
        end
      | C.TPSWITCH {exp, expTy, ruleList = C.EXNCASE rules,
                    defaultExp, ruleBodyTy, loc} =>
        let
          val exp = analyzeExp r env exp
          val defaultExp = analyzeExp r env defaultExp
          fun analyzeRule {exn, argVarOpt, body} =
              let
                val (exn, exnTy) = analyzeExnCon env exn
                val argVarOpt = Option.map (analyzeVarInfo r env) argVarOpt
                val (_, patTy, varEnv) =
                    D.TPPATEXNCONSTRUCT
                      {exnPat = exn,
                       argPatOpt = Option.map D.TPPATVAR argVarOpt,
                       loc = loc}
                val body = analyzeExp r (extendVarEnv env varEnv) body
              in
                ({exn = exn,
                  argVarOpt = argVarOpt,
                  body = body},
                 T.FUNMty ([patTy], #2 body))
              end
          val rules = map analyzeRule rules
        in
          equalAll r (T.FUNMty ([#2 exp], #2 defaultExp) :: map #2 rules);
          D.TPSWITCH_EXNCASE
            {exp = exp,
             ruleList = map #1 rules,
             defaultExp = defaultExp,
             loc = loc}
        end
      | C.TPTHROW {catchLabel, argExpList, resultTy, loc} =>
        D.TPTHROW
          {catchLabel = catchLabel,
           argExpList = map (analyzeExp r env) argExpList,
           resultTy = analyzeTy r env resultTy,
           loc = loc}
      | C.TPCATCH {catchLabel, tryExp, argVarList, catchExp, resultTy, loc} =>
        let
          val argVarList = map (analyzeVarInfo r env) argVarList
          val tryExp = analyzeExp r env tryExp
          val catchExp = analyzeExp r (addVars env argVarList) catchExp
        in
          equal r (#2 tryExp, #2 catchExp);
          D.TPCATCH
            {catchLabel = catchLabel,
             tryExp = tryExp,
             argVarList = argVarList,
             catchExp = catchExp,
             loc = loc}
        end
      | C.TPLET {body, decls, loc} =>
        let
          val (decls, env) = analyzeDeclList r env decls
        in
          D.TPLET
            {decls = decls,
             body = analyzeExp r env body,
             loc = loc}
        end
      | C.TPMONOLET {binds, bodyExp, loc} =>
        let
          val (binds, env) = analyzeMonoLet r env binds
        in
          D.TPMONOLET
            {binds = binds,
             bodyExp = analyzeExp r env bodyExp,
             loc = loc}
        end
      | C.TPRAISE {exp, loc, ty} =>
        D.TPRAISE
          {exp = analyzeExp r env exp,
           ty = analyzeTy r env ty,
           loc = loc}
      | C.TPHANDLE {exnVar, exp, handler, resultTy=_, loc} =>
        let
          val exnVar = analyzeVarInfo r env exnVar
        in
          D.TPHANDLE
            {exp = analyzeExp r env exp,
             exnVar = exnVar,
             handler = analyzeExp r (addVars env [exnVar]) handler,
             loc = loc}
        end
      | C.TPRECORD {fields, loc, recordTy=_} =>
        D.TPRECORD
          {fields = RecordLabel.Map.map (analyzeExp r env) fields,
           loc = loc}
      | C.TPSELECT {exp, expTy=_, label, loc, resultTy=_} =>
        D.TPSELECT
          (SOME (#btvEnv (#env env)))
          {exp = analyzeExp r env exp,
           label = label,
           loc = loc}
      | C.TPMODIFY {elementExp, elementTy=_, label, loc,
                    recordExp, recordTy=_} =>
        D.TPMODIFY
          (SOME (#btvEnv (#env env)))
          {recordExp = analyzeExp r env recordExp,
           label = label,
           elementExp = analyzeExp r env elementExp,
           loc = loc}
      | C.TPPRIMAPPLY {argExp, instTyList, loc, primOp} =>
        D.TPPRIMAPPLY
          {primOp = analyzePrimInfo r env primOp,
           instTyList = Option.map (map (analyzeTy r env)) instTyList,
           argExp = analyzeExp r env argExp,
           loc = loc}
      | C.TPOPRIMAPPLY {argExp, instTyList, loc, oprimOp} =>
        D.TPOPRIMAPPLY
          {oprimOp = analyzeOPrimInfo r env oprimOp,
           instTyList = map (analyzeTy r env) instTyList,
           argExp = analyzeExp r env argExp,
           loc = loc}
      | C.TPJOIN {isJoin, ty, args=(exp1, exp2), argtys=_, loc} =>
        D.TPJOIN
          {args = (analyzeExp r env exp1, analyzeExp r env exp2),
           ty = analyzeTy r env ty,
           isJoin = isJoin,
           loc = loc}
      | C.TPDYNAMIC {exp, ty=_, elemTy, coerceTy, loc} =>
        D.TPDYNAMIC
          {exp = analyzeExp r env exp,
           coerceTy = analyzeTy r env coerceTy,
           elemTy = analyzeTy r env elemTy,
           loc = loc}
      | C.TPDYNAMICIS {exp, ty=_, elemTy, coerceTy, loc} =>
        D.TPDYNAMICIS
          {exp = analyzeExp r env exp,
           coerceTy = analyzeTy r env coerceTy,
           elemTy = analyzeTy r env elemTy,
           loc = loc}
      | C.TPDYNAMICNULL {ty, coerceTy, loc} =>
        D.TPDYNAMICNULL
          {coerceTy = analyzeTy r env coerceTy,
           ty = analyzeTy r env ty,
           loc = loc}
      | C.TPDYNAMICTOP {ty, coerceTy, loc} =>
        D.TPDYNAMICTOP
          {coerceTy = analyzeTy r env coerceTy,
           ty = analyzeTy r env ty,
           loc = loc}
      | C.TPDYNAMICVIEW {exp, ty=_, elemTy, coerceTy, loc} =>
        D.TPDYNAMICVIEW
          {exp = analyzeExp r env exp,
           coerceTy = analyzeTy r env coerceTy,
           elemTy = analyzeTy r env elemTy,
           loc = loc}
      | C.TPDYNAMICCASE {groupListTerm, groupListTy, dynamicTerm, dynamicTy, elemTy, ruleBodyTy, loc} =>
        D.TPDYNAMICCASE
          {groupListTerm = analyzeExp r env groupListTerm,
           groupListTy = analyzeTy r env groupListTy,
           dynamicTerm = analyzeExp r env dynamicTerm,
           dynamicTy = analyzeTy r env dynamicTy,
           elemTy = analyzeTy r env elemTy,
           ruleBodyTy = analyzeTy r env ruleBodyTy,
           loc = loc}
      | C.TPDYNAMICEXISTTAPP {existInstMap, exp, expTy=_, instTyList, loc} =>
        let
          val existInstMap = analyzeExp r env existInstMap
          val exp as (_, expTy) = analyzeExp r env exp
          val instTyList = map (analyzeTy r env) instTyList
        in
          export r expTy;
          D.TPDYNAMICEXISTTAPP
            {existInstMap = existInstMap,
             exp = exp,
             instTyList = instTyList,
             loc = loc}
        end

  and analyzeMatch r env {args, body} =
      let
        val args = map (analyzePat r env) args
        val body = analyzeExp r (extendVarEnv env (D.patVars args)) body
      in
        {args = args, body = body}
      end

  and analyzeMatchList r env matches =
      let
        val matches = map (analyzeMatch r env) matches
        val matchTys = map (fn {args, body} => (map #2 args, #2 body)) matches
      in
        case matchTys of
          nil => raise bug "analyzeMatchList"
        | ty::_ =>
          (equalAll r (map T.FUNMty matchTys);
           (matches, ty))
      end

  and analyzeMonoLet r env nil = (nil, env)
    | analyzeMonoLet r env ((var, exp)::binds) =
      let
        val exp as (_, expTy) = analyzeExp r env exp
        val var = var # {ty = expTy}
        val env = addVars env [var]
        val (binds, env) = analyzeMonoLet r env binds
      in
        ((var, exp) :: binds, env)
      end

  and analyzeDeclList r env nil = (nil, env)
    | analyzeDeclList r env (dec::decs) =
      let
        val (dec, env1) = analyzeDecl r env dec
        val (decs, env) = analyzeDeclList r (extendEnv env env1) decs
      in
        (dec::decs, env)
      end

  and analyzeDecl r env tpdecl =
      case tpdecl of
        C.TPEXD (exnInfo, loc) =>
        D.TPEXD
          (analyzeExnInfo r env exnInfo,
           loc)
      | C.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
        let
          val exnInfo = analyzeExnInfo r env exnInfo
          val varInfo =
              case VarID.Map.find (#varEnv (#env env), #id varInfo) of
                NONE => raise bug "analyzeDecl: TPEXNTAGD"
              | SOME {ty,...} => varInfo # {ty = ty}
        in
          D.TPEXNTAGD ({exnInfo = exnInfo, varInfo = varInfo}, loc)
        end
      | C.TPEXTERNEXN ({path, ty}, provider) =>
        let
          val ty = analyzeTy r env ty
        in
          export r ty;
          D.TPEXTERNEXN ({path = path, ty = ty}, provider)
        end
      | C.TPBUILTINEXN {path, ty} =>
        let
          val ty = analyzeTy r env ty
        in
          export r ty;
          D.TPBUILTINEXN {path = path, ty = ty}
        end
      | C.TPEXTERNVAR ({path, ty}, provider) =>
        let
          val ty = analyzeTy r env ty
        in
          export r ty;
          D.TPEXTERNVAR ({path = path, ty = ty}, provider)
        end
      | C.TPEXPORTEXN exn =>
        let
          val ty =
              case ExnID.Map.find (#exnEnv (#env env), #id exn) of
                NONE => raise bug "analyzeDecl: TPEXPORTEXN"
              | SOME (exn as {ty,...}) => (export r ty; ty)
        in
          D.TPEXPORTEXN (exn # {ty = ty})
        end
      | C.TPEXPORTVAR {var={path, ty}, exp} =>
        let
          val ty = analyzeTy r env ty
          val exp = analyzeExp r env exp
        in
          export r ty;
          equal r (ty, #2 exp);
          D.TPEXPORTVAR {var = {path = path, ty = ty}, exp = exp}
        end
      | C.TPVAL ((var, exp), loc) =>
        D.TPVAL
          ((var, analyzeExp r env exp),
           loc)
      | C.TPVALREC (recbinds, loc) =>
        D.TPVALREC (analyzeRecbinds r env recbinds, loc)
      | C.TPVALPOLYREC {btvEnv, constraints, recbinds, loc} =>
        let
          val (btvEnv, env) = analyzeBtvEnv r env btvEnv
        in
          D.TPVALPOLYREC
            {btvEnv = btvEnv,
             constraints = analyzeConstraints r env constraints,
             recbinds = analyzeRecbinds r env recbinds,
             loc = loc}
        end
      | C.TPFUNDECL (recbinds, loc) =>
        D.TPFUNDECL (analyzeFunRecbinds r env recbinds, loc)
      | C.TPPOLYFUNDECL {btvEnv, constraints, recbinds, loc} =>
        let
          val (btvEnv, env) = analyzeBtvEnv r env btvEnv
        in
          D.TPPOLYFUNDECL
            {btvEnv = btvEnv,
             constraints = analyzeConstraints r env constraints,
             recbinds = analyzeFunRecbinds r env recbinds,
             loc = loc}
        end

  and analyzeRecbinds r env recbinds =
      let
        val recbinds =
            map (fn {var, exp} =>
                    {var = analyzeVarInfo r env var, exp = exp})
                recbinds
        val env = addVars env (map #var recbinds)
      in
        map (fn {var, exp} =>
                let
                  val exp = analyzeExp r env exp
                in
                  equal r (#ty var, #2 exp);
                  {var = var, exp = exp}
                end)
            recbinds
      end

  and analyzeFunRecbinds r env recbinds =
      let
        val recbinds =
            map (fn {funVarInfo, ruleList, ...} =>
                    {funVarInfo = analyzeVarInfo r env funVarInfo,
                     ruleList = ruleList})
                recbinds
        val env = addVars env (map #funVarInfo recbinds)
      in
        map (fn {funVarInfo, ruleList} =>
                let
                  val (ruleList, x) = analyzeMatchList r env ruleList
                in
                  equal r (#ty funVarInfo, T.FUNMty x);
                  {funVarInfo = funVarInfo, ruleList = ruleList}
                end)
            recbinds
      end

  exception Cycle
  exception NotFound

  fun traverse f graph =
      let
        datatype ('a,'b) task = DONE of 'b | DELAY of 'a -> 'b
        val graph =
            MetaID.Map.map
              (fn x => (ref (DELAY f), #id x, x))
              graph
        fun get (id, (ref (DONE x), _, _)) = x
          | get (id, (r as ref (DELAY f), id2, old)) =
            if id = id2
            then (r := DELAY (fn _ => raise Cycle);
                  let val new = f (getById, old) in r := DONE new; new end)
            else let val new = getById id2 in r := DONE new; new end
        and getById id =
            case MetaID.Map.find (graph, id) of
              SOME x => get (id, x)
            | NONE => raise NotFound
      in
        MetaID.Map.mapi get graph
      end

  fun check graph =
      traverse
        (fn (get, {id, instances = ref instances}) =>
            {id = id,
             instances = instances,
             adj = MetaID.Set.map (#id o get) (getIdsInstances instances)
            }
            handle Cycle =>
                   {id = id,
                    instances = [UNDEF],
                    adj = MetaID.Set.empty})
        (MetaID.Map.map UnionFind.find graph)

(*
  fun kindOf btvKinds ty =
      (* if a free type variable of ty is of EMPTY kind, the entire type
       * is also of EMPTY kind *)
      if BoundTypeVarID.Set.exists
           (fn tid => case BoundTypeVarID.Map.find (btvKinds, tid) of
                        SOME EMPTY => true
                      | _ => false)
           (TypesBasics.EFBTV ty)
      then EMPTY
      else case TypeLayout2.tagOf'
                  (TypeLayout2.runtimeTy
                     (BoundTypeVarID.Map.map toTypeKind btvKinds)
                     ty) of
             SOME R.TAG_UNBOXED => UNBOXED
             SOME R.TAG_UNBOXED => UNIV
           | SOME R.TAG_BOXED => BOXED
           | NONE => UNIV

  fun kindOf' ty =
      kindOf BoundTypeVarID.Map.empty ty

  fun lub (POLY EMPTY, x) = x
    | lub (x, POLY EMPTY) = x
    | lub (POLY UNIV, _) = POLY UNIV
    | lub (_, POLY UNIV) = POLY UNIV
    | lub (POLY BOXED, POLY BOXED) = POLY BOXED
    | lub (POLY BOXED, POLY UNBOXED) = POLY UNIV
    | lub (POLY BOXED, MONO ty) = lub (POLY BOXED, POLY (kindOf' ty))
    | lub (POLY UNBOXED, POLY UNBOXED) = POLY UNBOXED
    | lub (POLY UNBOXED, POLY BOXED) = POLY UNIV
    | lub (POLY UNBOXED, MONO ty) = lub (POLY UNBOXED, POLY (kindOf' ty))
    | lub (MONO ty, POLY BOXED) = lub (POLY BOXED, POLY (kindOf' ty))
    | lub (MONO ty, POLY UNBOXED) = lub (POLY UNBOXED, POLY (kindOf' ty))
    | lub (MONO ty1, MONO ty2) =
      if equalTy (ty1, ty2)
      then MONO ty1
      else lub (POLY (kindOf' ty1), POLY (kindOf' ty2))
*)
  fun instOf btvKinds ty =
      if BoundTypeVarID.Set.exists
           (fn tid => case BoundTypeVarID.Map.find (btvKinds, tid) of
                        SOME EMPTY => true
                      | _ => false)
           (TypesBasics.EFBTV ty)
      then EMPTY
      else 
        let
          val ty = TypesBasics.derefTy ty
        in
          case ty of 
            T.BOUNDVARty tid => 
            (case BoundTypeVarID.Map.find(btvKinds, tid) of
               SOME inst => inst
             | _ => raise bug "inst not found in btvEnv"
            )
          | ty => POLY (DKU.kindOfTy ty)
        end

  fun instOf' ty = instOf BoundTypeVarID.Map.empty ty

  fun lubInst (EMPTY, x) = x
    | lubInst (x, EMPTY) = x
    | lubInst (MONO ty1, MONO ty2) =
      if equalTy (ty1, ty2)
      then MONO ty1
      else lubInst (instOf' ty1, instOf' ty2)
    | lubInst (MONO ty, POLY kind) = 
      lubInst (instOf' ty, POLY kind)
    | lubInst (POLY kind, MONO ty) = 
      lubInst (POLY kind, instOf' ty)
    | lubInst (POLY d1, POLY d2) = POLY (DKU.lubKind(d1, d2))

  fun lubList nil = EMPTY
    | lubList (x :: nil) = x
    | lubList (x :: h :: t) = 
      lubList (lubInst (x, h) :: t)

  fun evalInstance get UNDEF = POLY DK.topKind
    | evalInstance get (EXTERN kind) = POLY kind
    | evalInstance get (INST (tyvars, ty)) =
      let
        val instMap = BoundTypeVarID.Map.fromSet (get o MetaID.idOf) tyvars
        val btvKinds =
            BoundTypeVarID.Map.mapPartial
              (fn MONO _ => NONE | k => SOME k)
              instMap
        val subst =
            BoundTypeVarID.Map.mapi
              (fn (i, MONO ty) => ty | (i, _) => T.BOUNDVARty i)
              instMap
        val ty = TypesBasics.substBTvar subst ty
      in
        if BoundTypeVarID.Map.isEmpty btvKinds
        then MONO ty
        else instOf btvKinds ty
      end

  fun calcInst graph =
      traverse
        (fn (get, {id, instances, adj}) =>
            lubList (map (evalInstance get) instances))
        graph

(*
  (* if k is upper than kind and kind is not empty, replace k with kind. *)
  fun mergeKind (k as T.KIND (r as {tvarKind,properties,dynamicKind}), kind) =
      case (kind, tvarKind) of
        (UNIV, _) => k
      | (EMPTY, _) => k
      | (BOXED, T.OCONSTkind _) => k
      | (BOXED, T.OPRIMkind _) => k
      | (BOXED, T.UNIV) => 
        T.KIND {tvarKind = tvarKind,
                properties = if T.isBoxedProperties properties then properties 
                             else T.BOXED :: properties,
                dynamicKind = dynamicKind
               }
      | (BOXED, T.REC _) => k
*)

  type c_env =
      {env : D.env,
       subst : Types.ty BoundTypeVarID.Map.map,
       instEnv : inst MetaID.Map.map,
       dummyTyId : DummyTyID.id}

  fun dummyTy ({dummyTyId, ...}:c_env) =
      T.DUMMYty (dummyTyId, #kind (T.univKind))

  fun dummyExp env loc =
      D.TPCAST
        ((D.TPCONSTANT
            {const = AbsynConst.INT 0,
             ty = BuiltinTypes.int32Ty,
             loc = loc},
          BuiltinTypes.int32Ty),
         dummyTy env,
         loc)

  fun compileTy (env:c_env) ty =
      case ty of
        T.SINGLETONty sty =>
        T.SINGLETONty (compileSingletonTy env sty)
      | T.DUMMYty (id, kind) =>
        T.DUMMYty (id, compileKind env kind)
      | T.EXISTty (id, kind) =>
        T.EXISTty (id, compileKind env kind)
      | T.TYVARty (ref (T.SUBSTITUTED ty)) => compileTy env ty
      | T.BOUNDVARty id =>
        (case BoundTypeVarID.Map.find (#subst env, id) of
           NONE => raise bug "compileTy: BOUNDVARty"
         | SOME ty => ty)
      | T.FUNMty (argTys, retTy) =>
        T.FUNMty (map (compileTy env) argTys, compileTy env retTy)
      | T.RECORDty fields =>
        T.RECORDty (RecordLabel.Map.map (compileTy env) fields)
      | T.CONSTRUCTty {tyCon, args} =>
        T.CONSTRUCTty {tyCon = tyCon, args = map (compileTy env) args}
      | T.POLYty {boundtvars, constraints, body} =>
        let
          val (env, btv) = compileBtvEnv env (boundtvars, constraints)
        in
          case btv of
            NONE => dummyTy env
          | SOME {btvEnv, constraints, ...} =>
            if BoundTypeVarID.Map.isEmpty btvEnv
            then compileTy env body
            else T.POLYty {boundtvars = btvEnv,
                           constraints = constraints,
                           body = compileTy env body}
        end
      | T.ERRORty =>
        raise bug "compileTy: ERRORty never occur"
      | T.BACKENDty bty =>
        T.BACKENDty (compileBackendTy env bty)
      | T.TYVARty (ref (T.TVAR _)) =>
        raise bug "compileTy: TVAR never occur"

  and compileBtvEnv env (btvEnv, constraints) =
      let
        val instMap =
            BoundTypeVarID.Map.mapi
              (fn (tid, kind) =>
                  (kind,
                   case MetaID.Map.find (#instEnv env, MetaID.idOf tid) of
                     SOME x => x
                   | NONE => raise bug "compileBtvEnv"))
              btvEnv
        val subst =
            BoundTypeVarID.Map.mapi
              (fn (_, (_, MONO ty)) => ty
                | (i, (_, _)) => T.BOUNDVARty i)
              instMap
        val envTmp =
            env # {subst = BoundTypeVarID.Map.unionWith #2 (#subst env, subst)}
        val btvEnv =
            BoundTypeVarID.Map.mapPartial
              (fn (kind, MONO _) => NONE
                | (kind, EMPTY) => NONE
                | (T.KIND {properties, tvarKind, dynamicKind = _},
                   POLY dynamicKind) =>
                  SOME (T.KIND {properties = properties,
                                tvarKind = compileTvarKind envTmp tvarKind,
                                dynamicKind = SOME dynamicKind}))
              instMap
        val env =
            extendBtvEnv env btvEnv
            # {subst = BoundTypeVarID.Map.unionWith #2 (#subst env, subst)}
      in
        (env,
         if BoundTypeVarID.Map.all
              (fn (_, EMPTY) => false | _ => true)
              instMap
         then SOME {btvEnv = btvEnv,
                    constraints = map (compileConstraint env) constraints,
                    subst = subst}
         else NONE)
      end

  and compileConstraint env (T.JOIN {res, args=(ty1, ty2), loc}) =
      T.JOIN {res = compileTy env res,
              args = (compileTy env ty1, compileTy env ty2),
              loc = loc}

  and compileBackendTy env backendTy =
      case backendTy of
        T.RECORDSIZEty ty =>
        T.RECORDSIZEty (compileTy env ty)
      | T.RECORDBITMAPINDEXty (i, ty) =>
        T.RECORDBITMAPINDEXty (i, compileTy env ty)
      | T.RECORDBITMAPty (i, ty) =>
        T.RECORDBITMAPty (i, compileTy env ty)
      | T.CCONVTAGty codeEntryTy =>
        T.CCONVTAGty (compileCodeEntryTy env codeEntryTy)
      | T.FUNENTRYty codeEntryTy =>
        T.FUNENTRYty (compileCodeEntryTy env codeEntryTy)
      | T.CALLBACKENTRYty {tyvars, haveClsEnv, argTyList, retTy, attributes} =>
        let
          val (env, btv) = compileBtvEnv env (tyvars, nil)
          val btvEnv =
              case btv of
                NONE => BoundTypeVarID.Map.empty
              | SOME {btvEnv, ...} => btvEnv
        in
          T.CALLBACKENTRYty
            {tyvars = btvEnv,
             haveClsEnv = haveClsEnv,
             argTyList = map (compileTy env) argTyList,
             retTy = Option.map (compileTy env) retTy,
             attributes = attributes}
        end
      | T.SOME_FUNENTRYty => T.SOME_FUNENTRYty
      | T.SOME_FUNWRAPPERty => T.SOME_FUNWRAPPERty
      | T.SOME_CLOSUREENVty => T.SOME_CLOSUREENVty
      | T.SOME_CCONVTAGty => T.SOME_CCONVTAGty
      | T.FOREIGNFUNPTRty {argTyList, varArgTyList, resultTy, attributes} =>
        T.FOREIGNFUNPTRty
          {argTyList = map (compileTy env) argTyList,
           varArgTyList = Option.map (map (compileTy env)) varArgTyList,
           resultTy = Option.map (compileTy env) resultTy,
           attributes = attributes}

  and compileCodeEntryTy env {tyvars, haveClsEnv, argTyList, retTy} =
        let
          val (env, btv) = compileBtvEnv env (tyvars, nil)
          val btvEnv =
              case btv of
                NONE => BoundTypeVarID.Map.empty
              | SOME {btvEnv, ...} => btvEnv
        in
          {tyvars = btvEnv,
           haveClsEnv = haveClsEnv,
           argTyList = map (compileTy env) argTyList,
           retTy = compileTy env retTy}
        end

  and compileSingletonTy env sty =
      case sty of
        T.INSTCODEty selector =>
        T.INSTCODEty (compileOprimSelector env selector)
      | T.INDEXty (label, ty) => T.INDEXty (label, compileTy env ty)
      | T.TAGty ty => T.TAGty (compileTy env ty)
      | T.SIZEty ty => T.SIZEty (compileTy env ty)
      | T.REIFYty ty => T.REIFYty (compileTy env ty)

  and compileOprimSelector env {oprimId, longsymbol, match} =
      {oprimId = oprimId,
       longsymbol = longsymbol,
       match = compileOverloadMatch env match}
      : Types.oprimSelector

  and compileOverloadMatch env match =
      case match of
        T.OVERLOAD_EXVAR {exVarInfo, instTyList} =>
        T.OVERLOAD_EXVAR
          {exVarInfo = exVarInfo,
           instTyList = Option.map (map (compileTy env)) instTyList}
      | T.OVERLOAD_PRIM {primInfo, instTyList} =>
        T.OVERLOAD_PRIM
          {primInfo = primInfo,
           instTyList = Option.map (map (compileTy env)) instTyList}
      | T.OVERLOAD_CASE (ty, matches) =>
        T.OVERLOAD_CASE
          (compileTy env ty,
           TypID.Map.map (compileOverloadMatch env) matches)

  and compileKind env (T.KIND {properties, tvarKind, dynamicKind}) =
      T.KIND
        {tvarKind = compileTvarKind env tvarKind,
         properties = properties,
         dynamicKind = dynamicKind
        }

  and compileTvarKind env tvarKind =
      case tvarKind of
        T.OCONSTkind tys =>
        T.OCONSTkind (map (compileTy env) tys)
      | T.OPRIMkind {instances, operators} =>
        T.OPRIMkind
          {instances = map (compileTy env) instances,
           operators = map (compileOprimSelector env) operators}
      | T.UNIV => T.UNIV
      | T.REC fields => T.REC (RecordLabel.Map.map (compileTy env) fields)

  fun benchmark (oldBtvEnv, NONE) =
      BoundTypeVarID.Map.app (fn _ => inc countEmpty) oldBtvEnv
    | benchmark (oldBtvEnv, SOME {btvEnv, ...}) =
      let
        fun dynamicKindOf (T.KIND {dynamicKind = SOME d, ...}) = d
          | dynamicKindOf (kind as T.KIND {dynamicKind = NONE, ...}) =
            case DKU.kindOfStaticKind kind of
              NONE => raise Bug.Bug "dynamicKindOf"
            | SOME d => d
        val oldBtvEnv = BoundTypeVarID.Map.map dynamicKindOf oldBtvEnv
        val btvEnv = BoundTypeVarID.Map.map dynamicKindOf btvEnv
      in
        (BoundTypeVarID.Map.mergeWith
           (fn (SOME _, NONE) => (inc countSubst; NONE)
             | (SOME k1, SOME k2) =>
               if DKU.eqKind (k1, k2)
               then (inc countKeep; NONE)
               else
                 (inc countOptimized;
                  case (#size k1, #size k2) of
                    (DK.ANYSIZE, DK.SIZE s) =>
                    (case DK.getSize s of
                       1 => inc countSize1
                     | 2 => inc countSize2
                     | 4 => inc countSize4
                     | 8 => inc countSize8
                     | _ => ())
                  | _ => ();
                  case (#tag k1, #tag k2) of
                    (DK.ANYTAG, DK.TAG DK.BOXED) => inc countBoxed
                  | (DK.ANYTAG, DK.TAG DK.UNBOXED) => inc countUnboxed
                  | _ => ();
                  RecordLabel.Map.mergeWith
                    (fn (NONE, SOME _) => SOME (inc countRecord) | _ => NONE)
                    (#record k1, #record k2);
                  NONE)
             | (NONE, _) => NONE)
           (oldBtvEnv, btvEnv));
        ()
      end

  fun single (x:C.tpdecl, y:D.env) = ([x], y)
  fun multi decs : C.tpdecl list * D.env =
      (map #1 decs,
       foldl (fn ((_, x), z) => D.extendEnv (z, x)) D.emptyEnv decs)

  fun compileFFIty env ffity =
      case ffity of
        C.FFIBASETY (ty, loc) =>
        C.FFIBASETY (compileTy env ty, loc)
      | C.FFIFUNTY (attributes, argTys, varArgTys, retTys, loc) =>
        C.FFIFUNTY
          (attributes,
           map (compileFFIty env) argTys,
           Option.map (map (compileFFIty env)) varArgTys,
           map (compileFFIty env) retTys,
           loc)
      | C.FFIRECORDTY (fields, loc) =>
        C.FFIRECORDTY
          (map (fn (label, ffity) => (label, compileFFIty env ffity)) fields,
           loc)

  fun compileVarInfo env (var : Types.varInfo) : Types.varInfo =
      var # {ty = compileTy env (#ty var)}

  fun compileExnInfo env (exn : Types.exnInfo) : Types.exnInfo =
      exn # {ty = compileTy env (#ty exn)}

  fun compileExnCon (env:c_env) exncon =
      case exncon of
        C.EXN exnInfo =>
        (case ExnID.Map.find (#exnEnv (#env env), #id exnInfo) of
           NONE => raise bug "compileExnCon: TPEXN"
         | SOME {ty,...} => C.EXN (exnInfo # {ty = ty}))
      | C.EXEXN exExnInfo =>
        (case LongsymbolEnv.find (#exExnEnv (#env env), #path exExnInfo) of
           NONE => raise bug "compileExnCon: TPEXEXN"
         | SOME {ty,...} => C.EXEXN (exExnInfo # {ty = ty}))

  fun compilePat env tppat =
      case tppat of
        C.TPPATERROR _ => D.TPPATERROR
      | C.TPPATCONSTANT (constant, ty, loc) =>
        D.TPPATCONSTANT
          (constant,
           compileTy env ty,
           loc)
      | C.TPPATDATACONSTRUCT {argPatOpt, conPat, instTyList, loc, patTy} =>
        D.TPPATDATACONSTRUCT
          {conPat = conPat,
           instTyList = Option.map (map (compileTy env)) instTyList,
           argPatOpt = Option.map (compilePat env) argPatOpt,
           loc = loc}
      | C.TPPATEXNCONSTRUCT {argPatOpt, exnPat, loc, patTy} =>
        D.TPPATEXNCONSTRUCT
          {exnPat = compileExnCon env exnPat,
           argPatOpt = Option.map (compilePat env) argPatOpt,
           loc = loc}
      | C.TPPATLAYERED {asPat, loc, varPat} =>
        D.TPPATLAYERED
          {asPat = compilePat env asPat,
           varPat = compilePat env varPat,
           loc = loc}
      | C.TPPATRECORD {fields, loc, recordTy} =>
        D.TPPATRECORD
          (SOME (#btvEnv (#env env)))
          {fields = RecordLabel.Map.map (compilePat env) fields,
           recordTy = SOME (compileTy env recordTy),
           loc = loc}
      | C.TPPATVAR var =>
        D.TPPATVAR (compileVarInfo env var)
      | C.TPPATWILD (ty, loc) =>
        D.TPPATWILD (compileTy env ty, loc)

  fun compileVar env (var as {id, ...}:T.varInfo) =
      case VarID.Map.find (#varEnv (#env env), id) of
        NONE => raise bug ("compileVar: " ^ VarID.toString id)
      | SOME {ty,...} => var # {ty = ty}

  fun compileExp (env:c_env) tpexp =
      case tpexp of
        C.TPERROR => D.TPERROR
      | C.TPCONSTANT {const, ty, loc} =>
        D.TPCONSTANT {const = const, ty = compileTy env ty, loc = loc}
      | C.TPSIZEOF (ty, loc) =>
        D.TPSIZEOF (compileTy env ty, loc)
      | C.TPREIFYTY (ty, loc) =>
        D.TPREIFYTY (compileTy env ty, loc)
      | C.TPEXNTAG {exnInfo, loc} =>
        (case ExnID.Map.find (#exnEnv (#env env), #id exnInfo) of
           NONE => raise bug "compileExp: TPEXNTAG"
         | SOME {ty,...} =>
           D.TPEXNTAG {exnInfo = exnInfo # {ty = ty}, loc = loc})
      | C.TPEXEXNTAG {exExnInfo, loc} =>
        (case LongsymbolEnv.find (#exExnEnv (#env env), #path exExnInfo) of
           NONE => raise bug "compileExp: TPEXNTAG"
         | SOME {ty,...} =>
           D.TPEXEXNTAG {exExnInfo = exExnInfo # {ty = ty}, loc = loc})
      | C.TPEXVAR (var, loc) =>
        (case LongsymbolEnv.find (#exVarEnv (#env env), #path var) of
           NONE => 
           (
            print "TPEXVAR\n";
            print (Symbol.longsymbolToString (#path var));
            print "\n";
            raise bug "compileExp: TPEXVAR"
           )
         | SOME {ty,...} => D.TPEXVAR (var # {ty = ty}, loc))
      | C.TPVAR var =>
        D.TPVAR (compileVar env var)
      | C.TPRECFUNVAR {arity, var} =>
        D.TPRECFUNVAR {arity = arity, var = compileVar env var}
      | C.TPCAST ((exp, ty1), ty2, loc) =>
        D.TPCAST
          ((compileExp env exp, compileTy env ty1),
           compileTy env ty2,
           loc)
      | C.TPDATACONSTRUCT {argExpOpt, con, instTyList, loc} =>
        D.TPDATACONSTRUCT
          {con = con,
           instTyList = Option.map (map (compileTy env)) instTyList,
           argExpOpt = Option.map (compileExp env) argExpOpt,
           loc = loc}
      | C.TPEXNCONSTRUCT {argExpOpt, exn, loc} =>
        D.TPEXNCONSTRUCT
          {exn = compileExnCon env exn,
           argExpOpt = Option.map (compileExp env) argExpOpt,
           loc = loc}
      | C.TPFFIIMPORT {funExp = C.TPFFIFUN (funExp, _), ffiTy, stubTy, loc} =>
        D.TPFFIIMPORT_FUN
          {funExp = compileExp env funExp,
           ffiTy = compileFFIty env ffiTy,
           loc = loc}
      | C.TPFFIIMPORT {funExp = C.TPFFIEXTERN symbol, ffiTy, stubTy, loc} =>
        D.TPFFIIMPORT_EXT
          {funExp = symbol,
           ffiTy = compileFFIty env ffiTy,
           loc = loc}
      | C.TPFOREIGNSYMBOL {name, ty, loc} =>
        D.TPFOREIGNSYMBOL
          {name = name,
           ty = compileTy env ty,
           loc = loc}
      | C.TPFOREIGNAPPLY {funExp, argExpList, attributes, resultTy, loc} =>
        D.TPFOREIGNAPPLY
          {funExp = compileExp env funExp,
           argExpList = map (compileExp env) argExpList,
           loc = loc}
      | C.TPCALLBACKFN {attributes, argVarList, bodyExp, resultTy, loc} =>
        let
          val argVarList = map (compileVarInfo env) argVarList
        in
          D.TPCALLBACKFN
            {attributes = attributes,
             argVarList = argVarList,
             bodyExp = compileExp (addVars env argVarList) bodyExp,
             isVoid = not (isSome resultTy),
             loc = loc}
        end
      | C.TPTAPP {exp, expTy, instTyList, loc} =>
        let
          val {boundtvars = oldbtv, ...} =
              case TypesBasics.derefTy expTy of
                T.POLYty x => x
              | _ => raise bug "compileExp: TPTAPP"
          val exp as (_, expTy) = compileExp env exp
          val instTyList = map (compileTy env) instTyList
          val oldInstMap =
              ListPair.foldlEq
                (fn (tid, ty, z) => BoundTypeVarID.Map.insert (z, tid, ty))
                BoundTypeVarID.Map.empty
                (BoundTypeVarID.Map.listKeys oldbtv, instTyList)
              handle ListPair.UnequalLengths =>
                     raise bug "compileExp: TPTAPP"
          val newbtv =
              case TypesBasics.derefTy expTy of
                T.POLYty {boundtvars, ...} => boundtvars
              | _ => BoundTypeVarID.Map.empty
          val newInstMap =
              BoundTypeVarID.Map.mapPartiali
                (fn (tid, _) => BoundTypeVarID.Map.find (oldInstMap, tid))
                newbtv
        in
          if BoundTypeVarID.Map.isEmpty newInstMap
          then exp
          else D.TPTAPP
                 {exp = exp,
                  instTyList = BoundTypeVarID.Map.listItems newInstMap,
                  loc = loc}
        end
      | C.TPPOLY {btvEnv, constraints, exp, expTyWithoutTAbs, loc} =>
        let
          val (env, btv) = compileBtvEnv env (btvEnv, constraints)
          val _ =
              if !Control.verbosePolyTyElim > 0
              then benchmark (btvEnv, btv)
              else ()
        in
          case btv of
            NONE => dummyExp env loc
          | SOME {btvEnv=newBtvEnv, constraints, ...} =>
            if BoundTypeVarID.Map.isEmpty newBtvEnv
            then compileExp env exp
            else D.TPPOLY
                   {btvEnv = newBtvEnv,
                    constraints = constraints,
                    exp = compileExp env exp,
                    loc = loc}
        end
      | C.TPFNM {argVarList, bodyExp, bodyTy, loc} =>
        let
          val argVarList = map (compileVarInfo env) argVarList
        in
          D.TPFNM
            {argVarList = argVarList,
             bodyExp = compileExp (addVars env argVarList) bodyExp,
             loc = loc}
        end
      | C.TPAPPM {funExp, funTy, argExpList, loc} =>
        D.TPAPPM
          {funExp = compileExp env funExp,
           argExpList = map (compileExp env) argExpList,
           loc = loc}
      | C.TPCASEM {caseKind, expList, expTyList, loc, ruleBodyTy, ruleList} =>
        D.TPCASEM
          {caseKind = caseKind,
           expList = map (compileExp env) expList,
           ruleList = map (compileMatch env) ruleList,
           loc = loc}
      | C.TPSWITCH {exp, expTy, ruleList = C.CONSTCASE rules,
                    defaultExp, ruleBodyTy, loc} =>
        D.TPSWITCH_CONSTCASE
          {exp = compileExp env exp,
           ruleList = map (fn {const, ty, body} =>
                              {const = const,
                               ty = compileTy env ty,
                               body = compileExp env body})
                          rules,
           defaultExp = compileExp env defaultExp,
           loc = loc}
      | C.TPSWITCH {exp, expTy, ruleList = C.CONCASE rules,
                    defaultExp, ruleBodyTy, loc} =>
        D.TPSWITCH_CONCASE
          {exp = compileExp env exp,
           ruleList =
             map (fn {con, instTyList, argVarOpt, body} =>
                     let
                       val argVarOpt = Option.map (compileVarInfo env) argVarOpt
                       val env2 = addVars env (optionToList argVarOpt)
                     in
                       {con = con,
                        instTyList =
                          Option.map (map (compileTy env)) instTyList,
                        argVarOpt = argVarOpt,
                        body = compileExp env2 body}
                     end)
                 rules,
           defaultExp = compileExp env defaultExp,
           loc = loc}
      | C.TPSWITCH {exp, expTy, ruleList = C.EXNCASE rules,
                    defaultExp, ruleBodyTy, loc} =>
        D.TPSWITCH_EXNCASE
          {exp = compileExp env exp,
           ruleList =
             map (fn {exn, argVarOpt, body} =>
                     let
                       val argVarOpt = Option.map (compileVarInfo env) argVarOpt
                       val env2 = addVars env (optionToList argVarOpt)
                     in
                       {exn = compileExnCon env exn,
                        argVarOpt = argVarOpt,
                        body = compileExp env2 body}
                     end)
                 rules,
           defaultExp = compileExp env defaultExp,
           loc = loc}
      | C.TPTHROW {catchLabel, argExpList, resultTy, loc} =>
        D.TPTHROW
          {catchLabel = catchLabel,
           argExpList = map (compileExp env) argExpList,
           resultTy = compileTy env resultTy,
           loc = loc}
      | C.TPCATCH {catchLabel, tryExp, argVarList, catchExp, resultTy, loc} =>
        let
          val argVarList = map (compileVarInfo env) argVarList
        in
          D.TPCATCH
            {catchLabel = catchLabel,
             tryExp = compileExp env tryExp,
             argVarList = argVarList,
             catchExp = compileExp (addVars env argVarList) catchExp,
             loc = loc}
        end
      | C.TPLET {decls, body, loc} =>
        let
          val (decls, env) = compileDeclList env decls
        in
          D.TPLET
            {decls = decls,
             body = compileExp env body,
             loc = loc}
        end
      | C.TPMONOLET {binds, bodyExp, loc} =>
        let
          val (binds, env) = compileMonoLet env binds
        in
          D.TPMONOLET
            {binds = binds,
             bodyExp = compileExp env bodyExp,
             loc = loc}
        end
      | C.TPRAISE {exp, ty, loc} =>
        D.TPRAISE
          {exp = compileExp env exp,
           ty = compileTy env ty,
           loc = loc}
      | C.TPHANDLE {exp, exnVar, handler, resultTy, loc} =>
        let
          val exnVar = compileVarInfo env exnVar
        in
          D.TPHANDLE
            {exp = compileExp env exp,
             exnVar = exnVar,
             handler = compileExp (addVars env [exnVar]) handler,
             loc = loc}
        end
      | C.TPRECORD {fields, loc, recordTy} =>
        D.TPRECORD
          {fields = RecordLabel.Map.map (compileExp env) fields,
           loc = loc}
      | C.TPSELECT {exp, expTy, label, loc, resultTy} =>
        D.TPSELECT
          (SOME (#btvEnv (#env env)))
          {exp = compileExp env exp,
           label = label,
           loc = loc}
      | C.TPMODIFY {elementExp, elementTy, label, loc, recordExp, recordTy} =>
        D.TPMODIFY
          (SOME (#btvEnv (#env env)))
          {recordExp = compileExp env recordExp,
           label = label,
           elementExp = compileExp env elementExp,
           loc = loc}
      | C.TPPRIMAPPLY {argExp, instTyList, loc, primOp} =>
        D.TPPRIMAPPLY
          {primOp = primOp,
           instTyList = Option.map (map (compileTy env)) instTyList,
           argExp = compileExp env argExp,
           loc = loc}
      | C.TPOPRIMAPPLY {argExp, instTyList, loc, oprimOp} =>
        D.TPOPRIMAPPLY
          {oprimOp = oprimOp,
           instTyList = map (compileTy env) instTyList,
           argExp = compileExp env argExp,
           loc = loc}
      | C.TPJOIN {isJoin, args=(tpexp1, tpexp2), argtys, ty, loc} =>
        D.TPJOIN
          {args = (compileExp env tpexp1, compileExp env tpexp2),
           ty = compileTy env ty,
           isJoin = isJoin,
           loc = loc}
      | C.TPDYNAMIC {exp, ty, elemTy, coerceTy, loc} =>
        D.TPDYNAMIC
          {exp = compileExp env exp,
           elemTy = compileTy env elemTy,
           coerceTy = compileTy env coerceTy,
           loc = loc}
      | C.TPDYNAMICIS {exp, ty, elemTy, coerceTy, loc} =>
        D.TPDYNAMICIS
          {exp = compileExp env exp,
           elemTy = compileTy env elemTy,
           coerceTy = compileTy env coerceTy,
           loc = loc}
      | C.TPDYNAMICVIEW {exp, ty, elemTy, coerceTy, loc} =>
        D.TPDYNAMICVIEW
          {exp = compileExp env exp,
           elemTy = compileTy env elemTy,
           coerceTy = compileTy env coerceTy,
           loc = loc}
      | C.TPDYNAMICNULL {ty, coerceTy, loc} =>
        D.TPDYNAMICNULL
          {ty = compileTy env ty,
           coerceTy = compileTy env coerceTy,
           loc = loc}
      | C.TPDYNAMICTOP {ty, coerceTy, loc} =>
        D.TPDYNAMICTOP
          {ty = compileTy env ty,
           coerceTy = compileTy env coerceTy,
           loc = loc}
      | C.TPDYNAMICCASE {groupListTerm, 
                         groupListTy, dynamicTerm, dynamicTy, elemTy, ruleBodyTy, loc} => 
        D.TPDYNAMICCASE
          {
           groupListTerm = compileExp env groupListTerm,
           groupListTy = compileTy env groupListTy,
           dynamicTerm = compileExp env dynamicTerm,
           dynamicTy = compileTy env dynamicTy,
           elemTy = compileTy env elemTy,
           ruleBodyTy = compileTy env ruleBodyTy,
           loc = loc}
      | C.TPDYNAMICEXISTTAPP {existInstMap, exp, expTy=_, instTyList, loc} =>
        D.TPDYNAMICEXISTTAPP
          {existInstMap = compileExp env existInstMap,
           exp = compileExp env exp,
           instTyList = map (compileTy env) instTyList,
           loc = loc}

  and compileMatch env {args, body} =
      let
        val args = map (compilePat env) args
        val body = compileExp (extendVarEnv env (D.patVars args)) body
      in
        {args = args, body = body}
      end

  and compileMonoLet env nil = (nil, env)
    | compileMonoLet env ((var, exp)::binds) =
      let
        val exp as (_, expTy) = compileExp env exp
        val var = var # {ty = expTy}
        val env = addVars env [var]
        val (binds, env) = compileMonoLet env binds
      in
        ((var, exp) :: binds, env)
      end

  and compileDeclList env nil = (nil, env)
    | compileDeclList env (dec::decs) =
      let
        val (decs1, env1) = compileDecl env dec
        val (decs2, env) = compileDeclList (extendEnv env env1) decs
      in
        (decs1 @ decs2, env)
      end

  and compileDecl env tpdecl =
      case tpdecl of
        C.TPEXD (exnInfo, loc) =>
        single
          (D.TPEXD
             (compileExnInfo env exnInfo,
              loc))
      | C.TPEXNTAGD ({exnInfo, varInfo}, loc) =>
        let
          val exnInfo = compileExnInfo env exnInfo
          val varInfo =
              case VarID.Map.find (#varEnv (#env env), #id varInfo) of
                NONE => raise bug "compileDecl: TPEXNTAGD"
              | SOME {ty,...} => varInfo # {ty = ty}
        in
          single (D.TPEXNTAGD ({exnInfo = exnInfo, varInfo = varInfo}, loc))
        end
      | C.TPEXPORTEXN x =>
        single (D.TPEXPORTEXN x)
      | C.TPBUILTINEXN x =>
        single (D.TPBUILTINEXN x)
      | C.TPEXPORTVAR {var, exp} =>
        (* The type of var may not be changed. *)
        single (D.TPEXPORTVAR {var = var, exp = compileExp env exp})
      | C.TPEXTERNEXN x =>
        single (D.TPEXTERNEXN x)
      | C.TPEXTERNVAR x =>
        single (D.TPEXTERNVAR x)
      | C.TPVAL ((var, exp), loc) =>
        single
          (D.TPVAL
             ((compileVarInfo env var, compileExp env exp),
              loc))
      | C.TPVALREC (recbinds, loc) =>
        single
          (D.TPVALREC
             (compileRecbinds env recbinds,
              loc))
      | C.TPVALPOLYREC {btvEnv, constraints, recbinds, loc} =>
        let
          val (env, btv) = compileBtvEnv env (btvEnv, constraints)
          val _ =
              if !Control.verbosePolyTyElim > 0
              then benchmark (btvEnv, btv)
              else ()
        in
          case btv of
            NONE =>
            multi
              (map (fn {var, ...} =>
                       D.TPVAL ((var # {ty = dummyTy env}, dummyExp env loc),
                                loc))
                   recbinds)
          | SOME {btvEnv=newBtvEnv, constraints, ...} =>
            if BoundTypeVarID.Map.isEmpty newBtvEnv
            then single (D.TPVALREC (compileRecbinds env recbinds, loc))
            else single
                   (D.TPVALPOLYREC
                      {btvEnv = newBtvEnv,
                       constraints = constraints,
                       recbinds = compileRecbinds env recbinds,
                       loc = loc})
        end
      | C.TPFUNDECL (recbinds, loc) =>
        single (D.TPFUNDECL (compileFunRecbinds env recbinds, loc))
      | C.TPPOLYFUNDECL {btvEnv, constraints, recbinds, loc} =>
        let
          val (env, btv) = compileBtvEnv env (btvEnv, constraints)
          val _ =
              if !Control.verbosePolyTyElim > 0
              then benchmark (btvEnv, btv)
              else ()
        in
          case btv of
            NONE =>
            multi
              (map (fn {funVarInfo = var, ...} =>
                       D.TPVAL ((var # {ty = dummyTy env}, dummyExp env loc),
                                loc))
                   recbinds)
          | SOME {btvEnv=newBtvEnv, constraints, ...} =>
            if BoundTypeVarID.Map.isEmpty newBtvEnv
            then single (D.TPFUNDECL (compileFunRecbinds env recbinds, loc))
            else single
                   (D.TPPOLYFUNDECL
                      {btvEnv = newBtvEnv,
                       constraints = constraints,
                       recbinds = compileFunRecbinds env recbinds,
                       loc = loc})
        end

  and compileRecbinds env recbinds =
      let
        val recbinds =
            map (fn {var, exp} =>
                    {var = compileVarInfo env var, exp = exp})
                recbinds
        val env = addVars env (map #var recbinds)
      in
        map (fn {var, exp} => {var = var, exp = compileExp env exp}) recbinds
      end

  and compileFunRecbinds env recbinds =
      let
        val recbinds =
            map (fn {funVarInfo, ruleList, ...} =>
                    {funVarInfo = compileVarInfo env funVarInfo,
                     ruleList = ruleList})
                recbinds
        val env = addVars env (map #funVarInfo recbinds)
      in
        map (fn {funVarInfo, ruleList} =>
                {funVarInfo = funVarInfo,
                 ruleList = map (compileMatch env) ruleList})
            recbinds
      end

  fun compile tpdecls =
      let

        val result = ref MetaID.Map.empty

        val (tpdecls, _) =
            analyzeDeclList
              result
              {env = D.emptyEnv,
               subst = BoundTypeVarID.Map.empty}
              tpdecls

        val _ =
            if !Control.verbosePolyTyElim > 1
            then
              let fun p "" = () | p s = (print s; print "\n")
              in print "===== PolyTyElim Source begin =====\n";
                 app (p o Bug.prettyPrint o C.formatWithType_tpdecl)
                     tpdecls;
                 print "===== PolyTyElim Source end =====\n"
              end
            else ()

        val instDag = check (!result)

        val _ =
            if !Control.verbosePolyTyElim > 1
            then
              (print "===== Instance Universes begin =====\n";
               print
                 (Bug.prettyPrint
                    (format_instancesMap
                      (MetaID.Map.toBtvMap
                         (MetaID.Map.map
                            #instances
                            instDag))));
               print "\n===== Instance Universes end =====\n")
            else ()

        val instEnv = calcInst instDag

        val _ =
            if !Control.verbosePolyTyElim > 1
            then
              (print "===== Least Upper Bounds begin =====\n";
               print
                 (Bug.prettyPrint
                    (format_instMap
                       (MetaID.Map.toBtvMap
                          instEnv)));
               print "\n===== Least Upper Bounds end =====\n")
            else ()

        val _ =
            if !Control.verbosePolyTyElim > 0
            then (countSubst := 0;
                  countOptimized := 0;
                  countBoxed := 0;
                  countUnboxed := 0;
                  countSize1 := 0;
                  countSize2 := 0;
                  countSize4 := 0;
                  countSize8 := 0;
                  countRecord := 0;
                  countEmpty := 0;
                  countKeep := 0)
            else ()

        val (tpdecls, _) =
            compileDeclList
              {env = D.emptyEnv,
               subst = BoundTypeVarID.Map.empty,
               instEnv = instEnv,
               dummyTyId = DummyTyID.generate ()}
              tpdecls

        val _ =
            if !Control.verbosePolyTyElim > 0
            then
              (print "===== Summary begin =====";
               print ("\nnum of bound tyvars original: "
                      ^ Int.toString (!countSubst + !countOptimized
                                      + !countKeep + !countEmpty));
               print ("\nsubstituted: " ^ Int.toString (!countSubst));
               print ("\nboxed kind: " ^ Int.toString (!countBoxed));
               print ("\nunboxed kind: " ^ Int.toString (!countUnboxed));
               print ("\nsize 1: " ^ Int.toString (!countSize1));
               print ("\nsize 2: " ^ Int.toString (!countSize2));
               print ("\nsize 4: " ^ Int.toString (!countSize4));
               print ("\nsize 8: " ^ Int.toString (!countSize8));
               print ("\nrecord: " ^ Int.toString (!countRecord));
               print ("\ndead code: " ^ Int.toString (!countEmpty));
               print ("\nkeep original: " ^ Int.toString (!countKeep));
               print "\n===== Summary end =====\n")
            else ()

      in
        tpdecls
      end

end
