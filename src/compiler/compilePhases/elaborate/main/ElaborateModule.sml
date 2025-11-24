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

  fun seq (SOME (items, _)) = items | seq NONE = nil

  val itId = Symbol.intern "it"
  fun itLongvid loc = (false, (nil, (itId, loc), loc), loc) : A.op_longvid

  fun elabValdesc (vid, ty, loc) =
      (vid, ElaborateTy.elabPolyTy (ElaborateTy.makePolyTy ty), LOC loc)

  fun elabTypdesc (tyvarseq, tycon, loc) =
      (map #2 (seq tyvarseq), tycon, LOC loc)

  fun elabCondesc (vid, ty, loc) =
      (vid, Option.map ElaborateTy.elabMonoTy ty, LOC loc)

  fun elabDatdesc (tyvarseq, tycon, condescs, loc) =
      (map #2 (seq tyvarseq), tycon, map elabCondesc condescs, LOC loc)

  val elabExdesc = elabCondesc

  fun elabWheretype (tyvarseq, longtycon, ty, loc) =
      (map #2 (seq tyvarseq), longtycon, ElaborateTy.elabMonoTy ty, LOC loc)

  fun elabTypbind (typbind as (tyvarseq, tycon, ty, loc)) =
      elabSpec
        (A.SPECINCLUDE
           (A.SIGWHERE
              (A.SIGBASIC ([A.SPECTYPE ([(tyvarseq, tycon, loc)], loc)], loc),
               [(tyvarseq, (nil, tycon, #2 tycon), ty, loc)],
               loc),
            loc))

  and elabStrdesc (strid, sigexp, loc) =
      (strid, elabSigexp sigexp, LOC loc)

  and elabSpec spec =
      case spec of
        A.SPECVAL (valdescs, loc) =>
        [P.SPECVAL (map elabValdesc valdescs, LOC loc)]
      | A.SPECTYPE (typdescs, loc) =>
        [P.SPECTYPE (false, map elabTypdesc typdescs, LOC loc)]
      | A.SPECEQTYPE (typdescs, loc) =>
        [P.SPECTYPE (true, map elabTypdesc typdescs, LOC loc)]
      | A.SPECTYPBIND (typbinds, loc) =>
        List.concat (map elabTypbind typbinds)
      | A.SPECDATATYPE (datdescs, loc) =>
        [P.SPECDATATYPE (map elabDatdesc datdescs, LOC loc)]
      | A.SPECDATATYPEREP (tycon, longtycon, loc) =>
        [P.SPECDATATYPEREP (tycon, longtycon, LOC loc)]
      | A.SPECEXCEPTION (exdescs, loc) =>
        [P.SPECEXCEPTION (map elabExdesc exdescs, LOC loc)]
      | A.SPECSTRUCTURE (strdescs, loc) =>
        [P.SPECSTRUCTURE (map elabStrdesc strdescs, LOC loc)]
      | A.SPECINCLUDE (sigexp, loc) =>
        [P.SPECINCLUDE (elabSigexp sigexp, LOC loc)]
      | A.SPECINCLUDE_ID (sigids, loc) =>
        elabSpecs
          (map (fn sigid => A.SPECINCLUDE (A.SIGID sigid, #2 sigid)) sigids)
      | A.SPECSHARINGTYPE (specs, tycons, loc) =>
        [P.SPECSHARINGTYPE (elabSpecs specs, tycons, LOC loc)]
      | A.SPECSHARING (specs, strids, loc) =>
        [P.SPECSHARING (elabSpecs specs, strids, LOC loc)]
      | A.SPECSEMICOLON _ => nil

  and elabSpecs specs =
      List.concat (map elabSpec specs)

  and elabSigexp sigexp =
      case sigexp of
        A.SIGBASIC (specs, loc) =>
        P.SIGBASIC (elabSpecs specs, LOC loc)
      | A.SIGID sigid =>
        P.SIGID sigid
      | A.SIGWHERE (sigexp, wheretypes, loc) =>
        foldl
          (fn (wheretype, sigexp) =>
              P.SIGWHERE (sigexp, elabWheretype wheretype, LOC loc))(*FIXME*)
          (elabSigexp sigexp)
          wheretypes

  fun elabStrexp strexp =
      case strexp of
        A.STRBASIC (strdecs, loc) =>
        P.STRBASIC (elabStrdecs strdecs, LOC loc)
      | A.STRID strid =>
        P.STRID strid
      | A.STRCONSTRAINT (strexp, (sigop, sigexp, _), loc) =>
        P.STRCONSTRAINT (elabStrexp strexp, sigop, elabSigexp sigexp, LOC loc)
      | A.STRAPP (funid, SOME (A.FUNARG strexp), loc) =>
        P.STRAPP (funid, elabStrexp strexp, LOC loc)
      | A.STRAPP (funid, SOME (A.FUNARG_DEC strdecs), loc) =>
        elabStrexp (A.STRAPP (funid, SOME (A.FUNARG (A.STRBASIC strdecs)), loc))
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
        P.STRLET (elabStrdecs strdecs, elabStrexp strexp, LOC loc)

  and elabStrbind strbind =
      case strbind of
        (strid, NONE, strexp, loc) =>
        (strid, elabStrexp strexp, LOC loc)
      | (strid, SOME sigcon, strexp, loc) =>
        elabStrbind
          (strid, NONE, A.STRCONSTRAINT (strexp, sigcon, #3 sigcon), loc)

  and elabStrdec strdec =
      case strdec of
        A.STRDEC dec =>
        map P.STRDEC (ElaborateCore.elabDec dec)
      | A.STRUCTURE (strbinds, loc) =>
        [P.STRUCTURE (map elabStrbind strbinds, LOC loc)]
      | A.STRLOCAL (strdecs1, strdecs2, loc) =>
        [P.STRLOCAL (elabStrdecs strdecs1, elabStrdecs strdecs2, LOC loc)]
      | A.STRSEMICOLON _ => nil

  and elabStrdecs strdecs =
      List.concat (map elabStrdec strdecs)

  fun elabSigbind (strid, sigexp, loc) =
      (strid, elabSigexp sigexp, LOC loc)

  fun elabFunbind ((funid, param, sigcon, strexp, loc) : A.funbind) =
      case (param, sigcon) of
        (SOME (A.FUNPARAM (strid, sigexp, _)), NONE) =>
        (funid, strid, elabSigexp sigexp, elabStrexp strexp, LOC loc)
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

  fun elabSigdec (sigbinds, loc) =
      (map elabSigbind sigbinds, LOC loc)

  fun elabTopdec topdec =
      case topdec of
        A.TOPSTRDEC strdec =>
        map P.TOPSTRDEC (elabStrdec strdec)
      | A.TOPSIGNATURE sigdec =>
        [P.TOPSIGNATURE (elabSigdec sigdec)]
      | A.TOPFUNCTOR (funbinds, loc) =>
        [P.TOPFUNCTOR (map elabFunbind funbinds, LOC loc)]
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
