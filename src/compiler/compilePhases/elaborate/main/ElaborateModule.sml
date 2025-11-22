(*
 * Elaborator.
 *
 * @copyright (C) 2021 SML# Development Team.
 * @author YAMATODANI Kiyoshi
 * @author Atsushi Ohori
 * @author Liu Bochao
 * @author Katsuhiro Ueno
 *)
structure ElaborateModule =
struct
  structure A = Absyn
  structure P = PatternCalc
  datatype loc = datatype Loc.loc

  fun toSymbol ((sym, loc) : A.vid) = {symbol = sym, loc = LOC loc}
  fun seq (SOME (items, _)) = items | seq NONE = nil

  val itId = Symbol.intern "it"
  fun itLongvid loc = (false, (nil, (itId, loc), loc), loc) : A.op_longvid

  fun elabValdesc (vid, ty, loc) =
      ((ElaborateTy.toKindedTyvars (ElaborateTy.ftvTy ty), LOC loc),
       toSymbol vid,
       ElaborateTy.elabRank1Ty ty,
       LOC loc)

  fun elabTypdesc (tyvarseq, tycon, loc) =
      (seq tyvarseq, toSymbol tycon)

  fun elabTypdescs eq (typdescs, loc) =
      P.PLSPECTYPE {tydecls = map elabTypdesc typdescs, eq = eq, loc = LOC loc}

  fun elabCondesc (vid, ty, loc) =
      {symbol = toSymbol vid,
       ty = Option.map ElaborateTy.elabMonoTy ty,
       loc = LOC loc}

  fun elabDatdesc (datdesc as (tyvarseq, tycon, condescs, loc)) =
      {tyvars = seq tyvarseq,
       symbol = toSymbol tycon,
       conbind = map elabCondesc condescs,
       loc = LOC loc}

  fun elabExdesc (vid, ty, loc) =
      (toSymbol vid, Option.map ElaborateTy.elabMonoTy ty, LOC loc)

  fun elabWheretype (wheretype as (tyvarseq, longtycon, ty, loc)) =
      (seq tyvarseq,
       SymbolWithLoc.fromAbsyn longtycon,
       ElaborateTy.elabMonoTy ty)

  fun elabTypbind (typbind as (tyvarseq, tycon, ty, loc)) =
      elabSpec
        (A.SPECINCLUDE
           (A.SIGWHERE
              (A.SIGBASIC ([A.SPECTYPE ([(tyvarseq, tycon, loc)], loc)], loc),
               [(tyvarseq, (nil, tycon, #2 tycon), ty, loc)],
               loc),
            loc))

  and elabStrdesc (strid, sigexp, loc) =
      (toSymbol strid, elabSigexp sigexp, LOC loc)

  and elabSpec spec =
      case spec of
        A.SPECVAL (valdescs, loc) =>
        [P.PLSPECVAL (map elabValdesc valdescs)]
      | A.SPECTYPE typdescs =>
        [elabTypdescs false typdescs]
      | A.SPECEQTYPE typdescs =>
        [elabTypdescs true typdescs]
      | A.SPECTYPBIND (typbinds, loc) =>
        List.concat (map elabTypbind typbinds)
      | A.SPECDATATYPE (datdescs, loc) =>
        [P.PLSPECDATATYPE (map elabDatdesc datdescs, LOC loc)]
      | A.SPECDATATYPEREP (tycon, longtycon, loc) =>
        [P.PLSPECREPLIC
           (toSymbol tycon, SymbolWithLoc.fromAbsyn longtycon, LOC loc)]
      | A.SPECEXCEPTION (exdescs, loc) =>
        [P.PLSPECEXCEPTION (map elabExdesc exdescs, LOC loc)]
      | A.SPECSTRUCTURE (strdescs, loc) =>
        [P.PLSPECSTRUCT (map elabStrdesc strdescs, LOC loc)]
      | A.SPECINCLUDE (sigexp, loc) =>
        [P.PLSPECINCLUDE (elabSigexp sigexp, LOC loc)]
      | A.SPECINCLUDE_ID (sigids, loc) =>
        elabSpecs
          (map (fn sigid => A.SPECINCLUDE (A.SIGID sigid, #2 sigid)) sigids)
      | A.SPECSHARINGTYPE (specs, tycons, loc) =>
        [P.PLSPECSHARE
           (elabSpecs specs, map SymbolWithLoc.fromAbsyn tycons, LOC loc)]
      | A.SPECSHARING (specs, strids, loc) =>
        [P.PLSPECSHARESTR
           (elabSpecs specs, map SymbolWithLoc.fromAbsyn strids, LOC loc)]
      | A.SPECSEMICOLON _ => nil

  and elabSpecs specs =
      List.concat (map elabSpec specs)

  and elabSigexp sigexp =
      case sigexp of
        A.SIGBASIC (specs, loc) =>
        P.PLSIGEXPBASIC (elabSpecs specs, LOC loc)
      | A.SIGID sigid =>
        P.PLSIGID (toSymbol sigid)
      | A.SIGWHERE (sigexp, wheretypes, loc) =>
        foldl
          (fn (wheretype, sigexp) =>
              P.PLSIGWHERE (sigexp, elabWheretype wheretype, LOC loc))(*FIXME*)
          (elabSigexp sigexp)
          wheretypes

  fun elabStrexp strexp =
      case strexp of
        A.STRBASIC (strdecs, loc) =>
        P.PLSTREXPBASIC (elabStrdecs strdecs, LOC loc)
      | A.STRID longid =>
        P.PLSTRID (SymbolWithLoc.fromAbsyn longid)
      | A.STRCONSTRAINT (strexp, (A.TRANSPARENT, sigexp, _), loc) =>
        P.PLSTRTRANCONSTRAINT
          (elabStrexp strexp, elabSigexp sigexp, LOC loc)
      | A.STRCONSTRAINT (strexp, (A.OPAQUE, sigexp, _), loc) =>
        P.PLSTROPAQCONSTRAINT
          (elabStrexp strexp, elabSigexp sigexp, LOC loc)
      | A.STRAPP (funid, SOME (A.FUNARG (A.STRID longid)), loc) =>
        P.PLFUNCTORAPP (toSymbol funid, SymbolWithLoc.fromAbsyn longid, LOC loc)
      | A.STRAPP (funid, SOME (A.FUNARG strexp), loc) =>
        let
          val loc2 = AbsynUtils.strexpLoc strexp
          val strid = (Symbol.generate NONE, loc2)
          val longstrid = (nil, strid, loc2)
        in
          elabStrexp
            (A.STRLET
               ([A.STRUCTURE ([(strid, NONE, strexp, loc2)], loc2)],
                A.STRAPP (funid, SOME (A.FUNARG (A.STRID longstrid)), loc),
                loc))
        end
      | A.STRAPP (funid, SOME (A.FUNARG_DEC strdecs), loc) =>
        elabStrexp
          (A.STRAPP (funid, SOME (A.FUNARG (A.STRBASIC strdecs)), loc))
      | A.STRAPP (funid, NONE, loc) =>
        let
          val strid = (Symbol.generate NONE, loc)
          val longstrid = (nil , strid, loc)
        in
          elabStrexp
            (A.STRLET
               ([A.STRUCTURE
                   ([(strid, NONE, A.STRBASIC (nil, loc), loc)], loc)],
                A.STRAPP (funid, SOME (A.FUNARG (A.STRID longstrid)), loc),
                loc))
        end
      | A.STRLET (strdecs, strexp, loc) =>
        P.PLSTRUCTLET (elabStrdecs strdecs, elabStrexp strexp, LOC loc)

  and elabStrbind strbind =
      case strbind of
        (strid, NONE, strexp, loc) =>
        (toSymbol strid, elabStrexp strexp, LOC loc)
      | (strid, SOME sigcon, strexp, loc) =>
        elabStrbind
          (strid, NONE, A.STRCONSTRAINT (strexp, sigcon, #3 sigcon), loc)

  and elabStrdec strdec =
      case strdec of
        A.STRDEC dec =>
        map P.PLCOREDEC (ElaborateCore.elabDec dec)
      | A.STRUCTURE (strbinds, loc) =>
        [P.PLSTRUCTBIND (map elabStrbind strbinds, LOC loc)]
      | A.STRLOCAL (strdecs1, strdecs2, loc) =>
        [P.PLSTRUCTLOCAL (elabStrdecs strdecs1, elabStrdecs strdecs2, LOC loc)]
      | A.STRSEMICOLON _ => nil

  and elabStrdecs strdecs =
      List.concat (map elabStrdec strdecs)

  fun elabSigbind (strid, sigexp, loc) =
      (toSymbol strid, elabSigexp sigexp, LOC loc)

  fun elabFunbind ((funid, param, sigcon, strexp, loc) : A.funbind) =
      case (param, sigcon) of
        (SOME (A.FUNPARAM (strid, sigexp, _)), NONE) =>
        {name = toSymbol funid,
         argStrName = toSymbol strid,
         argSig = elabSigexp sigexp,
         body = elabStrexp strexp,
         loc = LOC loc}
      | (SOME (A.FUNPARAM _), SOME (sigcon as (_, _, loc2))) =>
        elabFunbind
          (funid, param, NONE, A.STRCONSTRAINT (strexp, sigcon, loc2), loc)
      | (SOME (A.FUNPARAM_SPEC (spec as (_, loc2))), sigcon) =>
        let
          val strid = (Symbol.generate NONE, loc2)
          val param = SOME (A.FUNPARAM (strid, A.SIGBASIC spec, loc2))
          val strexp =
              case sigcon of
                NONE => strexp
              | SOME sigcon => A.STRCONSTRAINT (strexp, sigcon, #3 sigcon)
          val strexp =
              A.STRLET
                ([A.STRDEC (A.DECOPEN ([(nil, strid, #2 strid)], loc2))],
                 strexp,
                 AbsynUtils.strexpLoc strexp)
        in
          elabFunbind (funid, param, NONE, strexp, loc)
        end
      | (NONE, _) =>
        let
          val strid = (Symbol.generate NONE, loc)
          val param = SOME (A.FUNPARAM (strid, A.SIGBASIC (nil, loc), loc))
        in
          elabFunbind (funid, param, sigcon, strexp, loc)
        end

  fun elabTopdec topdec =
      case topdec of
        A.TOPSTRDEC strdec =>
        map P.PLTOPDECSTR (elabStrdec strdec)
      | A.TOPSIGNATURE (sigbinds, loc) =>
        [P.PLTOPDECSIG (map elabSigbind sigbinds, LOC loc)]
      | A.TOPFUNCTOR (funbinds, loc) =>
        [P.PLTOPDECFUN (map elabFunbind funbinds, LOC loc)]
      | A.TOPEXP (exp, loc) =>
        elabTopdec
          (A.TOPSTRDEC
             (A.STRDEC
                (A.DECVAL
                   (NONE,
                    [A.VALBIND (A.PATID (itLongvid loc), exp, loc)],
                    loc))))

  fun elabTopdecs topdecs =
      List.concat (map elabTopdec topdecs)

end
