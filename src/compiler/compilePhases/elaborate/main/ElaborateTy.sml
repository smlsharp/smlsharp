(**
 * @copyright (C) 2025 SML# Development Team.
 * @author Katsuhiro Ueno
 * @author Atsushi Ohori
 * @author YAMATODANI Kiyoshi
 *)
structure ElaborateTy =
struct
  structure A = Absyn
  structure E = ElaborateError
  fun enqueueError (loc, exn) = UserErrorUtils.enqueueError (Loc.LOC loc, exn)

  type ftv = (Absyn.tyvar * Absyn.tyvar list) Symbol.Map.map

  fun seq NONE = nil
    | seq (SOME (items, _)) = items

  val empty = Symbol.Map.empty

  fun singleton (tyvar as (_, (symbol, _)) : A.tyvar) =
      Symbol.Map.singleton (symbol, (tyvar, nil))

  fun union (set1, set2) : ftv =
      Symbol.Map.unionWith
        (fn ((tv1, tvs1), (tv2, tvs2)) => (tv1, tvs1 @ tv2 :: tvs2))
        (set1, set2)

  fun unionList sets =
      foldl union Symbol.Map.empty sets

  fun intersect (set1, set2 : ftv) =
      Symbol.Map.mergeWith
        (fn (NONE, _) => NONE
          | (_, NONE) => NONE
          | (x as SOME _, SOME _) => x)
        (set1, set2)

  fun setMinus (set1, set2 : ftv) =
      Symbol.Map.mergeWith
        (fn (NONE, _) => NONE
          | (x, NONE) => x
          | (SOME _, SOME _) => NONE)
        (set1, set2)

  fun tyvarsToSet tyvars =
      foldl
        (fn (tyvar as (_, (symbol, _)) : A.tyvar, set) =>
            Symbol.Map.insert (set, symbol, (tyvar, nil)))
        Symbol.Map.empty
        tyvars

  fun tyvarseqToSet (tyvarseq : A.tyvarseq option) =
      tyvarsToSet (seq tyvarseq)

  fun kindedTyvarsToSet (tyvars : A.kinded_tyvar list) =
      tyvarsToSet (map #1 tyvars)

  fun kindedTyvarseqToSet (tyvarseq : A.kinded_tyvarseq option) =
      tyvarsToSet (map #1 (seq tyvarseq))

  fun toKindedTyvars (ftv : ftv) : A.kinded_tyvar list =
      map (fn (tv as (_, (_, loc)), _) => (tv, NONE, loc))
          (Symbol.Map.listItems ftv)

  fun ftvTyrow ((_, ty, _) : A.tyrow) =
      ftvTy ty

  and ftvKind kind =
      case kind of
        A.UNIV _ => Symbol.Map.empty
      | A.REC (_, rows, _) => unionList (map ftvTyrow rows)

  and ftvKindedTyvar ((_, NONE, _) : A.kinded_tyvar) = Symbol.Map.empty
    | ftvKindedTyvar (_, SOME kind, _) = ftvKind kind

  and ftvTy ty =
      case ty of
        A.TYVAR tyvar => singleton tyvar
      | A.TYRECORD (rows, _, _) => unionList (map ftvTyrow rows)
      | A.TYCON (tyseq, _, _) => unionList (map ftvTy (seq tyseq))
      | A.TYTUPLE (tys, _) => unionList (map ftvTy tys)
      | A.TYFUN (ty1, ty2, _) => union (ftvTy ty1, ftvTy ty2)
      | A.TYPAREN (ty, _) => ftvTy ty
      | A.TYWILD _ => Symbol.Map.empty
      | A.TYVAR_FREE tyvar => ftvKindedTyvar tyvar
      | A.TYPOLY (body as ((tyvars, _), ty, loc)) =>
        setMinus (union (unionList (map ftvKindedTyvar tyvars), ftvTy ty),
                  kindedTyvarsToSet tyvars)

  fun ftvKindedTyvarseq NONE = Symbol.Map.empty
    | ftvKindedTyvarseq (SOME (tyvars, _)) =
      unionList (map ftvKindedTyvar tyvars)

  fun ftvTypbind (tyvarseq, _, ty, _ : A.loc) =
      setMinus (ftvTy ty, tyvarseqToSet tyvarseq)

  fun ftvConbind (_, NONE, _) = Symbol.Map.empty
    | ftvConbind (_, SOME ty, _) = ftvTy ty

  fun ftvDatbind (tyvarseq, _, conbinds, _) =
      setMinus (unionList (map ftvConbind conbinds), tyvarseqToSet tyvarseq)

  val ftvWheretype = ftvTypbind

  val ftvDatdesc = ftvDatbind

  fun ftvSubst subst loc =
      Symbol.Map.foldl
        (fn (ty, z) => union (z, ftvTy (ty loc)))
        Symbol.Map.empty
        subst

  fun renameBtv captured tyvars =
      CompileUtils.mapAccum
        (fn subst => fn tyvar as ((eq, (symbol, loc1)), kind, loc2) =>
            if Symbol.Map.inDomain (captured, symbol) then
              let
                val newSymbol = Symbol.generate (SOME symbol)
                fun rename loc = A.TYVAR (eq, (newSymbol, loc))
                val subst = Symbol.Map.insert (subst, symbol, rename)
              in
                (subst, ((eq, (newSymbol, loc1)), kind, loc2) : A.kinded_tyvar)
              end
            else (subst, tyvar))
        Symbol.Map.empty
        tyvars

  fun substTyrow subst ((lab, ty, loc) : A.tyrow) =
      (lab, substTy subst ty, loc)

  and substKind subst kind =
      case kind of
        A.UNIV _ => kind
      | A.REC (ids, rows, loc) =>
        A.REC (ids, map (substTyrow subst) rows, loc)

  and substKindedTyvar subst (tyvar, kind, loc) : A.kinded_tyvar =
      (tyvar, Option.map (substKind subst) kind, loc)

  and substTy subst ty =
      case ty of
        A.TYVAR (_, (symbol, loc)) =>
        (case Symbol.Map.find (subst, symbol) of
           NONE => ty
         | SOME tyFn => tyFn loc)
      | A.TYRECORD (rows, flex, loc) =>
        A.TYRECORD (map (substTyrow subst) rows, flex, loc)
      | A.TYCON (NONE, longtycon, loc2) =>
        A.TYCON (NONE, longtycon, loc2)
      | A.TYCON (SOME (tys, loc1), longtycon, loc2) =>
        A.TYCON (SOME (map (substTy subst) tys, loc1), longtycon, loc2)
      | A.TYTUPLE (tys, loc) =>
        A.TYTUPLE (map (substTy subst) tys, loc)
      | A.TYFUN (ty1, ty2, loc) =>
        A.TYFUN (substTy subst ty1, substTy subst ty2, loc)
      | A.TYPAREN (ty, loc) =>
        A.TYPAREN (substTy subst ty, loc)
      | A.TYWILD _ => ty
      | A.TYVAR_FREE tyvar =>
        A.TYVAR_FREE (substKindedTyvar subst tyvar)
      | A.TYPOLY ((tyvars, loc1), bodyTy, loc) =>
        let
          val btv = kindedTyvarsToSet tyvars
          val subst = setMinus (subst, btv)
          val subst = intersect (subst, ftvTy bodyTy)
        in
          if Symbol.Map.isEmpty subst then ty else
          let
            val captured = intersect (btv, ftvSubst subst loc)
            val subst =
                if Symbol.Map.isEmpty captured then subst else
                let
                  val (renameSubst, tyvars) = renameBtv captured tyvars
                in
                  Symbol.Map.unionWith #2 (subst, renameSubst)
                end
            val tyvars = map (substKindedTyvar subst) tyvars
          in
            A.TYPOLY ((tyvars, loc1), substTy subst bodyTy, loc)
          end
        end

  val substTy =
      fn subst => fn ty =>
         if Symbol.Map.isEmpty subst then ty else substTy subst ty

  fun makeSubst tyvars tys =
      ListPair.foldlEq
        (fn ((_, (symbol, _)) : A.tyvar, ty : A.ty, subst) =>
            Symbol.Map.insert (subst, symbol, fn (_ : A.loc) => ty))
        Symbol.Map.empty
        (tyvars, tys)

  fun reduceTyrow tyfuns (lab, ty, loc) : A.tyrow =
      (lab, reduceTy tyfuns ty, loc)

  and reduceKind tyfuns kind =
      case kind of
        A.UNIV _ => kind
      | A.REC (ids, rows, loc) =>
        A.REC (ids, map (reduceTyrow tyfuns) rows, loc)

  and reduceKindedTyvar tyfuns (tyvar, kind, loc) : A.kinded_tyvar =
      (tyvar, Option.map (reduceKind tyfuns) kind, loc)

  and reduceTyseq tyfuns NONE = NONE
    | reduceTyseq tyfuns (SOME (tys, loc)) =
      SOME (map (reduceTy tyfuns) tys, loc)

  and reduceTy tyfuns ty =
      case ty of
        A.TYVAR _ => ty
      | A.TYRECORD (rows, flex, loc) =>
        A.TYRECORD (map (reduceTyrow tyfuns) rows, flex, loc)
      | A.TYCON (tyseq, tycon, loc) =>
        let
          val tyseq = reduceTyseq tyfuns tyseq
        in
          case tycon of
            (nil, (symbol, _), _) =>
            (case Symbol.Map.find (tyfuns, symbol) of
               NONE => A.TYCON (tyseq, tycon, loc)
             | SOME ((tvseq, _, ty, _) : A.typbind) =>
               case SOME (makeSubst (seq tvseq) (seq tyseq)) handle _ => NONE of
                 NONE => (enqueueError
                            (loc,
                             E.ArityMismatchInTypeDeclaration
                               {tycon = symbol,
                                wants = length (seq tvseq),
                                given = length (seq tyseq)});
                          A.TYCON (tyseq, tycon, loc))
               | SOME subst => substTy subst ty)
          | _ => A.TYCON (tyseq, tycon, loc)
        end
      | A.TYTUPLE (tys, loc) =>
        A.TYTUPLE (map (reduceTy tyfuns) tys, loc)
      | A.TYFUN (ty1, ty2, loc) =>
        A.TYFUN (reduceTy tyfuns ty1, reduceTy tyfuns ty2, loc)
      | A.TYPAREN (ty, loc) =>
        A.TYPAREN (reduceTy tyfuns ty, loc)
      | A.TYWILD _ => ty
      | A.TYVAR_FREE tyvar =>
        A.TYVAR_FREE (reduceKindedTyvar tyfuns tyvar)
      | A.TYPOLY ((tyvars, loc1), ty, loc) =>
        A.TYPOLY ((map (reduceKindedTyvar tyfuns) tyvars, loc1),
                  reduceTy tyfuns ty,
                  loc)

  fun reduceTyConbind tyfuns (vid, ty, loc) : A.conbind =
      (vid, Option.map (reduceTy tyfuns) ty, loc)

  fun reduceTyDatbind subst (tyvarseq, tycon, conbinds, loc) : A.datbind =
      (tyvarseq, tycon, map (reduceTyConbind subst) conbinds, loc)

  fun reduceDatbind (datbinds, withty) =
      let
        val tyfuns =
            foldl
              (fn (t as (_, (id, _), _, _), z) => Symbol.Map.insert (z, id, t))
              Symbol.Map.empty
              (seq withty)
      in
        if Symbol.Map.isEmpty tyfuns
        then datbinds
        else map (reduceTyDatbind tyfuns) datbinds
      end

  fun appendTyvarseq (NONE, nil) = NONE
    | appendTyvarseq (SOME (tyvars, loc), tyvars2) =
      SOME (tyvars @ tyvars2, loc)
    | appendTyvarseq (NONE, tyvars as h :: t) =
      SOME (tyvars, foldl Loc.mergeRange (#3 h) (map #3 t))

end
